// lib/models/1_domain/domain_orchestrator.dart

import 'package:equatable/equatable.dart';

// Import all domain entities
import 'package:ubiqa/models/1_domain/shared/entities/listing.dart';
import 'package:ubiqa/models/1_domain/shared/entities/payment.dart';
import 'package:ubiqa/models/1_domain/shared/entities/property.dart';
import 'package:ubiqa/models/1_domain/shared/entities/user.dart';

// Import value objects
import 'package:ubiqa/models/1_domain/shared/value_objects/contact_info.dart';
import 'package:ubiqa/models/1_domain/shared/value_objects/media.dart';
import 'package:ubiqa/models/1_domain/shared/value_objects/price.dart';

/// Operation types for property transactions
/// Central enum for the entire application - used across multiple domains
enum OperationType {
  venta,
  alquiler;

  String get getSpanishOperationLabel {
    switch (this) {
      case OperationType.venta:
        return 'Venta';
      case OperationType.alquiler:
        return 'Alquiler';
    }
  }

  String get getTypicalCurrencyCode {
    switch (this) {
      case OperationType.venta:
        return 'USD';
      case OperationType.alquiler:
        return 'PEN';
    }
  }
}

/// Domain Orchestrator handles cross-entity business logic and workflows
class UbiqaDomainOrchestrator {
  // LISTING CREATION WORKFLOWS

  static UserListingEligibility checkUserListingEligibility({
    required User user,
    required Property property,
  }) {
    // User must be active
    if (!user.isActive) {
      return UserListingEligibility.ineligible('User account is deactivated');
    }

    // User must be verified to create listings
    if (!user.isVerified()) {
      if (user.contactInfo == null) {
        return UserListingEligibility.requiresPhone();
      } else {
        return UserListingEligibility.requiresVerification();
      }
    }

    // Property must be available for new listings
    if (!property.isAvailable) {
      return UserListingEligibility.ineligible(
        'Property is not available for listing',
      );
    }

    return UserListingEligibility.eligible();
  }

  static ListingCreationResult createListingForUserAndProperty({
    required User user,
    required Property property,
    required ListingId listingId,
    required String title,
    required String description,
    required Price price,
    ContactInfo? contactInfo,
    Media? media,
  }) {
    // Check eligibility first
    final eligibility = checkUserListingEligibility(
      user: user,
      property: property,
    );
    if (!eligibility.isEligible) {
      throw UbiqaDomainException('Cannot create listing', [
        'User eligibility failed: ${eligibility.reason}',
      ]);
    }

    // Create the listing using domain service
    try {
      final listing = ListingDomainService.createListingWithValidation(
        id: listingId,
        title: title,
        description: description,
        price: price,
        contactInfo: contactInfo ?? user.contactInfo,
        media: media,
      );

      // Cross-entity business validation
      final crossValidationErrors = _validateListingAgainstUserAndProperty(
        user: user,
        property: property,
        listing: listing,
      );

      if (crossValidationErrors.isNotEmpty) {
        throw UbiqaDomainException(
          'Cross-entity validation failed',
          crossValidationErrors,
        );
      }

      return ListingCreationResult.success(listing);
    } catch (e) {
      if (e is ListingDomainException) {
        return ListingCreationResult.failure(e.message, e.violations);
      } else if (e is UbiqaDomainException) {
        return ListingCreationResult.failure(e.message, e.violations);
      } else {
        return ListingCreationResult.failure('Listing creation failed', [
          e.toString(),
        ]);
      }
    }
  }

