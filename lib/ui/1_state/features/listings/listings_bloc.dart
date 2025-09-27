// lib/ui/1_state/features/listings/listings_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';

// Import use cases
import '../../../../models/2_usecases/features/listings/get_active_listings_usecase.dart';
import '../../../../models/2_usecases/features/listings/get_listing_details_usecase.dart';

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

  ListingsBloc({
    required GetActiveListingsUseCase getActiveListingsUseCase,
    required GetListingDetailsUseCase getListingDetailsUseCase,
  }) : _getActiveListingsUseCase = getActiveListingsUseCase,
       _getListingDetailsUseCase = getListingDetailsUseCase,
       super(const ListingsInitial()) {
    // Register event handlers
    on<LoadListingsRequested>(_onLoadListingsRequested);
    on<ListingSelected>(_onListingSelected);
    on<ListingDetailsClosed>(_onListingDetailsClosed);
  }

  /// Handles loading listings for specified operation type
  Future<void> _onLoadListingsRequested(
    LoadListingsRequested event,
    Emitter<ListingsState> emit,
  ) async {
    emit(ListingsLoading(event.operationType));

    final result = await _getActiveListingsUseCase.execute(event.operationType);

    if (result.isSuccess) {
      emit(
        ListingsLoaded(
          listings: result.data!,
          operationType: event.operationType,
        ),
      );
    } else {
      emit(
        ListingsError(
          message: result.getErrorMessage(),
          attemptedOperationType: event.operationType,
        ),
      );
    }
  }

  /// Handles listing selection for detail view
  Future<void> _onListingSelected(
    ListingSelected event,
    Emitter<ListingsState> emit,
  ) async {
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
        emit(
          ListingDetailError(
            message: result.getErrorMessage(),
            backgroundListings: currentState.listings,
            backgroundOperationType: currentState.operationType,
          ),
        );
      }
    }
  }

  /// Handles closing detail view and returning to map
  void _onListingDetailsClosed(
    ListingDetailsClosed event,
    Emitter<ListingsState> emit,
  ) {
    // Return to previous listings loaded state
    final currentState = state;
    if (currentState is ListingDetailLoaded) {
      emit(
        ListingsLoaded(
          listings: currentState.backgroundListings,
          operationType: currentState.backgroundOperationType,
        ),
      );
    } else if (currentState is ListingDetailError) {
      emit(
        ListingsLoaded(
          listings: currentState.backgroundListings,
          operationType: currentState.backgroundOperationType,
        ),
      );
    }
  }
}
