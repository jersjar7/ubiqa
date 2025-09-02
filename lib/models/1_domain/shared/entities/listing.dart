// lib/models/1_domain/shared/entities/listing.dart

import 'package:equatable/equatable.dart';

/// Strongly-typed identifier for Listing entities
class ListingId extends Equatable {
  final String value;

  const ListingId._(this.value);

  /// Creates ListingId from string with validation
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
  /// Created but not yet paid for
  draft,

  /// Payment initiated but not confirmed
  paymentPending,

  /// Live and visible to users
  active,

  /// 30-day period expired
  expired,

  /// Manually deactivated by owner
  deactivated;

  /// User-friendly status labels for UI
  String get displayName {
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

  /// Whether this status allows listing to be visible in search
  bool get isSearchable => this == ListingStatus.active;

  /// Whether this status requires payment to progress
  bool get needsPayment =>
      this == ListingStatus.draft || this == ListingStatus.paymentPending;

  /// Whether this status is considered "live" for business metrics
  bool get isLive => this == ListingStatus.active;
}

/// Listing entity representing a 30-day property publication subscription
///
/// Business Concept: A Listing is a time-bound publication that makes
/// a property visible to potential buyers/renters. It follows a simple
/// lifecycle: creation → payment → activation → expiration.
///
/// Core Responsibilities:
/// - Subscription lifecycle management (30-day duration)
/// - Content management (title, description)
/// - Status tracking and validation
/// - Expiration and renewal logic
class Listing extends Equatable {
  /// Unique identifier for this listing
  final ListingId id;

  /// Listing title for search and display
  final String title;

  /// Property description provided by owner
  final String description;

  /// Price amount for the property
  final double priceAmount;

  /// Currency for the price (PEN or USD)
  final String priceCurrency;

  /// Current status in subscription lifecycle
  final ListingStatus status;

  /// When listing was created
  final DateTime createdAt;

  /// When listing was published (became active)
  final DateTime? publishedAt;

  /// When listing expires (30 days from published)
  final DateTime? expiresAt;

  /// Last status update timestamp
  final DateTime updatedAt;

  /// Contact phone number for this listing
  final String? contactPhone;

  /// Preferred contact hours
  final String? contactHours;

  /// URLs of property photos in display order
  final List<String> photoUrls;

  const Listing._({
    required this.id,
    required this.title,
    required this.description,
    required this.priceAmount,
    required this.priceCurrency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.photoUrls,
    this.publishedAt,
    this.expiresAt,
    this.contactPhone,
    this.contactHours,
  });

  /// Factory: Create new draft listing
  factory Listing.createDraft({
    required ListingId id,
    required String title,
    required String description,
    required double priceAmount,
    required String priceCurrency,
    String? contactPhone,
    String? contactHours,
    List<String>? photoUrls,
  }) {
    final now = DateTime.now();
    return Listing._(
      id: id,
      title: title.trim(),
      description: description.trim(),
      priceAmount: priceAmount,
      priceCurrency: priceCurrency.toUpperCase(),
      status: ListingStatus.draft,
      createdAt: now,
      updatedAt: now,
      contactPhone: contactPhone?.trim(),
      contactHours: contactHours?.trim(),
      photoUrls: photoUrls ?? [],
    );
  }