  static PaymentInitiationResult initiateListingPayment({
    required User user,
    required Listing listing,
    required PaymentId paymentId,
    required PaymentProvider provider,
    required PaymentMethod method,
  }) {
    // Validate user is verified to make payments
    if (!user.isVerified()) {
      throw UbiqaDomainException('Cannot initiate payment', [
        'User must be verified to make payments',
      ]);
    }

    // Validate listing is in correct state for payment
    if (!listing.needsPayment()) {
      throw UbiqaDomainException('Cannot initiate payment', [
        'Listing does not require payment in current status: ${listing.status.name}',
      ]);
    }

    try {
      // Create payment for listing fee
      final payment = PaymentDomainService.createListingPayment(
        id: paymentId,
        provider: provider,
        method: method,
      );

      // Update listing to payment pending
      final updatedListing = listing.markPaymentPending();

      return PaymentInitiationResult.success(payment, updatedListing);
    } catch (e) {
      if (e is PaymentDomainException) {
        return PaymentInitiationResult.failure(e.message, e.violations);
      } else {
        return PaymentInitiationResult.failure('Payment initiation failed', [
          e.toString(),
        ]);
      }
    }
  }

  // PAYMENT PROCESSING WORKFLOWS

  static PaymentProcessingResult processPaymentCompletionForListing({
    required Payment payment,
    required Listing listing,
    String? receiptData,
    String? providerResponse,
  }) {
    // Validate payment and listing are compatible
    final validationErrors = _validatePaymentListingCompatibility(
      payment,
      listing,
    );
    if (validationErrors.isNotEmpty) {
      throw UbiqaDomainException(
        'Payment-Listing validation failed',
        validationErrors,
      );
    }

    try {
      // Complete the payment
      final completedPayment = PaymentDomainService.processCompletion(
        payment: payment,
        receiptData: receiptData,
        providerResponse: providerResponse,
      );

      // Activate the listing (starts 30-day countdown)
      final activatedListing = ListingDomainService.processPaymentConfirmation(
        listing,
      );

      return PaymentProcessingResult.success(
        completedPayment,
        activatedListing,
      );
    } catch (e) {
      if (e is PaymentDomainException || e is ListingDomainException) {
        return PaymentProcessingResult.failure(e.toString(), []);
      } else {
        return PaymentProcessingResult.failure('Payment processing failed', [
          e.toString(),
        ]);
      }
    }
  }

  static PaymentProcessingResult processPaymentFailureForListing({
    required Payment payment,
    required Listing listing,
    required String errorMessage,
    String? providerResponse,
  }) {
    try {
      // Fail the payment
      final failedPayment = PaymentDomainService.processFailure(
        payment: payment,
        errorMessage: errorMessage,
        providerResponse: providerResponse,
      );

      // Revert listing to draft status so user can retry
      final revertedListing = listing.copyWith(status: ListingStatus.draft);

      return PaymentProcessingResult.success(failedPayment, revertedListing);
    } catch (e) {
      return PaymentProcessingResult.failure(
        'Payment failure processing failed',
        [e.toString()],
      );
    }
  }

  // USER CAPABILITY MANAGEMENT

  static UserPlatformCapabilities getUserCapabilities(User user) {
    return UserPlatformCapabilities(
      canSearch: user.isActive,
      canContact: user.isActive && user.isVerified(),
      canCreateListings: user.isActive && user.isVerified(),
      canMakePayments: user.isActive && user.isVerified(),
      canEditProfile: user.isActive,
      needsPhoneVerification: user.contactInfo != null && !user.isVerified(),
      hasCompleteProfile: user.hasCompleteProfile(),
      isNewUser: user.isNewUser(),
    );
  }

  // LISTING MANAGEMENT WORKFLOWS

  static bool canUserEditListing({
    required User user,
    required Listing listing,
    bool userOwnsListing = true,
  }) {
    // User must be active and verified
    if (!user.isActive || !user.isVerified()) {
      return false;
    }

    // User must own the listing (checked by infrastructure layer)
    if (!userOwnsListing) {
      return false;
    }

    // Listing must be in editable status
    return listing.canBeEdited();
  }

