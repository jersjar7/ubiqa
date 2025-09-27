// lib/services/1_contracts/features/listings/listings_repository.dart

// Import horizontal foundation - domain entities
import 'package:ubiqa/models/1_domain/shared/entities/listing.dart';
import 'package:ubiqa/models/1_domain/shared/entities/property.dart';

// Import domain orchestrator for OperationType
import 'package:ubiqa/models/1_domain/domain_orchestrator.dart';

// Import horizontal foundation - infrastructure
import 'package:ubiqa/services/4_infrastructure/shared/service_result.dart';

/// Composite object combining Listing and Property data
/// Used for map display and detail views
class ListingWithDetails {
  final Listing listing;
  final Property property;

  const ListingWithDetails({required this.listing, required this.property});

  @override
  String toString() {
    return 'ListingWithDetails(listing: ${listing.id.value}, property: ${property.id.value})';
  }
}

/// Listings repository contract
///
/// Defines listing data operations for Ubiqa V1 MVP.
/// Focused on map display with price bubbles and listing details.
///
/// V1 Scope (Piura only):
/// - Show all active listings on map as price bubbles
/// - Toggle between venta/alquiler
/// - View listing details when bubble tapped
///
/// Future enhancements:
/// - Geographic filtering (bounding box, radius)
/// - Advanced filters (price range, bedrooms, etc.)
/// - Real-time updates
/// - Pagination
abstract class IListingsRepository {
  /// Fetches all active listings for the specified operation type
  ///
  /// Used for map display with price bubbles showing property prices.
  /// Only returns listings with status = ListingStatus.active.
  ///
  /// V1 Implementation Notes:
  /// - Returns ALL active listings in Piura (no pagination)
  /// - Results may be cached (implementation-specific)
  /// - Cache auto-expires after reasonable TTL (e.g., 10 minutes)
  ///
  /// Parameters:
  /// - [operationType]: Either OperationType.venta or OperationType.alquiler
  ///
  /// Returns:
  /// - Success with empty list: No active listings exist (valid state)
  /// - Success with data: List of active listings with full property details
  /// - Failure: Network error, permission error, or server error
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.fetchActiveListingsByOperationType(
  ///   OperationType.venta
  /// );
  ///
  /// if (result.isSuccess) {
  ///   if (result.data!.isEmpty) {
  ///     // Show "No properties available" message
  ///   } else {
  ///     // Display bubbles on map
  ///   }
  /// } else {
  ///   // Show error to user
  /// }
  /// ```
  Future<ServiceResult<List<ListingWithDetails>>>
  fetchActiveListingsByOperationType(OperationType operationType);

  /// Fetches complete details for a specific listing by its ID
  ///
  /// Used when user taps a price bubble on the map to view full listing details.
  /// Only returns listing if it exists AND status = ListingStatus.active.
  ///
  /// Parameters:
  /// - [listingId]: The unique identifier of the listing to fetch
  ///
  /// Returns:
  /// - Success with data: Complete listing and property information
  /// - Failure with notFound: Listing doesn't exist or is not active
  /// - Failure with network: Connection error
  ///
  /// Example:
  /// ```dart
  /// final result = await repository.fetchListingDetailsById(
  ///   ListingId.fromString('listing-123')
  /// );
  ///
  /// if (result.isSuccess) {
  ///   // Show detail view
  /// } else if (result.exception?.errorType == ServiceErrorType.notFound) {
  ///   // Show "Listing no longer available"
  /// } else {
  ///   // Show generic error
  /// }
  /// ```
  Future<ServiceResult<ListingWithDetails>> fetchListingDetailsById(
    ListingId listingId,
  );
}
