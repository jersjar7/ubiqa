// lib/ui/1_state/features/listings/listings_event.dart

import 'package:equatable/equatable.dart';
import 'package:ubiqa/models/1_domain/shared/entities/property.dart';

// Import domain
import '../../../../models/1_domain/shared/entities/listing.dart';
import '../../../../models/1_domain/shared/value_objects/price.dart';
import '../../../../models/1_domain/shared/value_objects/contact_info.dart';
import '../../../../models/1_domain/shared/value_objects/property_specs.dart';
import '../../../../models/1_domain/shared/value_objects/location.dart';
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

/// Event: User submitted new listing form
/// Creates both Property and Listing entities
class CreateListingRequested extends ListingsEvent {
  // Listing data
  final String listingTitle;
  final String listingDescription;
  final Price listingPrice;
  final ContactInfo? listingContactInfo;

  // Property data
  final PropertyType propertyType;
  final OperationType operationType;
  final PropertySpecs propertySpecs;
  final Location propertyLocation;

  // Optional amenities list
  final List<String>? selectedAmenities;

  const CreateListingRequested({
    required this.listingTitle,
    required this.listingDescription,
    required this.listingPrice,
    this.listingContactInfo,
    required this.propertyType,
    required this.operationType,
    required this.propertySpecs,
    required this.propertyLocation,
    this.selectedAmenities,
  });

  @override
  List<Object?> get props => [
        listingTitle,
        listingDescription,
        listingPrice,
        listingContactInfo,
        propertyType,
        operationType,
        propertySpecs,
        propertyLocation,
        selectedAmenities,
      ];
}