  static ListingUpdateResult updateUserListingContent({
    required User user,
    required Listing listing,
    bool userOwnsListing = true,
    String? title,
    String? description,
    Price? price,
    ContactInfo? contactInfo,
    Media? media,
  }) {
    // Check if user can edit
    if (!canUserEditListing(
      user: user,
      listing: listing,
      userOwnsListing: userOwnsListing,
    )) {
      return ListingUpdateResult.failure('User cannot edit this listing', []);
    }

    try {
      // Use contact info from user if not specified
      final effectiveContactInfo = contactInfo ?? user.contactInfo;

      final updatedListing = ListingDomainService.updateListingContent(
        listing: listing,
        title: title,
        description: description,
        price: price,
        contactInfo: effectiveContactInfo,
        media: media,
      );

      return ListingUpdateResult.success(updatedListing);
    } catch (e) {
      if (e is ListingDomainException) {
        return ListingUpdateResult.failure(e.message, e.violations);
      } else {
        return ListingUpdateResult.failure('Listing update failed', [
          e.toString(),
        ]);
      }
    }
  }

  // CROSS-ENTITY VALIDATION HELPERS

  static List<String> _validateListingAgainstUserAndProperty({
    required User user,
    required Property property,
    required Listing listing,
  }) {
    final errors = <String>[];

    // Contact info should match user's verified contact info
    if (listing.contactInfo != null && user.contactInfo != null) {
      final userPhone = user.contactInfo!.whatsappPhoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final listingPhone = listing.contactInfo!.whatsappPhoneNumber.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      if (userPhone != listingPhone) {
        errors.add('Contact phone should match user verified phone number');
      }
    }

    // Listing price should be reasonable for property type and size
    if (property.propertyType == PropertyType.terreno) {
      if (listing.price.monetaryAmountValue < 10000) {
        errors.add('Terreno price seems unusually low');
      }
    } else {
      // Rough price per m² validation
      final pricePerM2 =
          listing.price.monetaryAmountValue /
          property.specs.totalAreaInSquareMeters;
      if (pricePerM2 < 100) {
        errors.add('Price per square meter seems unusually low');
      }
      if (pricePerM2 > 50000) {
        errors.add('Price per square meter seems unusually high');
      }
    }

    return errors;
  }

  static List<String> _validatePaymentListingCompatibility(
    Payment payment,
    Listing listing,
  ) {
    final errors = <String>[];

    // Payment must be in processing state
    if (payment.status != PaymentStatus.processing) {
      errors.add('Payment must be in processing state');
    }

    // Listing must be waiting for payment
    if (listing.status != ListingStatus.paymentPending) {
      errors.add('Listing must be in payment pending state');
    }

    // Payment amount should match listing fee
    if (payment.price.monetaryAmountValue !=
        PaymentDomainService.listingFeeAmount) {
      errors.add('Payment amount does not match listing fee');
    }

    // Payment should not be expired
    if (payment.isExpired()) {
      errors.add('Payment has expired');
    }

    return errors;
  }
}

// RESULT VALUE OBJECTS

class UserListingEligibility extends Equatable {
  final bool isEligible;
  final String? reason;
  final ListingRequirement? requirement;

  const UserListingEligibility._({
    required this.isEligible,
    this.reason,
    this.requirement,
  });

  factory UserListingEligibility.eligible() {
    return const UserListingEligibility._(isEligible: true);
  }

  factory UserListingEligibility.requiresPhone() {
    return const UserListingEligibility._(
      isEligible: false,
      reason: 'Phone number required for listing creation',
      requirement: ListingRequirement.phoneNumber,
    );
  }

  factory UserListingEligibility.requiresVerification() {
    return const UserListingEligibility._(
      isEligible: false,
      reason: 'Phone verification required for listing creation',
      requirement: ListingRequirement.phoneVerification,
    );
  }

  factory UserListingEligibility.ineligible(String reason) {
    return UserListingEligibility._(isEligible: false, reason: reason);
  }

  @override
  List<Object?> get props => [isEligible, reason, requirement];
}

enum ListingRequirement { phoneNumber, phoneVerification }

class ListingCreationResult extends Equatable {
  final bool isSuccess;
  final Listing? listing;
  final String? errorMessage;
  final List<String> violations;

  const ListingCreationResult._({
    required this.isSuccess,
    this.listing,
    this.errorMessage,
    required this.violations,
  });

  factory ListingCreationResult.success(Listing listing) {
    return ListingCreationResult._(
      isSuccess: true,
      listing: listing,
      violations: [],
    );
  }

