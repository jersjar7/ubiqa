// lib/models/1_domain/shared/value_objects/location.dart

import 'package:equatable/equatable.dart';
import 'dart:math' as math;

/// Location value object representing a geographic position in Peru
///
/// This immutable value object encapsulates all location data needed
/// for Ubiqa's map-first property discovery. It handles GPS coordinates,
/// address display, and basic distance calculations.
///
/// V1 Scope: Simple location representation with Google Maps integration
class Location extends Equatable {
  /// GPS latitude coordinate
  final double latitude;

  /// GPS longitude coordinate
  final double longitude;

  /// Human-readable address for display
  final String address;

  /// District name (from Google services)
  final String district;

  /// Country code (always "PE" for Peru in V1)
  final String countryCode;

  const Location._({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.district,
    required this.countryCode,
  });

  /// Creates a Location with validation
  factory Location.create({
    required double latitude,
    required double longitude,
    required String address,
    required String district,
    String countryCode = 'PE',
  }) {
    final location = Location._(
      latitude: latitude,
      longitude: longitude,
      address: address.trim(),
      district: district.trim(),
      countryCode: countryCode.toUpperCase(),
    );

    final violations = location._validate();
    if (violations.isNotEmpty) {
      throw LocationException('Invalid location data', violations);
    }

    return location;
  }

  /// Creates a Location from Google Places API response
  factory Location.fromGooglePlaces({
    required double latitude,
    required double longitude,
    required String formattedAddress,
    required String district,
  }) {
    return Location.create(
      latitude: latitude,
      longitude: longitude,
      address: formattedAddress,
      district: district,
      countryCode: 'PE',
    );
  }

  // LOCATION CALCULATIONS

  /// Calculates distance to another location in kilometers
  double distanceTo(Location other) {
    const double earthRadius = 6371; // Earth's radius in km

    final double lat1Rad = _degreesToRadians(latitude);
    final double lat2Rad = _degreesToRadians(other.latitude);
    final double deltaLatRad = _degreesToRadians(other.latitude - latitude);
    final double deltaLngRad = _degreesToRadians(other.longitude - longitude);

    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Checks if location is within specified radius of another location
  bool isWithinRadius(Location center, double radiusKm) {
    return distanceTo(center) <= radiusKm;
  }

  // DISPLAY AND FORMATTING

  /// Gets formatted address for UI display
  String getFormattedAddress() {
    return '$address, $district';
  }

  /// Gets short display format (district only)
  String getShortDisplay() {
    return district;
  }

  /// Gets coordinates as string for debugging
  String getCoordinatesString() {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // GOOGLE MAPS INTEGRATION

  /// Gets Google Maps URL for this location
  String getGoogleMapsUrl() {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  /// Gets Google Maps static map URL for property images
  String getStaticMapUrl({int width = 400, int height = 300, int zoom = 15}) {
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$latitude,$longitude&'
        'zoom=$zoom&'
        'size=${width}x$height&'
        'markers=color:red%7C$latitude,$longitude&'
        'key=YOUR_API_KEY'; // Will be replaced by infrastructure layer
  }

  // VALIDATION

  /// Validates location data
  List<String> _validate() {
    final errors = <String>[];

    // Coordinate validation
    if (latitude < -90 || latitude > 90) {
      errors.add('Latitude must be between -90 and 90 degrees');
    }
    if (longitude < -180 || longitude > 180) {
      errors.add('Longitude must be between -180 and 180 degrees');
    }

    // Peru bounds check (approximate)
    if (!_isWithinPeruBounds()) {
      errors.add('Coordinates must be within Peru');
    }

    // Address validation
    if (address.trim().isEmpty) {
      errors.add('Address cannot be empty');
    }
    if (address.length > 200) {
      errors.add('Address cannot exceed 200 characters');
    }

    // District validation
    if (district.trim().isEmpty) {
      errors.add('District cannot be empty');
    }
    if (district.length > 100) {
      errors.add('District cannot exceed 100 characters');
    }

    // Country validation
    if (countryCode != 'PE') {
      errors.add('Only Peru locations are supported in V1');
    }

    return errors;
  }

  /// Checks if coordinates are within Peru's approximate bounds
  bool _isWithinPeruBounds() {
    // Peru approximate bounds
    const double minLat = -18.5;
    const double maxLat = -0.0;
    const double minLng = -81.5;
    const double maxLng = -68.5;

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }

  /// Converts degrees to radians for calculations
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object> get props => [
    latitude,
    longitude,
    address,
    district,
    countryCode,
  ];

  @override
  String toString() {
    return 'Location(${getCoordinatesString()}, $district)';
  }
}

/// Exception for location validation errors
class LocationException implements Exception {
  final String message;
  final List<String> violations;

  const LocationException(this.message, this.violations);

  @override
  String toString() =>
      'LocationException: $message\nViolations: ${violations.join(', ')}';
}

/// Location domain service for common operations
class LocationDomainService {
  /// Default search radius in kilometers for "nearby" properties
  static const double defaultSearchRadiusKm = 5.0;

  /// Maximum reasonable search radius in kilometers
  static const double maxSearchRadiusKm = 50.0;

  /// Finds locations within search radius
  static List<Location> findLocationsWithinRadius(
    List<Location> locations,
    Location center,
    double radiusKm,
  ) {
    if (radiusKm > maxSearchRadiusKm) {
      throw ArgumentError('Search radius cannot exceed $maxSearchRadiusKm km');
    }

    return locations
        .where((location) => location.isWithinRadius(center, radiusKm))
        .toList();
  }

  /// Sorts locations by distance from center point
  static List<Location> sortByDistance(
    List<Location> locations,
    Location center,
  ) {
    final locationsWithDistance = locations
        .map(
          (location) => {
            'location': location,
            'distance': location.distanceTo(center),
          },
        )
        .toList();

    locationsWithDistance.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );

    return locationsWithDistance
        .map((item) => item['location'] as Location)
        .toList();
  }

  /// Gets display distance string for UI
  static String getDistanceDisplay(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  /// Validates location is suitable for property listing
  static List<String> validateForPropertyListing(Location location) {
    final errors = <String>[];

    // Must be within reasonable urban bounds for Piura
    // These are rough coordinates for Piura metropolitan area
    const double piuraMinLat = -5.3;
    const double piuraMaxLat = -5.1;
    const double piuraMinLng = -80.8;
    const double piuraMaxLng = -80.5;

    if (location.latitude < piuraMinLat ||
        location.latitude > piuraMaxLat ||
        location.longitude < piuraMinLng ||
        location.longitude > piuraMaxLng) {
      errors.add('Location appears to be outside Piura metropolitan area');
    }

    return errors;
  }
}