  /// Creates copy with updated fields
  Listing copyWith({
    String? title,
    String? description,
    double? priceAmount,
    String? priceCurrency,
    ListingStatus? status,
    DateTime? publishedAt,
    DateTime? expiresAt,
    DateTime? updatedAt,
    String? contactPhone,
    String? contactHours,
    List<String>? photoUrls,
  }) {
    return Listing._(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priceAmount: priceAmount ?? this.priceAmount,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      status: status ?? this.status,
      createdAt: createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      updatedAt: updatedAt ?? DateTime.now(),
      contactPhone: contactPhone ?? this.contactPhone,
      contactHours: contactHours ?? this.contactHours,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  // LISTING LIFECYCLE METHODS

  /// Activates listing after payment confirmation
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

  /// Marks listing as payment pending
  Listing markPaymentPending() {
    return copyWith(status: ListingStatus.paymentPending);
  }

  /// Expires the listing after 30-day period
  Listing expire() {
    return copyWith(status: ListingStatus.expired);
  }

  /// Manually deactivates the listing
  Listing deactivate() {
    return copyWith(status: ListingStatus.deactivated);
  }

  // LISTING STATUS QUERIES

  /// Checks if listing is currently active and visible
  bool isActive() {
    return status == ListingStatus.active && !isExpired();
  }

  /// Checks if listing has expired (past expiration date)
  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Checks if listing is searchable by users
  bool isSearchable() {
    return status.isSearchable && !isExpired();
  }

  /// Checks if listing needs payment to progress
  bool needsPayment() {
    return status.needsPayment;
  }

  /// Checks if listing can be edited
  bool canBeEdited() {
    return status == ListingStatus.draft || status == ListingStatus.active;
  }

  // LISTING TIME CALCULATIONS

  /// Gets days remaining until expiration (null if not active)
  int? daysUntilExpiry() {
    if (!isActive() || expiresAt == null) return null;

    final remaining = expiresAt!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// Gets hours remaining until expiration (for urgent notifications)
  int? hoursUntilExpiry() {
    if (!isActive() || expiresAt == null) return null;

    final remaining = expiresAt!.difference(DateTime.now()).inHours;
    return remaining < 0 ? 0 : remaining;
  }

  /// Checks if listing is expiring soon (within 3 days)
  bool isExpiringSoon() {
    final days = daysUntilExpiry();
    return days != null && days <= 3;
  }

  /// Checks if listing is expiring very soon (within 24 hours)
  bool isExpiringToday() {
    final hours = hoursUntilExpiry();
    return hours != null && hours <= 24;
  }

  /// Gets listing age since creation
  Duration getAge() {
    return DateTime.now().difference(createdAt);
  }

  /// Gets how long listing has been active
  Duration? getActiveTime() {
    if (publishedAt == null) return null;
    return DateTime.now().difference(publishedAt!);
  }

  // LISTING CONTENT METHODS

  /// Gets formatted price for display
  String getFormattedPrice() {
    final formatter = _getPriceFormatter();
    if (priceCurrency == 'USD') {
      return 'US\$ ${formatter.format(priceAmount)}';
    } else {
      return 'S/ ${formatter.format(priceAmount)}';
    }
  }

  /// Gets SEO-friendly URL slug from title
  String getUrlSlug() {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Remove multiple hyphens
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
  }

  /// Gets listing summary for preview cards
  String getDescriptionPreview({int maxLength = 150}) {
    if (description.length <= maxLength) {
      return description;
    }

    // Find last space before max length to avoid cutting words
    final cutoffIndex = description.lastIndexOf(' ', maxLength);
    final finalIndex = cutoffIndex > 0 ? cutoffIndex : maxLength;

    return '${description.substring(0, finalIndex)}...';
  }

  /// Gets primary photo URL (first in list)
  String? getPrimaryPhoto() {
    return photoUrls.isNotEmpty ? photoUrls.first : null;
  }

  /// Checks if listing has photos
  bool hasPhotos() {
    return photoUrls.isNotEmpty;
  }

  /// Gets contact WhatsApp URL with listing info
  String? getWhatsAppContactUrl() {
    if (contactPhone == null) return null;

    final cleanPhone = contactPhone!.replaceAll(RegExp(r'[^\d]'), '');
    final internationalFormat = cleanPhone.startsWith('51')
        ? cleanPhone
        : '51$cleanPhone';

    final message =
        'Hola! Me interesa tu propiedad: ${title.length > 50 ? '${title.substring(0, 50)}...' : title}';
    final encoded = Uri.encodeComponent(message);

    return 'https://wa.me/$internationalFormat?text=$encoded';
  }

  // VALIDATION

  /// Validates listing data against business rules
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

    // Price validation
    if (priceAmount <= 0) {
      errors.add('Price must be greater than 0');
    }
    if (priceAmount > 10000000) {
      errors.add('Price cannot exceed 10 million');
    }

    // Currency validation
    if (!['PEN', 'USD'].contains(priceCurrency)) {
      errors.add('Currency must be PEN or USD');
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

    // Expiration logic validation
    if (publishedAt != null && expiresAt != null) {
      final duration = expiresAt!.difference(publishedAt!);
      if (duration.inDays != 30) {
        errors.add('Listing duration must be exactly 30 days');
      }
    }

    // Photo validation
    if (photoUrls.length > 20) {
      errors.add('Cannot have more than 20 photos');
    }

    // Contact validation
    if (contactPhone != null && !_isValidPeruvianPhone(contactPhone!)) {
      errors.add('Contact phone must be valid Peruvian number');
    }

    return errors;
  }

  /// Validates Peruvian phone number format
  bool _isValidPeruvianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length == 9 && cleaned.startsWith('9')) {
      return true;
    }

    if (cleaned.length == 11 && cleaned.startsWith('519')) {
      return true;
    }

    return false;
  }

  /// Gets number formatter for price display
  dynamic _getPriceFormatter() {
    // This would typically use a proper NumberFormat, but for domain layer
    // we'll keep it simple and handle in presentation layer
    return _SimpleNumberFormatter();
  }

  // ENTITY IDENTITY - Based on ID only
  @override
  List<Object> get props => [id];

  @override
  String toString() {
    return 'Listing(id: ${id.value}, status: ${status.name}, title: "$title")';
  }
}

/// Simple number formatter for domain layer
class _SimpleNumberFormatter {
  String format(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    } else {
      return number.toStringAsFixed(0);
    }
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
  /// V1 listing fee in Peruvian soles
  static const int listingFeeInSoles = 19;

