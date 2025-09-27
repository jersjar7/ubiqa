// lib/services/3_datasources/features/listings/listings_firestore_datasource.dart

// Import horizontal foundation - infrastructure
import '../../../4_infrastructure/firebase/firestore_service.dart';
import '../../../4_infrastructure/shared/service_result.dart';

// Import horizontal foundation - domain
import '../../../../models/1_domain/shared/entities/listing.dart';
import '../../../../models/1_domain/domain_orchestrator.dart';

// Import contract types (ListingWithDetails defined here)
import '../../../1_contracts/features/listings/listings_repository.dart';

/// Listings Firestore Data Source
///
/// Wraps FirestoreService to provide listing data operations.
/// Pure delegation layer - no caching, no business logic.
///
/// Responsibilities:
/// - Call FirestoreService methods
/// - Pass through ServiceResult responses
/// - Handle Firebase-specific error mapping if needed
class ListingsFirestoreDataSource {
  final FirestoreService _firestoreService;

  ListingsFirestoreDataSource(this._firestoreService);

  /// Fetches all active listings for specified operation type
  /// Delegates to FirestoreService.getActiveListingsByOperationType()
  Future<ServiceResult<List<ListingWithDetails>>>
  fetchActiveListingsByOperationType(OperationType operationType) async {
    return await _firestoreService.getActiveListingsByOperationType(
      operationType,
    );
  }

  /// Fetches single listing with property details by ID
  /// Delegates to FirestoreService.getListingWithDetailsById()
  Future<ServiceResult<ListingWithDetails?>> fetchListingDetailsById(
    ListingId listingId,
  ) async {
    return await _firestoreService.getListingWithDetailsById(listingId);
  }
}
