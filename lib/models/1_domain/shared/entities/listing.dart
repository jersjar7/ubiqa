// lib/models/1_domain/shared/entities/listing.dart

import 'package:equatable/equatable.dart';

// Import value objects
import '../value_objects/price.dart';
import '../value_objects/contact_info.dart';
import '../value_objects/media.dart';

/// Strongly-typed identifier for Listing entities
class ListingId extends Equatable {
  final String value;

  const ListingId._(this.value);

  factory ListingId.fromString(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('ListingId cannot be empty');
    }
    return ListingId._(id.trim());
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}

/// Listing lifecycle status for V1 subscription model
enum ListingStatus {
  draft,
  paymentPending,
  active,
  expired,
  deactivated;

  String get getSpanishStatusLabel {
    switch (this) {
      case ListingStatus.draft:
        return 'Borrador';
      case ListingStatus.paymentPending:
        return 'Pago Pendiente';
      case ListingStatus.active:
        return 'Activo';
      case ListingStatus.expired:
        return 'Vencido';
      case ListingStatus.deactivated:
        return 'Desactivado';
    }
  }

  bool get isSearchableStatus => this == ListingStatus.active;
  bool get requiresPayment =>
      this == ListingStatus.draft || this == ListingStatus.paymentPending;
  bool get isLiveStatus => this == ListingStatus.active;
}

/// Listing entity representing a 30-day property publication subscription
class Listing extends Equatable {
  final ListingId id;
  final String title;
  final String description;
  final Price price;
  final ContactInfo? contactInfo;
  final Media media;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime updatedAt;

  const Listing._({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.media,
    this.contactInfo,
    this.publishedAt,
    this.expiresAt,
  });