  /// V1 listing duration in days
  static const int listingDurationDays = 30;

  /// Maximum photos per listing
  static const int maxPhotosPerListing = 20;

  /// Creates listing with validation
  static Listing createListingWithValidation({
    required ListingId id,
    required String title,
    required String description,
    required double priceAmount,
    required String priceCurrency,
    String? contactPhone,
    String? contactHours,
    List<String>? photoUrls,
  }) {
    final listing = Listing.createDraft(
      id: id,
      title: title,
      description: description,
      priceAmount: priceAmount,
      priceCurrency: priceCurrency,
      contactPhone: contactPhone,
      contactHours: contactHours,
      photoUrls: photoUrls,
    );

    final violations = listing.validateBusinessRules();
    if (violations.isNotEmpty) {
      throw ListingDomainException('Invalid listing data', violations);
    }

    return listing;
  }

  /// Processes payment confirmation and activates listing
  static Listing processPaymentConfirmation(Listing listing) {
    if (listing.status != ListingStatus.paymentPending) {
      throw ListingDomainException('Cannot confirm payment', [
        'Listing must be in payment pending status',
      ]);
    }

    return listing.activate();
  }

  /// Processes expired listings (called by background job)
  static Listing? processExpiration(Listing listing) {
    if (!listing.isActive()) return null;
    if (!listing.isExpired()) return null;

    return listing.expire();
  }

  /// Calculates listing fee for V1 (fixed price)
  static int calculateListingFee() {
    return listingFeeInSoles;
  }

  /// Updates listing content with validation
  static Listing updateListingContent({
    required Listing listing,
    String? title,
    String? description,
    double? priceAmount,
    String? priceCurrency,
    String? contactPhone,
    String? contactHours,
    List<String>? photoUrls,
  }) {
    if (!listing.canBeEdited()) {
      throw ListingDomainException('Cannot edit listing', [
        'Listing status does not allow editing',
      ]);
    }

    final updatedListing = listing.copyWith(
      title: title,
      description: description,
      priceAmount: priceAmount,
      priceCurrency: priceCurrency,
      contactPhone: contactPhone,
      contactHours: contactHours,
      photoUrls: photoUrls,
    );

    final violations = updatedListing.validateBusinessRules();
    if (violations.isNotEmpty) {
      throw ListingDomainException('Invalid listing updates', violations);
    }

    return updatedListing;
  }
}
