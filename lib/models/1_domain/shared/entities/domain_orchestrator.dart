// lib/models/1_domain/shared/entities/domain_orchestrator.dart

import 'package:equatable/equatable.dart';

// Import all domain entities
import 'user.dart';
import 'property.dart';
import 'listing.dart';
import 'payment.dart';

/// Domain Orchestrator handles cross-entity business logic and workflows
///
/// This service coordinates between User, Property, Listing, and Payment entities
/// to implement complex business operations that span multiple domain concepts.
///
/// Key Responsibilities:
/// - Listing creation workflows (User + Property + Payment)
/// - Payment processing workflows (Payment + Listing activation)
/// - Cross-entity validation and business rules
/// - User capability determination across entities
class UbiqaDomainOrchestrator {
  // LISTING CREATION WORKFLOWS

  /// Determines if a user can create a listing for a specific property
  ///
  /// This encapsulates the core business rules for listing creation eligibility
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
      if (user.phoneNumber == null) {
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

    // Property must have valid business data
    final propertyErrors = property.validateBusinessRules();
    if (propertyErrors.isNotEmpty) {
      return UserListingEligibility.ineligible(
        'Property data is invalid: ${propertyErrors.first}',
      );
    }

    return UserListingEligibility.eligible();
  }

  /// Creates a new listing for a user and property with business validation
  ///
  /// This implements the complete listing creation workflow including
  /// cross-entity validation and business rule enforcement
  static ListingCreationResult createListingForUserAndProperty({
    required User user,
    required Property property,
    required ListingId listingId,
    required String title,
    required String description,
    required double priceAmount,
    required String priceCurrency,
    String? contactPhone,
    String? contactHours,
    List<String>? photoUrls,
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
        priceAmount: priceAmount,
        priceCurrency: priceCurrency,
        contactPhone: contactPhone ?? user.phoneNumber,
        contactHours: contactHours,
        photoUrls: photoUrls,
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

  /// Initiates payment for a user's listing
  ///
  /// Creates the payment entity and establishes the connection between
  /// User, Listing, and Payment for the subscription workflow
  static PaymentInitiationResult initiateListingPayment({
    required User user,
    required Listing listing,
    required PaymentId paymentId,
    required PaymentProvider provider,
    required PaymentMethod method,
  }) {
    // Validate user owns the listing context (this would normally check user ID matching)
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

  /// Processes payment completion and activates the associated listing
  ///
  /// This implements the core subscription activation workflow when
  /// payment is successfully completed by the payment provider
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

  /// Processes payment failure and updates listing accordingly
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

  /// Determines comprehensive user capabilities across the platform
  ///
  /// This consolidates all user capability checks in one place for
  /// consistent business rule application across the application
  static UserPlatformCapabilities getUserCapabilities(User user) {
    return UserPlatformCapabilities(
      canSearch: user.isActive, // Any active user can search
      canContact:
          user.isActive && user.isVerified(), // Only verified users can contact
      canCreateListings:
          user.isActive && user.isVerified(), // Only verified users can publish
      canMakePayments:
          user.isActive && user.isVerified(), // Only verified users can pay
      canEditProfile: user.isActive, // Any active user can edit profile
      needsPhoneVerification: user.phoneNumber != null && !user.isPhoneVerified,
      hasCompleteProfile: user.hasCompleteProfile(),
      isNewUser: user.isNewUser(),
    );
  }

  // LISTING MANAGEMENT WORKFLOWS

  /// Checks if a user can edit a specific listing
  ///
  /// In a full implementation, this would check user ownership via repository,
  /// but for domain layer we focus on business rule validation
  static bool canUserEditListing({
    required User user,
    required Listing listing,
    bool userOwnsListing = true, // This would be determined by repository layer
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

  /// Updates listing content with cross-entity validation
  static ListingUpdateResult updateUserListingContent({
    required User user,
    required Listing listing,
    bool userOwnsListing = true,
    String? title,
    String? description,
    double? priceAmount,
    String? priceCurrency,
    String? contactPhone,
    String? contactHours,
    List<String>? photoUrls,
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
      // Use contact phone from user if not specified
      final effectiveContactPhone = contactPhone ?? user.phoneNumber;

      final updatedListing = ListingDomainService.updateListingContent(
        listing: listing,
        title: title,
        description: description,
        priceAmount: priceAmount,
        priceCurrency: priceCurrency,
        contactPhone: effectiveContactPhone,
        contactHours: contactHours,
        photoUrls: photoUrls,
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

  /// Validates listing data against user and property context
  static List<String> _validateListingAgainstUserAndProperty({
    required User user,
    required Property property,
    required Listing listing,
  }) {
    final errors = <String>[];

    // Contact phone should match user's verified phone
    if (listing.contactPhone != null && user.phoneNumber != null) {
      final userPhone = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      final listingPhone = listing.contactPhone!.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );

      if (userPhone != listingPhone) {
        errors.add('Contact phone should match user verified phone number');
      }
    }

    // Listing price should be reasonable for property type and size
    if (property.propertyType == PropertyType.terreno) {
      if (listing.priceAmount < 10000) {
        errors.add('Terreno price seems unusually low');
      }
    } else {
      // Rough price per m² validation
      final pricePerM2 = listing.priceAmount / property.areaM2;
      if (pricePerM2 < 100) {
        errors.add('Price per square meter seems unusually low');
      }
      if (pricePerM2 > 50000) {
        errors.add('Price per square meter seems unusually high');
      }
    }

    // Currency should match operation type conventions
    if (property.operationType == OperationType.venta &&
        listing.priceCurrency == 'PEN' &&
        listing.priceAmount > 100000) {
      // Sales over 100k soles might be better in USD
      // This is a warning, not an error
    }

    return errors;
  }

  /// Validates payment and listing compatibility
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
    if (payment.amount != PaymentDomainService.listingFeeAmount) {
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

/// Result of user listing eligibility check
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

/// Requirements for listing creation
enum ListingRequirement { phoneNumber, phoneVerification }

/// Result of listing creation operation
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

/// Result of payment initiation
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

/// Result of payment processing
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

/// Result of listing update operation
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

/// Comprehensive user capabilities across the platform
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

/// Domain exception for orchestrator operations
class UbiqaDomainException implements Exception {
  final String message;
  final List<String> violations;

  const UbiqaDomainException(this.message, this.violations);

  @override
  String toString() =>
      'UbiqaDomainException: $message\nViolations: ${violations.join(', ')}';
}