  /// Factory: Create new draft listing
  factory Listing.createDraft({
    required ListingId id,
    required String title,
    required String description,
    required Price price,
    ContactInfo? contactInfo,
    Media? media,
  }) {
    final now = DateTime.now();
    return Listing._(
      id: id,
      title: title.trim(),
      description: description.trim(),
      price: price,
      contactInfo: contactInfo,
      media: media ?? Media.createEmpty(),
      status: ListingStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates copy with updated fields
  Listing copyWith({
    String? title,
    String? description,
    Price? price,
    ContactInfo? contactInfo,
    Media? media,
    ListingStatus? status,
    DateTime? publishedAt,
    DateTime? expiresAt,
    DateTime? updatedAt,
  }) {
    return Listing._(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      contactInfo: contactInfo ?? this.contactInfo,
      media: media ?? this.media,
      status: status ?? this.status,
      createdAt: createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // LISTING LIFECYCLE METHODS

  Listing activate() {
    final now = DateTime.now();
    final expiration = now.add(const Duration(days: 30));

    return copyWith(
      status: ListingStatus.active,
      publishedAt: now,
      expiresAt: expiration,
      updatedAt: now,
    );
  }

  Listing markPaymentPending() {
    return copyWith(status: ListingStatus.paymentPending);
  }

  Listing expire() {
    return copyWith(status: ListingStatus.expired);
  }

  Listing deactivate() {
    return copyWith(status: ListingStatus.deactivated);
  }

  // LISTING STATUS QUERIES

  bool isActive() {
    return status == ListingStatus.active && !isExpired();
  }

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool isSearchable() {
    return status.isSearchableStatus && !isExpired();
  }

  bool needsPayment() {
    return status.requiresPayment;
  }

  bool canBeEdited() {
    return status == ListingStatus.draft || status == ListingStatus.active;
  }

  // LISTING TIME CALCULATIONS

  int? daysUntilExpiry() {
    if (!isActive() || expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  bool isExpiringSoon() {
    final days = daysUntilExpiry();
    return days != null && days <= 3;
  }

  Duration getAge() {
    return DateTime.now().difference(createdAt);
  }

  // DELEGATION TO VALUE OBJECTS

  /// Gets formatted price for display
  String getFormattedPrice() {
    return price.generateFormattedPriceForDisplay();
  }

  /// Gets compact price format
  String getCompactPrice() {
    return price.generateCompactPriceFormat();
  }

  /// Gets WhatsApp contact URL
  String? getWhatsAppContactUrl() {
    if (contactInfo == null) return null;

    final message =
        'Hola! Me interesa tu propiedad: ${title.length > 50 ? '${title.substring(0, 50)}...' : title}';
    return contactInfo!.generateWhatsAppContactUrl(message);
  }

  /// Gets formatted contact info
  String? getContactSummary() {
    return contactInfo?.generateContactSummaryForListing();
  }

  /// Gets primary photo URL
  String? getPrimaryPhoto() {
    return media.getPrimaryPropertyPhotoUrl();
  }

  /// Checks if listing has photos
  bool hasPhotos() {
    return media.containsPropertyPhotos();
  }

  /// Gets all photo URLs
  List<String> getPhotoUrls() {
    return media.propertyPhotoUrls;
  }

  // CONTENT METHODS

  String getDescriptionPreview({int maxLength = 150}) {
    if (description.length <= maxLength) return description;

    final cutoffIndex = description.lastIndexOf(' ', maxLength);
    final finalIndex = cutoffIndex > 0 ? cutoffIndex : maxLength;
    return '${description.substring(0, finalIndex)}...';
  }

  String getUrlSlug() {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  // VALIDATION

  List<String> validateBusinessRules() {
    final errors = <String>[];

    // Title validation
    if (title.trim().length < 10) {
      errors.add('Title must be at least 10 characters');
    }
    if (title.trim().length > 120) {
      errors.add('Title cannot exceed 120 characters');
    }

    // Description validation
    if (description.trim().length < 20) {
      errors.add('Description must be at least 20 characters');
    }
    if (description.trim().length > 2000) {
      errors.add('Description cannot exceed 2000 characters');
    }

    // Status consistency validation
    if (status == ListingStatus.active) {
      if (publishedAt == null) {
        errors.add('Active listings must have published date');
      }
      if (expiresAt == null) {
        errors.add('Active listings must have expiration date');
      }
    }

    // Duration validation
    if (publishedAt != null && expiresAt != null) {
      final duration = expiresAt!.difference(publishedAt!);
      if (duration.inDays != 30) {
        errors.add('Listing duration must be exactly 30 days');
      }
    }

    return errors;
  }

  // ENTITY IDENTITY - Based on ID only
  @override
  List<Object> get props => [id];

  @override
  String toString() {
    return 'Listing(id: ${id.value}, status: ${status.name}, title: "$title")';
  }
}

/// Domain exception for listing business rule violations
class ListingDomainException implements Exception {
  final String message;
  final List<String> violations;

  const ListingDomainException(this.message, this.violations);

  @override
  String toString() =>
      'ListingDomainException: $message\nViolations: ${violations.join(', ')}';
}

/// Listing domain service for validation and operations
class ListingDomainService {
  static const int listingFeeInSoles = 19;
  static const int listingDurationDays = 30;

  static Listing createListingWithValidation({
    required ListingId id,
    required String title,
    required String description,
    required Price price,
    ContactInfo? contactInfo,
    Media? media,
  }) {
    final listing = Listing.createDraft(
      id: id,
      title: title,
      description: description,
      price: price,
      contactInfo: contactInfo,
      media: media,
    );

    final violations = listing.validateBusinessRules();
    if (violations.isNotEmpty) {
      throw ListingDomainException('Invalid listing data', violations);
    }

    return listing;
  }

  static Listing processPaymentConfirmation(Listing listing) {
    if (listing.status != ListingStatus.paymentPending) {
      throw ListingDomainException('Cannot confirm payment', [
        'Listing must be in payment pending status',
      ]);
    }
    return listing.activate();
  }

  static Listing updateListingContent({
    required Listing listing,
    String? title,
    String? description,
    Price? price,
    ContactInfo? contactInfo,
    Media? media,
  }) {
    if (!listing.canBeEdited()) {
      throw ListingDomainException('Cannot edit listing', [
        'Listing status does not allow editing',
      ]);
    }

    final updatedListing = listing.copyWith(
      title: title,
      description: description,
      price: price,
      contactInfo: contactInfo,
      media: media,
    );

    final violations = updatedListing.validateBusinessRules();
    if (violations.isNotEmpty) {
      throw ListingDomainException('Invalid listing updates', violations);
    }

    return updatedListing;
  }
}
