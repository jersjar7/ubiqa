// lib/ui/1_state/features/listings/listings_state.dart

import 'package:equatable/equatable.dart';
import 'package:ubiqa/models/1_domain/shared/entities/listing.dart';

// Import contracts
import '../../../../services/1_contracts/features/listings/listings_repository.dart';

// Import domain
import '../../../../models/1_domain/domain_orchestrator.dart';

/// Base class for all listings states
abstract class ListingsState extends Equatable {
  const ListingsState();

  @override
  List<Object?> get props => [];
}

/// State: Initial state before any data loaded
class ListingsInitial extends ListingsState {
  const ListingsInitial();
}

/// State: Loading listings from repository
class ListingsLoading extends ListingsState {
  final OperationType operationType;

  const ListingsLoading(this.operationType);

  @override
  List<Object?> get props => [operationType];
}

/// State: Listings successfully loaded
/// Contains list of listings and current operation type
class ListingsLoaded extends ListingsState {
  final List<ListingWithDetails> listings;
  final OperationType operationType;

  const ListingsLoaded({required this.listings, required this.operationType});

  @override
  List<Object?> get props => [listings, operationType];

  /// Helper: Check if there are no listings
  bool get isEmpty => listings.isEmpty;

  /// Helper: Get listing count
  int get count => listings.length;
}

/// State: Error loading listings
class ListingsError extends ListingsState {
  final String message;
  final OperationType? attemptedOperationType;

  const ListingsError({required this.message, this.attemptedOperationType});

  @override
  List<Object?> get props => [message, attemptedOperationType];
}

/// State: Loading single listing details
class ListingDetailLoading extends ListingsState {
  // Keep previous listings loaded in background
  final List<ListingWithDetails> backgroundListings;
  final OperationType backgroundOperationType;

  const ListingDetailLoading({
    required this.backgroundListings,
    required this.backgroundOperationType,
  });

  @override
  List<Object?> get props => [backgroundListings, backgroundOperationType];
}

/// State: Listing details successfully loaded
class ListingDetailLoaded extends ListingsState {
  final ListingWithDetails listingDetail;
  // Keep previous listings in background to return to
  final List<ListingWithDetails> backgroundListings;
  final OperationType backgroundOperationType;

  const ListingDetailLoaded({
    required this.listingDetail,
    required this.backgroundListings,
    required this.backgroundOperationType,
  });

  @override
  List<Object?> get props => [
    listingDetail,
    backgroundListings,
    backgroundOperationType,
  ];
}

/// State: Error loading listing details
class ListingDetailError extends ListingsState {
  final String message;
  // Keep previous listings to return to
  final List<ListingWithDetails> backgroundListings;
  final OperationType backgroundOperationType;

  const ListingDetailError({
    required this.message,
    required this.backgroundListings,
    required this.backgroundOperationType,
  });

  @override
  List<Object?> get props => [
    message,
    backgroundListings,
    backgroundOperationType,
  ];
}

/// State: Creating new listing
/// Emitted while listing is being saved to repository
class ListingCreating extends ListingsState {
  const ListingCreating();
}

/// State: Listing successfully created
/// Emitted when listing creation completes successfully
class ListingCreated extends ListingsState {
  final Listing createdListing;
  final String successMessage;

  const ListingCreated({
    required this.createdListing,
    this.successMessage = 'Propiedad publicada exitosamente',
  });

  @override
  List<Object?> get props => [createdListing, successMessage];
}

/// State: Error creating listing
/// Emitted when listing creation fails with error details
class ListingCreationError extends ListingsState {
  final String errorMessage;
  final List<String>? validationErrors;

  const ListingCreationError({
    required this.errorMessage,
    this.validationErrors,
  });

  @override
  List<Object?> get props => [errorMessage, validationErrors];
}
