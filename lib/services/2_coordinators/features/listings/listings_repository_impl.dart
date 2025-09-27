// lib/services/2_coordinators/features/listings/listings_repository_impl.dart

// Import contracts
import '../../../1_contracts/features/listings/listings_repository.dart';

// Import data sources
import '../../../3_datasources/features/listings/listings_firestore_datasource.dart';

// Import infrastructure
import '../../../4_infrastructure/shared/service_result.dart';

// Import domain
import '../../../../models/1_domain/shared/entities/listing.dart';
import '../../../../models/1_domain/domain_orchestrator.dart';

/// Listings Repository Implementation
///
/// Coordinates listing data operations with intelligent caching.
/// Implements IListingsRepository contract using FirestoreDataSource.
///
/// Caching Strategy:
/// - 10-minute TTL for active listings
/// - Separate cache per OperationType (venta/alquiler)
/// - Auto-invalidation on cache expiry
/// - No manual refresh needed (following Zillow pattern)
class ListingsRepositoryImpl implements IListingsRepository {
  final ListingsFirestoreDataSource _dataSource;

  // Cache storage
  final Map<OperationType, List<ListingWithDetails>> _cache = {};
  final Map<OperationType, DateTime> _cacheTimestamps = {};

  // Cache configuration
  static const Duration _cacheDuration = Duration(minutes: 10);

  ListingsRepositoryImpl(this._dataSource);

  @override
  Future<ServiceResult<List<ListingWithDetails>>>
  fetchActiveListingsByOperationType(OperationType operationType) async {
    // Check cache validity
    if (_isCacheValid(operationType)) {
      return ServiceResult.success(_cache[operationType]!);
    }

    // Fetch fresh data
    final result = await _dataSource.fetchActiveListingsByOperationType(
      operationType,
    );

    // Update cache on success
    if (result.isSuccess && result.data != null) {
      _cache[operationType] = result.data!;
      _cacheTimestamps[operationType] = DateTime.now();
    }

    return result;
  }

  @override
  Future<ServiceResult<ListingWithDetails>> fetchListingDetailsById(
    ListingId listingId,
  ) async {
    // No caching for detail views - always fetch fresh
    // WHY: Detail views are one-time, user expects latest data
    final result = await _dataSource.fetchListingDetailsById(listingId);

    if (result.isSuccess && result.data != null) {
      return ServiceResult.success(result.data!);
    }

    // Convert null to notFound error
    if (result.isSuccess && result.data == null) {
      return ServiceResult.failure(
        'Listing not found or no longer available',
        ServiceException('Listing not found', ServiceErrorType.notFound),
      );
    }

    return ServiceResult.failure(result.errorMessage!, result.exception);
  }

  // CACHE MANAGEMENT

  /// Checks if cached data is still valid
  bool _isCacheValid(OperationType operationType) {
    if (!_cache.containsKey(operationType)) return false;
    if (!_cacheTimestamps.containsKey(operationType)) return false;

    final cachedAt = _cacheTimestamps[operationType]!;
    final now = DateTime.now();
    final age = now.difference(cachedAt);

    return age < _cacheDuration;
  }

  /// Invalidates all cached data
  /// Call when app returns to foreground or on significant state changes
  void invalidateCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Invalidates cache for specific operation type
  void invalidateCacheForOperationType(OperationType operationType) {
    _cache.remove(operationType);
    _cacheTimestamps.remove(operationType);
  }
}
