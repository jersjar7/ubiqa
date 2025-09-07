// lib/services/1_infrastructure/firebase/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Import domain entities - these define WHAT we persist
import '../../../models/1_domain/shared/entities/user.dart';
import '../../../models/1_domain/shared/entities/property.dart';
import '../../../models/1_domain/shared/entities/listing.dart';
import '../../../models/1_domain/shared/entities/payment.dart';

// Import value objects for data conversion
import '../../../models/1_domain/shared/value_objects/location.dart';
import '../../../models/1_domain/shared/value_objects/contact_info.dart';
import '../../../models/1_domain/shared/value_objects/property_specs.dart';
import '../../../models/1_domain/shared/value_objects/media.dart';
import '../../../models/1_domain/shared/value_objects/price.dart';

// Import domain orchestrator for operation types
import '../../../models/1_domain/domain_orchestrator.dart';

// Import configuration
import '../../0_config/shared/firebase_config.dart';

// Import shared infrastructure
import '../shared/service_result.dart';

/// Firestore Service for Ubiqa Real Estate Data Persistence
///
/// WHY this service exists:
/// Peru's real estate market requires cross-device continuity because users frequently
/// switch between phones, share devices, and need to manage listings from multiple
/// locations. This service ensures property owners can draft listings on mobile,
/// complete payments on desktop, and monitor active listings from any device.
///
/// WHY we separate collections:
/// - Users: Profile persistence enables WhatsApp verification state across devices
/// - Properties: Reusable data allows multiple listings for same property over time
/// - Listings: 30-day subscription lifecycle requires independent status tracking
/// - Payments: Receipt access and customer support requires transaction history
///
/// Updated: Now supports international phone numbers (Peru + US) with proper serialization
class FirestoreService {
  // USER PERSISTENCE
  // WHY: Peru users switch devices frequently and need profile continuity

