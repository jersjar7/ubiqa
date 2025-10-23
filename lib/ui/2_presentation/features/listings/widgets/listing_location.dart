// lib/ui/2_presentation/features/listings/widgets/map_location_picker.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

/// Interactive map widget for selecting property location
///
/// Allows users to explore a map freely by panning and zooming,
/// then drop a pin anywhere to set the exact location of their property.
/// Much more intuitive than manually entering coordinates.
class MapLocationPicker extends StatefulWidget {
  /// Initial latitude (defaults to Piura city center)
  final double? initialLatitude;

  /// Initial longitude (defaults to Piura city center)
  final double? initialLongitude;

  /// Callback when location is selected
  final Function(double latitude, double longitude) onLocationSelected;

  /// Optional error text to display
  final String? errorText;

  const MapLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.errorText,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;

  // Default to Piura city center
  static const LatLng _piuraCenter = LatLng(-5.0645, -80.4328);

  // Piura region bounds (more generous to allow full exploration)
  // static final LatLngBounds _piuraBounds = LatLngBounds(
  //   southwest: const LatLng(-5.5, -81.0),  // Southwest corner
  //   northeast: const LatLng(-4.5, -80.0),  // Northeast corner
  // );

  @override
  void initState() {
    super.initState();
    // Set initial location if provided
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    widget.onLocationSelected(position.latitude, position.longitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _centerOnPiura() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_piuraCenter, 13.0),
    );
  }

  void _centerOnSelectedLocation() {
    if (_selectedLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 16.0),
      );
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = CameraPosition(
      target: _selectedLocation ?? _piuraCenter,
      zoom: _selectedLocation != null ? 16.0 : 13.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with instructions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ubicación en el Mapa',
              style: AppTextStyles.formLabel.copyWith(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_selectedLocation != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Ubicación seleccionada',
                      style: AppTextStyles.formLabel.copyWith(
                        color: Colors.green,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Mueve el mapa libremente y toca para colocar un pin. Puedes arrastrar el pin para ajustar la ubicación.',
                  style: AppTextStyles.formLabel.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.0,
                    fontWeight: FontWeight.normal,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),

        // Map container with gesture controls
        Container(
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.errorText != null ? Colors.red : AppColors.border,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: initialCamera,
                  onTap: _onMapTapped,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: _selectedLocation!,
                            draggable: true,
                            onDragEnd: (newPosition) {
                              setState(() {
                                _selectedLocation = newPosition;
                              });
                              widget.onLocationSelected(
                                newPosition.latitude,
                                newPosition.longitude,
                              );
                            },
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                            infoWindow: InfoWindow(
                              title: 'Ubicación de tu propiedad',
                              snippet: 'Arrastra para ajustar',
                            ),
                          ),
                        }
                      : {},
                  // Enable all gesture controls
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  // Disable default UI to use custom controls
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  // Set camera target bounds to Piura region (soft limit)
                  minMaxZoomPreference: const MinMaxZoomPreference(10.0, 20.0),
                  // Map style
                  mapType: MapType.normal,
                ),

                // Zoom control buttons (right side)
                Positioned(
                  right: 12.0,
                  top: 12.0,
                  child: Column(
                    children: [
                      Material(
                        color: Colors.white,
                        elevation: 2.0,
                        borderRadius: BorderRadius.circular(4.0),
                        child: InkWell(
                          onTap: _zoomIn,
                          borderRadius: BorderRadius.circular(4.0),
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.add,
                              color: AppColors.primary,
                              size: 24.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1.0),
                      Material(
                        color: Colors.white,
                        elevation: 2.0,
                        borderRadius: BorderRadius.circular(4.0),
                        child: InkWell(
                          onTap: _zoomOut,
                          borderRadius: BorderRadius.circular(4.0),
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.remove,
                              color: AppColors.primary,
                              size: 24.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick action buttons (bottom right)
                Positioned(
                  right: 12.0,
                  bottom: 12.0,
                  child: Column(
                    children: [
                      // Center on Piura button
                      FloatingActionButton.small(
                        heroTag: 'center_piura',
                        backgroundColor: Colors.white,
                        elevation: 2.0,
                        onPressed: _centerOnPiura,
                        tooltip: 'Centrar en Piura',
                        child: const Icon(
                          Icons.location_city,
                          color: AppColors.primary,
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),

                      // Center on selected location button
                      if (_selectedLocation != null)
                        FloatingActionButton.small(
                          heroTag: 'center_selected',
                          backgroundColor: Colors.white,
                          elevation: 2.0,
                          onPressed: _centerOnSelectedLocation,
                          tooltip: 'Centrar en ubicación seleccionada',
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.green,
                            size: 20.0,
                          ),
                        ),
                    ],
                  ),
                ),

                // Instructions overlay (top left) - shows initially
                if (_selectedLocation == null)
                  Positioned(
                    left: 12.0,
                    top: 12.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: Colors.white,
                            size: 16.0,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            'Toca el mapa para colocar el pin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Error message
        if (widget.errorText != null) ...[
          const SizedBox(height: 8.0),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                widget.errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],

        // Coordinates display (for reference)
        if (_selectedLocation != null) ...[
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.pin_drop, color: Colors.red, size: 18.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordenadas seleccionadas:',
                        style: AppTextStyles.formLabel.copyWith(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: AppTextStyles.formLabel.copyWith(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
