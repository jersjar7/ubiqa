// lib/ui/2_presentation/features/listings/pages/home_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Import DI
import '../../../../../services/5_injection/dependency_container.dart';

// Import BLoC
import '../../../../1_state/features/listings/listings_bloc.dart';
import '../../../../1_state/features/listings/listings_event.dart';
import '../../../../1_state/features/listings/listings_state.dart';

// Import widgets
import '../widgets/operation_type_toggle.dart';
import '../widgets/listing_detail_panel.dart';
import '../widgets/empty_state_message.dart';
import '../widgets/new_listing.dart'; // ✅ ADD THIS IMPORT

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Import domain
import '../../../../../models/1_domain/domain_orchestrator.dart';

/// Home Page - Map View with Listings
///
/// Main landing page showing property listings on map.
/// Default: Venta listings centered on Piura.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Piura city center coordinates
  static const LatLng _piuraCenterLatLng = LatLng(-5.0645, -80.4328);
  static const double _defaultZoom = 8.0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          UbiqaDependencyContainer.get<ListingsBloc>()
            ..add(const LoadListingsRequested(OperationType.venta)),
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Track if we should show empty state message
  // This key helps Flutter know when to recreate the widget (reset timer)
  Key _emptyStateKey = UniqueKey();

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ListingsBloc, ListingsState>(
        listener: (context, state) {
          if (state is ListingsLoaded) {
            _updateMarkers(state);

            // Reset empty state message when listings are empty
            // This recreates the widget with a new key, restarting the timer
            if (state.isEmpty) {
              setState(() => _emptyStateKey = UniqueKey());
            }
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: HomePage._piuraCenterLatLng,
                  zoom: HomePage._defaultZoom,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Operation Type Toggle (top-right)
              if (state is ListingsLoaded)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: OperationTypeToggle(
                    currentType: state.operationType,
                    onToggle: (type) {
                      context.read<ListingsBloc>().add(
                            LoadListingsRequested(type),
                          );
                    },
                  ),
                ),

              // Only show when NOT displaying detail panel
              if (state is! ListingDetailLoaded)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  right: 16,
                  child: const NewListingButton(),
                ),

              // Loading indicator
              if (state is ListingsLoading)
                Center(
                  child: CupertinoActivityIndicator(
                    radius: 16,
                    color: AppColors.primary,
                  ),
                ),

              // Empty state message - auto-dismissible notification
              if (state is ListingsLoaded && state.isEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  child: EmptyStateMessage(
                    key: _emptyStateKey,
                    message: 'Pronto, más propiedades disponibles',
                  ),
                ),

              // Error state
              if (state is ListingsError)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar propiedades',
                          style: AppTextStyles.subheadline,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton(
                          color: AppColors.primary,
                          onPressed: () {
                            context.read<ListingsBloc>().add(
                                  LoadListingsRequested(
                                    state.attemptedOperationType ??
                                        OperationType.venta,
                                  ),
                                );
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Detail Panel
              if (state is ListingDetailLoaded)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ListingDetailPanel(
                    listingDetail: state.listingDetail,
                    onClose: () {
                      context.read<ListingsBloc>().add(
                            const ListingDetailsClosed(),
                          );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _updateMarkers(ListingsLoaded state) {
    _markers.clear();

    for (final listingDetail in state.listings) {
      final location = listingDetail.property.location;

      _markers.add(
        Marker(
          markerId: MarkerId(listingDetail.listing.id.value),
          position: LatLng(
            location.latitudeInDecimalDegrees,
            location.longitudeInDecimalDegrees,
          ),
          onTap: () {
            context.read<ListingsBloc>().add(
                  ListingSelected(listingDetail.listing.id),
                );
          },
          // Note: Custom marker widget rendering requires additional setup
          // For MVP, using default markers with infoWindow
          infoWindow: InfoWindow(
            title: listingDetail.listing.title,
            snippet:
                '${listingDetail.listing.price.transactionCurrency.currencySymbol}${listingDetail.listing.price.monetaryAmountValue.toInt()}',
          ),
        ),
      );
    }

    if (mounted) setState(() {});
  }
}