// lib/models/2_usecases/features/listings/get_listing_details_usecase.dart

// Import contracts
import '../../../../services/1_contracts/features/listings/listings_repository.dart';

// Import infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import domain
import '../../../1_domain/shared/entities/listing.dart';

/// Get Listing Details Use Case
///
/// Fetches complete details for a specific listing.
/// Used when user taps price bubble on map.
class GetListingDetailsUseCase {
  final IListingsRepository _repository;

  GetListingDetailsUseCase(this._repository);

  /// Execute: Get complete listing and property details by ID
  /// Returns error if listing doesn't exist or is not active
  Future<ServiceResult<ListingWithDetails>> execute(ListingId listingId) async {
    // Call repository (which returns nullable ListingWithDetails?)
    final result = await _repository.fetchListingDetailsById(listingId);

    // Handle the result
    if (result.isSuccess) {
      // Check if data is null (listing not found)
      if (result.data == null) {
        return ServiceResult.failure(
          'Listing not found or no longer available',
          ServiceException(
            'Listing does not exist or is not active',
            ServiceErrorType.notFound,
          ),
        );
      }
      // Data exists, return it (non-nullable now)
      return ServiceResult.success(result.data!);
    }

    // Repository returned an error, pass it through
    return ServiceResult.failure(
      result.errorMessage!,
      result.exception!,
    );
  }
}