  factory ListingCreationResult.failure(
    String message,
    List<String> violations,
  ) {
    return ListingCreationResult._(
      isSuccess: false,
      errorMessage: message,
      violations: violations,
    );
  }

  @override
  List<Object?> get props => [isSuccess, listing, errorMessage, violations];
}

class PaymentInitiationResult extends Equatable {
  final bool isSuccess;
  final Payment? payment;
  final Listing? updatedListing;
  final String? errorMessage;
  final List<String> violations;

  const PaymentInitiationResult._({
    required this.isSuccess,
    this.payment,
    this.updatedListing,
    this.errorMessage,
    required this.violations,
  });

  factory PaymentInitiationResult.success(Payment payment, Listing listing) {
    return PaymentInitiationResult._(
      isSuccess: true,
      payment: payment,
      updatedListing: listing,
      violations: [],
    );
  }

  factory PaymentInitiationResult.failure(
    String message,
    List<String> violations,
  ) {
    return PaymentInitiationResult._(
      isSuccess: false,
      errorMessage: message,
      violations: violations,
    );
  }

  @override
  List<Object?> get props => [
    isSuccess,
    payment,
    updatedListing,
    errorMessage,
    violations,
  ];
}

class PaymentProcessingResult extends Equatable {
  final bool isSuccess;
  final Payment? payment;
  final Listing? updatedListing;
  final String? errorMessage;
  final List<String> violations;

  const PaymentProcessingResult._({
    required this.isSuccess,
    this.payment,
    this.updatedListing,
    this.errorMessage,
    required this.violations,
  });

  factory PaymentProcessingResult.success(Payment payment, Listing listing) {
    return PaymentProcessingResult._(
      isSuccess: true,
      payment: payment,
      updatedListing: listing,
      violations: [],
    );
  }

  factory PaymentProcessingResult.failure(
    String message,
    List<String> violations,
  ) {
    return PaymentProcessingResult._(
      isSuccess: false,
      errorMessage: message,
      violations: violations,
    );
  }

  @override
  List<Object?> get props => [
    isSuccess,
    payment,
    updatedListing,
    errorMessage,
    violations,
  ];
}

class ListingUpdateResult extends Equatable {
  final bool isSuccess;
  final Listing? updatedListing;
  final String? errorMessage;
  final List<String> violations;

  const ListingUpdateResult._({
    required this.isSuccess,
    this.updatedListing,
    this.errorMessage,
    required this.violations,
  });

  factory ListingUpdateResult.success(Listing listing) {
    return ListingUpdateResult._(
      isSuccess: true,
      updatedListing: listing,
      violations: [],
    );
  }

  factory ListingUpdateResult.failure(String message, List<String> violations) {
    return ListingUpdateResult._(
      isSuccess: false,
      errorMessage: message,
      violations: violations,
    );
  }

  @override
  List<Object?> get props => [
    isSuccess,
    updatedListing,
    errorMessage,
    violations,
  ];
}

class UserPlatformCapabilities extends Equatable {
  final bool canSearch;
  final bool canContact;
  final bool canCreateListings;
  final bool canMakePayments;
  final bool canEditProfile;
  final bool needsPhoneVerification;
  final bool hasCompleteProfile;
  final bool isNewUser;

  const UserPlatformCapabilities({
    required this.canSearch,
    required this.canContact,
    required this.canCreateListings,
    required this.canMakePayments,
    required this.canEditProfile,
    required this.needsPhoneVerification,
    required this.hasCompleteProfile,
    required this.isNewUser,
  });

  @override
  List<Object> get props => [
    canSearch,
    canContact,
    canCreateListings,
    canMakePayments,
    canEditProfile,
    needsPhoneVerification,
    hasCompleteProfile,
    isNewUser,
  ];
}

class UbiqaDomainException implements Exception {
  final String message;
  final List<String> violations;

  const UbiqaDomainException(this.message, this.violations);

  @override
  String toString() =>
      'UbiqaDomainException: $message\nViolations: ${violations.join(', ')}';
}