  /// Saves user profile to enable cross-device access
  /// WHY: Users start registration on mobile but may complete verification on desktop
  Future<ServiceResult<void>> saveUser(User user) async {
    try {
      final userData = _userToFirestoreMap(user);

      await FirebaseCollections.users
          .doc(user.id.value)
          .set(userData, SetOptions(merge: true));

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to save user profile',
        ServiceException('User persistence error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Retrieves user by ID for profile loading across devices
  /// WHY: Authentication happens on every device, but profile data must persist
  Future<ServiceResult<User?>> getUserById(UserId userId) async {
    try {
      final doc = await FirebaseCollections.users.doc(userId.value).get();

      if (!doc.exists) {
        return ServiceResult.success(null);
      }

      final userData = doc.data() as Map<String, dynamic>;
      final user = _userFromFirestoreMap(userData, userId.value);

      return ServiceResult.success(user);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to load user profile',
        ServiceException('User retrieval error', ServiceErrorType.unknown, e),
      );
    }
  }

  // PROPERTY PERSISTENCE
  // WHY: Properties are reusable assets that can have multiple listings over time

  /// Saves property for portfolio management across devices
  /// WHY: Property owners manage multiple properties and need access from any device
  Future<ServiceResult<void>> saveProperty(
    Property property,
    UserId ownerId,
  ) async {
    try {
      final propertyData = _propertyToFirestoreMap(property);
      // WHY: Link to owner for portfolio queries and ownership verification
      propertyData['ownerId'] = ownerId.value;
      propertyData['createdAt'] = FieldValue.serverTimestamp();

      await FirebaseCollections.properties
          .doc(property.id.value)
          .set(propertyData, SetOptions(merge: true));

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to save property',
        ServiceException(
          'Property persistence error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  /// Gets all properties owned by a user for portfolio display
  /// WHY: Property owners need to see their complete portfolio across devices
  Future<ServiceResult<List<Property>>> getUserProperties(
    UserId ownerId,
  ) async {
    try {
      final snapshot = await FirebaseCollections.properties
          .where('ownerId', isEqualTo: ownerId.value)
          .orderBy('createdAt', descending: true)
          .get();

      final properties = snapshot.docs
          .map(
            (doc) => _propertyFromFirestoreMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      return ServiceResult.success(properties);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to load user properties',
        ServiceException('Property query error', ServiceErrorType.unknown, e),
      );
    }
  }

  // LISTING PERSISTENCE
  // WHY: 30-day subscription model requires persistent status tracking

  /// Saves listing with subscription lifecycle tracking
  /// WHY: Listings must persist through payment → active → expired states
  Future<ServiceResult<void>> saveListing(
    Listing listing,
    UserId ownerId,
    PropertyId propertyId,
  ) async {
    try {
      final listingData = _listingToFirestoreMap(listing);
      // WHY: Link ownership and property for queries and business rules
      listingData['ownerId'] = ownerId.value;
      listingData['propertyId'] = propertyId.value;

      await FirebaseCollections.listings
          .doc(listing.id.value)
          .set(listingData, SetOptions(merge: true));

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to save listing',
        ServiceException(
          'Listing persistence error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  /// Gets active listings within Piura geographic bounds for property search
  /// WHY: Buyers need to find available properties in their target area
  Future<ServiceResult<List<ListingWithDetails>>> getActiveListingsInPiura({
    int limit = 50,
  }) async {
    try {
      // WHY: Only show active listings to buyers (not drafts or expired)
      final snapshot = await FirebaseCollections.listings
          .where('status', isEqualTo: ListingStatus.active.name)
          .where('isAvailable', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      final listingsWithDetails = <ListingWithDetails>[];

      // WHY: Enrich with property details for complete search results
      for (final doc in snapshot.docs) {
        final listing = _listingFromFirestoreMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        final propertyId =
            (doc.data() as Map<String, dynamic>?)?['propertyId'] as String?;

        if (propertyId != null) {
          final propertyResult = await _getPropertyById(propertyId);
          if (propertyResult.isSuccess && propertyResult.data != null) {
            listingsWithDetails.add(
              ListingWithDetails(
                listing: listing,
                property: propertyResult.data!,
              ),
            );
          }
        }
      }

      return ServiceResult.success(listingsWithDetails);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to load active listings',
        ServiceException('Listing query error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Gets all listings created by a user across all statuses
  /// WHY: Property owners need to manage drafts, active, and expired listings
  Future<ServiceResult<List<Listing>>> getUserListings(UserId ownerId) async {
    try {
      final snapshot = await FirebaseCollections.listings
          .where('ownerId', isEqualTo: ownerId.value)
          .orderBy('createdAt', descending: true)
          .get();

      final listings = snapshot.docs
          .map(
            (doc) => _listingFromFirestoreMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      return ServiceResult.success(listings);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to load user listings',
        ServiceException(
          'User listings query error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  /// Updates listing status for 30-day subscription lifecycle management
  /// WHY: Listings transition through payment → active → expired states automatically
  Future<ServiceResult<void>> updateListingStatus(
    ListingId listingId,
    ListingStatus newStatus, {
    DateTime? publishedAt,
    DateTime? expiresAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // WHY: Track publication time for 30-day countdown
      if (publishedAt != null) {
        updateData['publishedAt'] = Timestamp.fromDate(publishedAt);
      }

      // WHY: Track expiration for automatic status transitions
      if (expiresAt != null) {
        updateData['expiresAt'] = Timestamp.fromDate(expiresAt);
      }

      await FirebaseCollections.listings
          .doc(listingId.value)
          .update(updateData);

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to update listing status',
        ServiceException('Status update error', ServiceErrorType.unknown, e),
      );
    }
  }

  // PAYMENT PERSISTENCE
  // WHY: Receipt access and customer support require transaction history

  /// Saves payment for receipt access and transaction tracking
  /// WHY: Users need receipts for accounting and may contact support about payments
  Future<ServiceResult<void>> savePayment(
    Payment payment,
    UserId userId, {
    ListingId? listingId,
  }) async {
    try {
      final paymentData = _paymentToFirestoreMap(payment);
      // WHY: Link payments to users and listings for support queries
      paymentData['userId'] = userId.value;
      if (listingId != null) {
        paymentData['listingId'] = listingId.value;
      }

      await FirebaseCollections.payments
          .doc(payment.id.value)
          .set(paymentData, SetOptions(merge: true));

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to save payment',
        ServiceException(
          'Payment persistence error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  /// Gets user's payment history for receipt access
  /// WHY: Users need receipts for tax purposes and expense tracking
  Future<ServiceResult<List<Payment>>> getUserPayments(UserId userId) async {
    try {
      final snapshot = await FirebaseCollections.payments
          .where('userId', isEqualTo: userId.value)
          .orderBy('createdAt', descending: true)
          .get();

      final payments = snapshot.docs
          .map(
            (doc) => _paymentFromFirestoreMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      return ServiceResult.success(payments);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to load payment history',
        ServiceException('Payment history error', ServiceErrorType.unknown, e),
      );
    }
  }

  // SEARCH AND FILTERING
  // WHY: Buyers need to find properties that match their specific requirements

  /// Searches listings by price range for budget-based property discovery
  /// WHY: Price is the primary filter for property buyers in Peru market
  Future<ServiceResult<List<ListingWithDetails>>> searchListingsByPriceRange(
    Currency currency,
    double minPrice,
    double maxPrice, {
    int limit = 20,
  }) async {
    try {
      // WHY: Filter by currency first since PEN/USD have different price scales
      final snapshot = await FirebaseCollections.listings
          .where('status', isEqualTo: ListingStatus.active.name)
          .where('price.currency', isEqualTo: currency.isoCurrencyCode)
          .where('price.amount', isGreaterThanOrEqualTo: minPrice)
          .where('price.amount', isLessThanOrEqualTo: maxPrice)
          .orderBy('price.amount')
          .limit(limit)
          .get();

      final results = <ListingWithDetails>[];

      for (final doc in snapshot.docs) {
        final listing = _listingFromFirestoreMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        final propertyId =
            (doc.data() as Map<String, dynamic>?)?['propertyId'] as String?;

        if (propertyId != null) {
          final propertyResult = await _getPropertyById(propertyId);
          if (propertyResult.isSuccess && propertyResult.data != null) {
            results.add(
              ListingWithDetails(
                listing: listing,
                property: propertyResult.data!,
              ),
            );
          }
        }
      }

      return ServiceResult.success(results);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to search listings by price',
        ServiceException('Price search error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Searches listings by property type for category-based discovery
  /// WHY: Buyers typically know if they want casa, departamento, or terreno
  Future<ServiceResult<List<ListingWithDetails>>> searchListingsByPropertyType(
    PropertyType propertyType,
    OperationType operationType, {
    int limit = 30,
  }) async {
    try {
      final snapshot = await FirebaseCollections.listings
          .where('status', isEqualTo: ListingStatus.active.name)
          .where('operationType', isEqualTo: operationType.name)
          .where('propertyType', isEqualTo: propertyType.name)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      final results = <ListingWithDetails>[];

      for (final doc in snapshot.docs) {
        final listing = _listingFromFirestoreMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        final propertyId =
            (doc.data() as Map<String, dynamic>?)?['propertyId'] as String?;

        if (propertyId != null) {
          final propertyResult = await _getPropertyById(propertyId);
          if (propertyResult.isSuccess && propertyResult.data != null) {
            results.add(
              ListingWithDetails(
                listing: listing,
                property: propertyResult.data!,
              ),
            );
          }
        }
      }

      return ServiceResult.success(results);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to search by property type',
        ServiceException(
          'Property type search error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // EXPIRED LISTING MANAGEMENT
  // WHY: 30-day subscription model requires automatic expiration handling

  /// Gets listings that have expired and need status updates
  /// WHY: Expired listings should not appear in buyer searches
  Future<ServiceResult<List<Listing>>> getExpiredListings() async {
    try {
      final now = Timestamp.now();

      final snapshot = await FirebaseCollections.listings
          .where('status', isEqualTo: ListingStatus.active.name)
          .where('expiresAt', isLessThan: now)
          .get();

      final expiredListings = snapshot.docs
          .map(
            (doc) => _listingFromFirestoreMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      return ServiceResult.success(expiredListings);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to get expired listings',
        ServiceException('Expiration query error', ServiceErrorType.unknown, e),
      );
    }
  }

  // HELPER METHODS FOR DATA CONVERSION
  // WHY: Clean separation between domain entities and Firestore format

  Future<ServiceResult<Property?>> _getPropertyById(String propertyId) async {
    try {
      final doc = await FirebaseCollections.properties.doc(propertyId).get();
      if (!doc.exists) return ServiceResult.success(null);

      final property = _propertyFromFirestoreMap(
        doc.data()! as Map<String, dynamic>,
        propertyId,
      );
      return ServiceResult.success(property);
    } catch (e) {
      return ServiceResult.failure(
        'Property lookup failed',
        ServiceException('Property query error', ServiceErrorType.unknown, e),
      );
    }
  }

  // DATA CONVERSION METHODS
  // WHY: Domain entities must be converted to/from Firestore format
  // Updated: Now properly handles InternationalPhoneNumber serialization

  Map<String, dynamic> _userToFirestoreMap(User user) {
    final data = <String, dynamic>{
      'email': user.email,
      'name': user.name,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'updatedAt': Timestamp.fromDate(user.updatedAt),
      'isActive': user.isActive,
    };

    if (user.contactInfo != null) {
      data['contactInfo'] = {
        'whatsappPhoneNumber': user.contactInfo!.getInternationalPhoneNumber(),
        'countryCode': user.contactInfo!.getDetectedCountryCode().name,
        'preferredContactTimeSlot':
            user.contactInfo!.preferredContactTimeSlot.name,
        'additionalContactNotes': user.contactInfo!.additionalContactNotes,
      };
    }

    return data;
  }

  User _userFromFirestoreMap(Map<String, dynamic> data, String userId) {
    ContactInfo? contactInfo;
    if (data['contactInfo'] != null) {
      final contactData = data['contactInfo'] as Map<String, dynamic>;
      final contactHours = ContactHours.values.firstWhere(
        (hours) => hours.name == contactData['preferredContactTimeSlot'],
        orElse: () => ContactHours.anytime,
      );

      contactInfo = ContactInfo.create(
        whatsappPhoneNumber: contactData['whatsappPhoneNumber'] as String,
        preferredContactTimeSlot: contactHours,
        additionalContactNotes:
            contactData['additionalContactNotes'] as String?,
      );
    }

    return User.fromStoredData(
      firebaseUid: userId,
      email: data['email'] as String,
      name: data['name'] as String?,
      contactInfo: contactInfo,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _propertyToFirestoreMap(Property property) {
    return {
      'propertyType': property.propertyType.name,
      'operationType': property.operationType.name,
      'specs': {
        'totalAreaInSquareMeters': property.specs.totalAreaInSquareMeters,
        'bedroomCount': property.specs.bedroomCount,
        'bathroomCount': property.specs.bathroomCount,
        'availableParkingSpaces': property.specs.availableParkingSpaces,
        'propertyAmenities': property.specs.propertyAmenities,
      },
      'location': {
        'latitude': property.location.latitudeInDecimalDegrees,
        'longitude': property.location.longitudeInDecimalDegrees,
        'fullStreetAddress': property.location.fullStreetAddress,
        'administrativeDistrict': property.location.administrativeDistrict,
        'countryIsoCode': property.location.countryIsoCode,
      },
      'media': {'propertyPhotoUrls': property.media.propertyPhotoUrls},
      'updatedAt': Timestamp.fromDate(property.updatedAt),
      'isAvailable': property.isAvailable,
    };
  }

  Property _propertyFromFirestoreMap(
    Map<String, dynamic> data,
    String propertyId,
  ) {
    final specsData = data['specs'] as Map<String, dynamic>;
    final locationData = data['location'] as Map<String, dynamic>;
    final mediaData = data['media'] as Map<String, dynamic>;

    final specs = PropertySpecs.create(
      totalAreaInSquareMeters: (specsData['totalAreaInSquareMeters'] as num)
          .toDouble(),
      bedroomCount: specsData['bedroomCount'] as int?,
      bathroomCount: specsData['bathroomCount'] as int?,
      availableParkingSpaces: specsData['availableParkingSpaces'] as int? ?? 0,
      propertyAmenities: List<String>.from(
        specsData['propertyAmenities'] ?? [],
      ),
    );

    final location = Location.create(
      latitudeInDecimalDegrees: (locationData['latitude'] as num).toDouble(),
      longitudeInDecimalDegrees: (locationData['longitude'] as num).toDouble(),
      fullStreetAddress: locationData['fullStreetAddress'] as String,
      administrativeDistrict: locationData['administrativeDistrict'] as String,
      countryIsoCode: locationData['countryIsoCode'] as String? ?? 'PE',
    );

    final media = Media.create(
      propertyPhotoUrls: List<String>.from(
        mediaData['propertyPhotoUrls'] ?? [],
      ),
    );

    return Property.create(
      id: PropertyId.fromString(propertyId),
      propertyType: PropertyType.values.firstWhere(
        (type) => type.name == data['propertyType'],
      ),
      operationType: OperationType.values.firstWhere(
        (type) => type.name == data['operationType'],
      ),
      specs: specs,
      location: location,
      media: media,
    ).copyWith(
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isAvailable: data['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _listingToFirestoreMap(Listing listing) {
    final data = <String, dynamic>{
      'title': listing.title,
      'description': listing.description,
      'price': {
        'amount': listing.price.monetaryAmountValue,
        'currency': listing.price.transactionCurrency.isoCurrencyCode,
      },
      'status': listing.status.name,
      'createdAt': Timestamp.fromDate(listing.createdAt),
      'updatedAt': Timestamp.fromDate(listing.updatedAt),
    };

    if (listing.contactInfo != null) {
      data['contactInfo'] = {
        'whatsappPhoneNumber': listing.contactInfo!
            .getInternationalPhoneNumber(),
        'countryCode': listing.contactInfo!.getDetectedCountryCode().name,
        'preferredContactTimeSlot':
            listing.contactInfo!.preferredContactTimeSlot.name,
        'additionalContactNotes': listing.contactInfo!.additionalContactNotes,
      };
    }

    if (listing.publishedAt != null) {
      data['publishedAt'] = Timestamp.fromDate(listing.publishedAt!);
    }

    if (listing.expiresAt != null) {
      data['expiresAt'] = Timestamp.fromDate(listing.expiresAt!);
    }

    data['media'] = {'propertyPhotoUrls': listing.media.propertyPhotoUrls};

    return data;
  }

  Listing _listingFromFirestoreMap(
    Map<String, dynamic> data,
    String listingId,
  ) {
    final priceData = data['price'] as Map<String, dynamic>;

    final price = Price.createFromCurrencyCode(
      monetaryAmountValue: (priceData['amount'] as num).toDouble(),
      isoCurrencyCode: priceData['currency'] as String,
    );

    ContactInfo? contactInfo;
    if (data['contactInfo'] != null) {
      final contactData = data['contactInfo'] as Map<String, dynamic>;
      final contactHours = ContactHours.values.firstWhere(
        (hours) => hours.name == contactData['preferredContactTimeSlot'],
        orElse: () => ContactHours.anytime,
      );

      contactInfo = ContactInfo.create(
        whatsappPhoneNumber: contactData['whatsappPhoneNumber'] as String,
        preferredContactTimeSlot: contactHours,
        additionalContactNotes:
            contactData['additionalContactNotes'] as String?,
      );
    }

    final mediaData = data['media'] as Map<String, dynamic>? ?? {};
    final media = Media.create(
      propertyPhotoUrls: List<String>.from(
        mediaData['propertyPhotoUrls'] ?? [],
      ),
    );

    final status = ListingStatus.values.firstWhere(
      (status) => status.name == data['status'],
      orElse: () => ListingStatus.draft,
    );

    return Listing.createDraft(
      id: ListingId.fromString(listingId),
      title: data['title'] as String,
      description: data['description'] as String,
      price: price,
      contactInfo: contactInfo,
      media: media,
    ).copyWith(
      status: status,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _paymentToFirestoreMap(Payment payment) {
    return {
      'amount': payment.price.monetaryAmountValue,
      'currency': payment.price.transactionCurrency.isoCurrencyCode,
      'status': payment.status.name,
      'provider': payment.provider.name,
      'method': payment.method.name,
      'providerTransactionId': payment.providerTransactionId,
      'referenceCode': payment.referenceCode,
      'description': payment.description,
      'createdAt': Timestamp.fromDate(payment.createdAt),
      'updatedAt': Timestamp.fromDate(payment.updatedAt),
      'completedAt': payment.completedAt != null
          ? Timestamp.fromDate(payment.completedAt!)
          : null,
      'expiresAt': payment.expiresAt != null
          ? Timestamp.fromDate(payment.expiresAt!)
          : null,
      'providerResponse': payment.providerResponse,
      'errorMessage': payment.errorMessage,
      'receiptData': payment.receiptData,
    };
  }

  Payment _paymentFromFirestoreMap(
    Map<String, dynamic> data,
    String paymentId,
  ) {
    final price = Price.createFromCurrencyCode(
      monetaryAmountValue: (data['amount'] as num).toDouble(),
      isoCurrencyCode: data['currency'] as String,
    );

    final status = PaymentStatus.values.firstWhere(
      (status) => status.name == data['status'],
      orElse: () => PaymentStatus.pending,
    );

    final provider = PaymentProvider.values.firstWhere(
      (provider) => provider.name == data['provider'],
      orElse: () => PaymentProvider.culqi,
    );

    final method = PaymentMethod.values.firstWhere(
      (method) => method.name == data['method'],
      orElse: () => PaymentMethod.card,
    );

    return Payment.create(
      id: PaymentId.fromString(paymentId),
      price: price,
      provider: provider,
      method: method,
      description: data['description'] as String,
      referenceCode: data['referenceCode'] as String?,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    ).copyWith(
      status: status,
      providerTransactionId: data['providerTransactionId'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      providerResponse: data['providerResponse'] as String?,
      errorMessage: data['errorMessage'] as String?,
      receiptData: data['receiptData'] as String?,
    );
  }
}

/// Combined result for listing search with property details
/// WHY: Buyers need both listing info (price, description) and property details (specs, location)
class ListingWithDetails {
  final Listing listing;
  final Property property;

  const ListingWithDetails({required this.listing, required this.property});
}
