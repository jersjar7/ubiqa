// lib/ui/1_state/features/listings/listings_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';

// Import use cases
import '../../../../models/2_usecases/features/listings/get_active_listings_usecase.dart';
import '../../../../models/2_usecases/features/listings/get_listing_details_usecase.dart';
// ✅ ADD THIS: Import create listing use case (once it's created)
// import '../../../../models/2_usecases/features/listings/create_listing_usecase.dart';

// Import state and events
import 'listings_event.dart';
import 'listings_state.dart';

/// Listings BLoC
///
/// Manages state for listing map view and detail view.
/// Orchestrates listing operations through use cases.
class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  final GetActiveListingsUseCase _getActiveListingsUseCase;
  final GetListingDetailsUseCase _getListingDetailsUseCase;
  // ✅ ADD THIS: Create listing use case dependency (once it's created)
  // final CreateListingUseCase _createListingUseCase;

  ListingsBloc({
    required GetActiveListingsUseCase getActiveListingsUseCase,
    required GetListingDetailsUseCase getListingDetailsUseCase,
    // ✅ ADD THIS: Add to constructor parameters (once use case is created)
    // required CreateListingUseCase createListingUseCase,
  })  : _getActiveListingsUseCase = getActiveListingsUseCase,
        _getListingDetailsUseCase = getListingDetailsUseCase,
        // ✅ ADD THIS: Initialize use case (once it's created)
        // _createListingUseCase = createListingUseCase,
        super(const ListingsInitial()) {
    print('🏠 [ListingsBloc] Constructor called');

    // Register event handlers
    on<LoadListingsRequested>(_onLoadListingsRequested);
    on<ListingSelected>(_onListingSelected);
    on<ListingDetailsClosed>(_onListingDetailsClosed);
    // ✅ ADD THIS: Register create listing handler
    on<CreateListingRequested>(_onCreateListingRequested);

    print('✅ [ListingsBloc] Event handlers registered');
  }

  /// Handles loading listings for specified operation type
  Future<void> _onLoadListingsRequested(
    LoadListingsRequested event,
    Emitter<ListingsState> emit,
  ) async {
    print('🏠 [ListingsBloc] LoadListingsRequested event received');
    print('🏠 [ListingsBloc] Operation type: ${event.operationType.name}');

    emit(ListingsLoading(event.operationType));
    print('🏠 [ListingsBloc] Emitted ListingsLoading state');

    print('🏠 [ListingsBloc] Calling GetActiveListingsUseCase...');
    final result = await _getActiveListingsUseCase.execute(event.operationType);

    print('🏠 [ListingsBloc] Use case completed');
    print('🏠 [ListingsBloc] Result success: ${result.isSuccess}');

    if (result.isSuccess) {
      print(
        '✅ [ListingsBloc] Successfully loaded ${result.data!.length} listings',
      );
      emit(
        ListingsLoaded(
          listings: result.data!,
          operationType: event.operationType,
        ),
      );
      print('✅ [ListingsBloc] Emitted ListingsLoaded state');
    } else {
      print('❌ [ListingsBloc] Failed to load listings');
      print('❌ [ListingsBloc] Error: ${result.getErrorMessage()}');
      print('❌ [ListingsBloc] Exception type: ${result.exception?.type}');
      emit(
        ListingsError(
          message: result.getErrorMessage(),
          attemptedOperationType: event.operationType,
        ),
      );
      print('❌ [ListingsBloc] Emitted ListingsError state');
    }
  }

  /// Handles listing selection for detail view
  Future<void> _onListingSelected(
    ListingSelected event,
    Emitter<ListingsState> emit,
  ) async {
    print('🏠 [ListingsBloc] ListingSelected event received');

    // Preserve current listings in background
    final currentState = state;
    if (currentState is ListingsLoaded) {
      emit(
        ListingDetailLoading(
          backgroundListings: currentState.listings,
          backgroundOperationType: currentState.operationType,
        ),
      );

      final result = await _getListingDetailsUseCase.execute(event.listingId);

      if (result.isSuccess) {
        emit(
          ListingDetailLoaded(
            listingDetail: result.data!,
            backgroundListings: currentState.listings,
            backgroundOperationType: currentState.operationType,
          ),
        );
      } else {
        // Return to loaded state on error
        emit(currentState);
      }
    }
  }

  /// Handles closing detail view
  void _onListingDetailsClosed(
    ListingDetailsClosed event,
    Emitter<ListingsState> emit,
  ) {
    print('🏠 [ListingsBloc] ListingDetailsClosed event received');

    final currentState = state;
    if (currentState is ListingDetailLoaded) {
      emit(
        ListingsLoaded(
          listings: currentState.backgroundListings,
          operationType: currentState.backgroundOperationType,
        ),
      );
    }
  }

  // ✅ NEW HANDLER: Handles creating new listing
  Future<void> _onCreateListingRequested(
    CreateListingRequested event,
    Emitter<ListingsState> emit,
  ) async {
    print('🏠 [ListingsBloc] CreateListingRequested event received');

    // Emit loading state
    emit(const ListingCreating());
    print('🏠 [ListingsBloc] Emitted ListingCreating state');

    // TODO: Call use case once it's created
    // final result = await _createListingUseCase.execute(
    //   listingTitle: event.listingTitle,
    //   listingDescription: event.listingDescription,
    //   listingPrice: event.listingPrice,
    //   propertyType: event.propertyType,
    //   operationType: event.operationType,
    //   propertySpecs: event.propertySpecs,
    //   propertyLocation: event.propertyLocation,
    //   selectedAmenities: event.selectedAmenities,
    // );

    // TODO: Handle result
    // if (result.isSuccess) {
    //   print('✅ [ListingsBloc] Listing created successfully');
    //   emit(ListingCreated(createdListing: result.data!));
    // } else {
    //   print('❌ [ListingsBloc] Failed to create listing');
    //   emit(ListingCreationError(errorMessage: result.getErrorMessage()));
    // }

    // TEMPORARY: For now, simulate success
    await Future.delayed(const Duration(seconds: 1));
    print('⚠️ [ListingsBloc] TODO: Create listing use case not implemented yet');
    emit(const ListingCreationError(
      errorMessage: 'Create listing use case not yet implemented',
    ));
  }
}