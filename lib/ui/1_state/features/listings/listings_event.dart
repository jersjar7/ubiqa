// lib/ui/1_state/features/listings/listings_event.dart

import 'package:equatable/equatable.dart';

// Import domain
import '../../../../models/1_domain/shared/entities/listing.dart';
import '../../../../models/1_domain/domain_orchestrator.dart';

/// Base class for all listings events
abstract class ListingsEvent extends Equatable {
  const ListingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load active listings for specified operation type
/// Triggered on initial load or when user toggles venta/alquiler
class LoadListingsRequested extends ListingsEvent {
  final OperationType operationType;

  const LoadListingsRequested(this.operationType);

  @override
  List<Object?> get props => [operationType];
}

/// Event: User tapped a listing bubble on map
/// Triggers detail view load
class ListingSelected extends ListingsEvent {
  final ListingId listingId;

  const ListingSelected(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

/// Event: User closed detail view and returned to map
/// Clears detail state
class ListingDetailsClosed extends ListingsEvent {
  const ListingDetailsClosed();
}
