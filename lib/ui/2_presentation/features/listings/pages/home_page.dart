// lib/ui/2_presentation/features/listings/pages/home_page.dart

import 'dart:async';
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
  static const LatLng _piuraCenterLatLng = LatLng(-5.1945, -80.6328);
  static const double _defaultZoom = 12.0;

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

  // Empty state timer management
  Timer? _emptyStateTimer;
  bool _showEmptyStateMessage = true;

  @override
  void dispose() {
    _mapController?.dispose();
    _emptyStateTimer?.cancel();
    super.dispose();
  }

  void _startEmptyStateTimer() {
    // Cancel any existing timer
    _emptyStateTimer?.cancel();

    // Reset visibility
    setState(() => _showEmptyStateMessage = true);

    // Start 5-second timer to hide the message
    _emptyStateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showEmptyStateMessage = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ListingsBloc, ListingsState>(
        listener: (context, state) {
          if (state is ListingsLoaded) {
            _updateMarkers(state);

            // Start timer if listings are empty
            if (state.isEmpty) {
              _startEmptyStateTimer();
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

              // Loading indicator
              if (state is ListingsLoading)
                Center(
                  child: CupertinoActivityIndicator(
                    radius: 16,
                    color: AppColors.primary,
                  ),
                ),

              // Empty state message - temporary toast notification
              if (state is ListingsLoaded && state.isEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  child: IgnorePointer(
                    ignoring: !_showEmptyStateMessage,
                    child: AnimatedOpacity(
                      opacity: _showEmptyStateMessage ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Pronto, más propiedades disponibles',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.callout.copyWith(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Error state
              if (state is ListingsError)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.separator, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
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
