// lib/models/2_usecases/features/listings/get_active_listings_usecase.dart

// Import contracts
import '../../../../services/1_contracts/features/listings/listings_repository.dart';

// Import infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import domain
import '../../../1_domain/domain_orchestrator.dart';

/// Get Active Listings Use Case
///
/// Fetches active listings filtered by operation type for map display.
/// Delegates to repository which handles caching strategy.
class GetActiveListingsUseCase {
  final IListingsRepository _repository;

  GetActiveListingsUseCase(this._repository);

  /// Execute: Get all active listings for specified operation type
  /// Used by map view with venta/alquiler toggle
  Future<ServiceResult<List<ListingWithDetails>>> execute(
    OperationType operationType,
  ) async {
    return await _repository.fetchActiveListingsByOperationType(operationType);
  }
}
