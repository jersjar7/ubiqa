// lib/models/2_usecases/features/listings/create_listing_usecase.dart

// Import contracts
import '../../../../services/1_contracts/features/listings/listings_repository.dart';

// Import infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import domain
import '../../../1_domain/shared/entities/listing.dart';
import '../../../1_domain/shared/entities/property.dart';
import '../../../1_domain/shared/value_objects/price.dart';
import '../../../1_domain/shared/value_objects/contact_info.dart';
import '../../../1_domain/shared/value_objects/property_specs.dart';
import '../../../1_domain/shared/value_objects/location.dart';
import '../../../1_domain/shared/value_objects/media.dart';
import '../../../1_domain/domain_orchestrator.dart';

/// Create Listing Use Case
///
/// Handles new listing creation with property data.
/// Orchestrates domain entity creation and repository persistence.
/// Used when user submits the new listing form.
class CreateListingUseCase {
  final IListingsRepository _repository;

  CreateListingUseCase(this._repository);

  /// Execute: Create new listing with associated property
  ///
  /// Takes raw form data, creates domain entities with validation,
  /// and persists through repository.
  ///
  /// Parameters:
  /// - listingTitle: Title for the listing
  /// - listingDescription: Detailed description
  /// - listingPrice: Price value object
  /// - listingContactInfo: Optional contact information
  /// - propertyType: Type of property (casa, departamento, etc.)
  /// - operationType: Venta or Alquiler
  /// - propertySpecs: Property specifications (area, rooms, etc.)
  /// - propertyLocation: Location with address and coordinates
  /// - selectedAmenities: Optional list of property amenities
  ///
  /// Returns:
  /// - Success with created Listing entity
  /// - Failure with validation errors or persistence errors
  Future<ServiceResult<Listing>> execute({
    required String listingTitle,
    required String listingDescription,
    required Price listingPrice,
    ContactInfo? listingContactInfo,
    required PropertyType propertyType,
    required OperationType operationType,
    required PropertySpecs propertySpecs,
    required Location propertyLocation,
    List<String>? selectedAmenities,
  }) async {
    try {
      // STEP 1: Validate inputs
      final validationResult = _validateInputs(
        listingTitle: listingTitle,
        listingDescription: listingDescription,
        propertySpecs: propertySpecs,
        propertyLocation: propertyLocation,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Listing creation validation failed',
          validationResult.exception!,
        );
      }

      // STEP 2: Generate unique IDs for listing and property
      final listingId = ListingId.fromString(
        'listing_${DateTime.now().millisecondsSinceEpoch}',
      );
      final propertyId = PropertyId.fromString(
        'property_${DateTime.now().millisecondsSinceEpoch}',
      );

      // STEP 3: Create Property entity
      final property = Property.create(
        id: propertyId,
        propertyType: propertyType,
        operationType: operationType,
        specs: propertySpecs,
        location: propertyLocation,
        media: Media.createEmpty(), // Photos will be added in future version
      );

      // STEP 4: Create Listing entity as draft
      final listing = Listing.createDraft(
        id: listingId,
        title: listingTitle,
        description: listingDescription,
        price: listingPrice,
        contactInfo: listingContactInfo,
        media: Media.createEmpty(),
      );

      // Activate the listing - sets publishedAt and expiresAt
      final activatedListing = listing.activate();

      // STEP 5: Persist through repository
      final result = await _repository.createListing(
        listing: activatedListing,
        property: property,
      );


      if (!result.isSuccess) {
        return ServiceResult.failure(
          'Failed to save listing',
          result.exception!,
        );
        }

      // TEMPORARY: Return success for now
      return ServiceResult.success(listing);
    } catch (e) {
      return ServiceResult.failure(
        'Listing creation execution failed',
        ServiceException(
          'Unexpected error during listing creation',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validateInputs({
    required String listingTitle,
    required String listingDescription,
    required PropertySpecs propertySpecs,
    required Location propertyLocation,
  }) {
    final errors = <String>[];

    // Validate title
    if (listingTitle.trim().isEmpty) {
      errors.add('Title cannot be empty');
    } else if (listingTitle.trim().length < 10) {
      errors.add('Title must be at least 10 characters');
    }

    // Validate description
    if (listingDescription.trim().isEmpty) {
      errors.add('Description cannot be empty');
    } else if (listingDescription.trim().length < 20) {
      errors.add('Description must be at least 20 characters');
    }

    // Validate property specs
    if (propertySpecs.totalAreaInSquareMeters <= 0) {
      errors.add('Area must be greater than 0');
    }

    // Validate location
    if (propertyLocation.fullStreetAddress.trim().isEmpty) {
      errors.add('Address cannot be empty');
    }
    if (propertyLocation.administrativeDistrict.trim().isEmpty) {
      errors.add('District cannot be empty');
    }

    // Return validation result
    if (errors.isNotEmpty) {
      return ServiceResult.failure(
        'Validation errors',
        ServiceException(
          errors.join(', '),
          ServiceErrorType.validation,
        ),
      );
    }

    return ServiceResult.successVoid();
  }
}