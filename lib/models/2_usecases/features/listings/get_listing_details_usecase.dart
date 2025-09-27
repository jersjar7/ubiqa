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
    return await _repository.fetchListingDetailsById(listingId);
  }
}
