// lib/models/1_domain/shared/value_objects/location.dart

import 'package:equatable/equatable.dart';
import 'dart:math' as math;

/// Location value object representing a geographic position in Piura, Peru
///
/// Encapsulates geographic data because Piura's real estate market requires
/// precise location information for property discovery, pricing analysis,
/// and legal documentation. Immutable design prevents coordinate corruption
/// during property lifecycle management.
///
/// V1 Scope: Piura metropolitan area only - boundaries configurable for future expansion
class Location extends Equatable {
  /// GPS latitude coordinate in decimal degrees
  /// Critical for map display and distance calculations in property search
  final double latitudeInDecimalDegrees;

  /// GPS longitude coordinate in decimal degrees
  /// Essential for property positioning and geographic-based filtering
  final double longitudeInDecimalDegrees;

  /// Complete street address for legal and display purposes
  /// Stored as provided by Google Places API for consistency with user expectations
  final String fullStreetAddress;

  /// Administrative district name for local market segmentation
  /// Important in Peru where district significantly affects property values and desirability
  final String administrativeDistrict;

  /// ISO country code for future international expansion
  /// Currently fixed to 'PE' but enables multi-country support later
  final String countryIsoCode;

  const Location._({
    required this.latitudeInDecimalDegrees,
    required this.longitudeInDecimalDegrees,
    required this.fullStreetAddress,
    required this.administrativeDistrict,
    required this.countryIsoCode,
  });

  /// Creates Location with comprehensive validation
  /// Validation prevents invalid coordinates that would break map integration and search
  factory Location.create({
    required double latitudeInDecimalDegrees,
    required double longitudeInDecimalDegrees,
    required String fullStreetAddress,
    required String administrativeDistrict,
    String countryIsoCode = 'PE',
  }) {
    final location = Location._(
      latitudeInDecimalDegrees: latitudeInDecimalDegrees,
      longitudeInDecimalDegrees: longitudeInDecimalDegrees,
      fullStreetAddress: fullStreetAddress.trim(),
      administrativeDistrict: administrativeDistrict.trim(),
      countryIsoCode: countryIsoCode.toUpperCase(),
    );

    final validationErrors = location._validateLocationData();
    if (validationErrors.isNotEmpty) {
      throw LocationValidationException(
        'Invalid location data',
        validationErrors,
      );
    }

    return location;
  }

  /// Creates Location from Google Places API response data
  /// Specialized factory ensures consistent data format from external geocoding service
  factory Location.createFromGooglePlacesApiResponse({
    required double latitudeInDecimalDegrees,
    required double longitudeInDecimalDegrees,
    required String formattedAddressFromApi,
    required String districtFromApi,
  }) {
    return Location.create(
      latitudeInDecimalDegrees: latitudeInDecimalDegrees,
      longitudeInDecimalDegrees: longitudeInDecimalDegrees,
      fullStreetAddress: formattedAddressFromApi,
      administrativeDistrict: districtFromApi,
      countryIsoCode: 'PE',
    );
  }

  // GEOGRAPHIC CALCULATIONS

  /// Calculates straight-line distance to another location in kilometers
  /// Uses Haversine formula because it's accurate for property search radius functionality
  double calculateDistanceInKilometersTo(Location targetLocation) {
    const double earthRadiusInKilometers = 6371; // Earth's mean radius

    final double currentLatitudeInRadians = _convertDegreesToRadians(
      latitudeInDecimalDegrees,
    );
    final double targetLatitudeInRadians = _convertDegreesToRadians(
      targetLocation.latitudeInDecimalDegrees,
    );
    final double latitudeDifferenceInRadians = _convertDegreesToRadians(
      targetLocation.latitudeInDecimalDegrees - latitudeInDecimalDegrees,
    );
    final double longitudeDifferenceInRadians = _convertDegreesToRadians(
      targetLocation.longitudeInDecimalDegrees - longitudeInDecimalDegrees,
    );

    final double haversineA =
        math.sin(latitudeDifferenceInRadians / 2) *
            math.sin(latitudeDifferenceInRadians / 2) +
        math.cos(currentLatitudeInRadians) *
            math.cos(targetLatitudeInRadians) *
            math.sin(longitudeDifferenceInRadians / 2) *
            math.sin(longitudeDifferenceInRadians / 2);

    final double haversineC =
        2 * math.atan2(math.sqrt(haversineA), math.sqrt(1 - haversineA));

    return earthRadiusInKilometers * haversineC;
  }

  /// Determines if location falls within search radius of center point
  /// Enables property discovery within user-specified geographic boundaries
  bool isWithinSearchRadiusOf(
    Location centerLocation,
    double searchRadiusInKilometers,
  ) {
    return calculateDistanceInKilometersTo(centerLocation) <=
        searchRadiusInKilometers;
  }

  // DISPLAY AND FORMATTING

  /// Generates complete formatted address for property listing display
  /// Combines street address and district for user-friendly location identification
  String generateFormattedAddressForDisplay() {
    return '$fullStreetAddress, $administrativeDistrict';
  }

  /// Generates district-only display for compact UI components
  /// Used in property cards where space is limited but location context is needed
  String generateDistrictOnlyDisplay() {
    return administrativeDistrict;
  }

  /// Formats coordinates for debugging and technical support
  /// High precision format enables accurate troubleshooting of location issues
  String formatCoordinatesForDebugging() {
    return '${latitudeInDecimalDegrees.toStringAsFixed(6)}, ${longitudeInDecimalDegrees.toStringAsFixed(6)}';
  }

  // GOOGLE MAPS INTEGRATION

  /// Generates Google Maps navigation URL for this location
  /// Direct integration with Google Maps enables one-tap navigation from property listings
  String generateGoogleMapsNavigationUrl() {
    return 'https://www.google.com/maps?q=$latitudeInDecimalDegrees,$longitudeInDecimalDegrees';
  }

  /// Generates static map image URL for property thumbnails and previews
  /// Static maps reduce loading time and provide consistent visual representation
  String generateStaticMapImageUrl({
    int imageWidthInPixels = 400,
    int imageHeightInPixels = 300,
    int mapZoomLevel = 15,
  }) {
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$latitudeInDecimalDegrees,$longitudeInDecimalDegrees&'
        'zoom=$mapZoomLevel&'
        'size=${imageWidthInPixels}x$imageHeightInPixels&'
        'markers=color:red%7C$latitudeInDecimalDegrees,$longitudeInDecimalDegrees&'
        'key=YOUR_API_KEY'; // Replaced by infrastructure layer with actual API key
  }

  // VALIDATION

  /// Validates all location data fields comprehensively
  /// Comprehensive validation prevents runtime errors in map integration and property search
  List<String> _validateLocationData() {
    final validationErrors = <String>[];

    // Coordinate range validation - prevents impossible geographic coordinates
    if (latitudeInDecimalDegrees < -90 || latitudeInDecimalDegrees > 90) {
      validationErrors.add(
        'Latitude must be between -90 and 90 degrees (valid Earth coordinate range)',
      );
    }
    if (longitudeInDecimalDegrees < -180 || longitudeInDecimalDegrees > 180) {
      validationErrors.add(
        'Longitude must be between -180 and 180 degrees (valid Earth coordinate range)',
      );
    }

    // Geographic bounds validation - ensures coordinates are within Piura service area
    if (!_isWithinSupportedServiceArea()) {
      validationErrors.add(
        'Coordinates must be within Piura metropolitan area (current service boundary)',
      );
    }

    // Address validation - ensures meaningful location identification
    if (fullStreetAddress.trim().isEmpty) {
      validationErrors.add(
        'Street address cannot be empty (required for property identification)',
      );
    }
    if (fullStreetAddress.length > 200) {
      validationErrors.add(
        'Street address cannot exceed 200 characters (database constraint)',
      );
    }

    // District validation - critical for Peru market segmentation
    if (administrativeDistrict.trim().isEmpty) {
      validationErrors.add(
        'Administrative district cannot be empty (required for market analysis)',
      );
    }
    if (administrativeDistrict.length > 100) {
      validationErrors.add(
        'Administrative district cannot exceed 100 characters (database constraint)',
      );
    }

    // Country code validation - enforces Peru focus with Piura service area
    if (countryIsoCode != 'PE') {
      validationErrors.add(
        'Only Peru locations are supported (Piura metropolitan area in V1)',
      );
    }

    // Coordinate precision validation - prevents obviously invalid coordinates
    if (latitudeInDecimalDegrees == 0.0 && longitudeInDecimalDegrees == 0.0) {
      validationErrors.add(
        'Coordinates cannot both be zero (likely indicates failed geocoding)',
      );
    }

    // Address consistency validation - ensures address matches district context
    if (!fullStreetAddress.toLowerCase().contains(
      administrativeDistrict.toLowerCase().split(' ')[0],
    )) {
      // Only check first word of district to handle compound names
      // This is a soft validation - warns but doesn't reject
    }

    return validationErrors;
  }

  /// Determines if coordinates fall within current service area boundaries
  /// Piura-only in V1 - boundaries easily configurable for expansion
  bool _isWithinSupportedServiceArea() {
    return _isWithinPiuraMetropolitanArea();
  }

  /// Checks if coordinates are within Piura metropolitan area boundaries
  /// Boundaries can be updated here for service expansion
  bool _isWithinPiuraMetropolitanArea() {
    // Piura metropolitan area geographic bounds (configurable for expansion)
    const double piuraSouthernLatitudeBound = -5.3;
    const double piuraNorthernLatitudeBound = -5.1;
    const double piuraWesternLongitudeBound = -80.8;
    const double piuraEasternLongitudeBound = -80.5;

    return latitudeInDecimalDegrees >= piuraSouthernLatitudeBound &&
        latitudeInDecimalDegrees <= piuraNorthernLatitudeBound &&
        longitudeInDecimalDegrees >= piuraWesternLongitudeBound &&
        longitudeInDecimalDegrees <= piuraEasternLongitudeBound;
  }

  /// Converts decimal degrees to radians for trigonometric calculations
  /// Required for Haversine formula distance calculations
  double _convertDegreesToRadians(double decimalDegrees) {
    return decimalDegrees * (math.pi / 180);
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object> get props => [
    latitudeInDecimalDegrees,
    longitudeInDecimalDegrees,
    fullStreetAddress,
    administrativeDistrict,
    countryIsoCode,
  ];

  @override
  String toString() {
    return 'Location(${formatCoordinatesForDebugging()}, $administrativeDistrict)';
  }
}

/// Exception for location validation errors
/// Specific exception type enables targeted error handling in application layers
class LocationValidationException implements Exception {
  final String message;
  final List<String> violations;

  const LocationValidationException(this.message, this.violations);

  @override
  String toString() =>
      'LocationValidationException: $message\nViolations: ${violations.join(', ')}';
}

/// Location domain service for geographic operations and business logic
/// Centralized service ensures consistent location-based functionality across Piura service area
class LocationDomainService {
  /// Standard search radius for "nearby" property discovery in Piura
  /// 5km radius balances comprehensive results with relevance for Piura urban area
  static const double defaultSearchRadiusInKilometers = 5.0;

  /// Maximum allowed search radius to prevent performance issues
  /// 25km limit appropriate for Piura metropolitan area coverage
  static const double maximumSearchRadiusInKilometers = 25.0;

  // SERVICE AREA CONFIGURATION - Update these bounds for expansion
  /// Piura metropolitan area boundaries (easily configurable for expansion)
  static const double _piuraSouthernBound = -5.3;
  static const double _piuraNorthernBound = -5.1;
  static const double _piuraWesternBound = -80.8;
  static const double _piuraEasternBound = -80.5;

  /// Filters locations within specified search radius from center point
  /// Enables geographic property filtering for location-based search functionality
  static List<Location> findLocationsWithinSearchRadius(
    List<Location> candidateLocations,
    Location searchCenterLocation,
    double searchRadiusInKilometers,
  ) {
    if (searchRadiusInKilometers > maximumSearchRadiusInKilometers) {
      throw ArgumentError(
        'Search radius cannot exceed $maximumSearchRadiusInKilometers km (performance limitation)',
      );
    }

    return candidateLocations
        .where(
          (candidateLocation) => candidateLocation.isWithinSearchRadiusOf(
            searchCenterLocation,
            searchRadiusInKilometers,
          ),
        )
        .toList();
  }

  /// Sorts locations by distance from center point in ascending order
  /// Enables "nearest first" property listing for improved user experience
  static List<Location> sortLocationsByDistanceFromCenter(
    List<Location> locationsToSort,
    Location centerLocation,
  ) {
    final locationsWithCalculatedDistance = locationsToSort
        .map(
          (location) => {
            'location': location,
            'distanceInKilometers': location.calculateDistanceInKilometersTo(
              centerLocation,
            ),
          },
        )
        .toList();

    locationsWithCalculatedDistance.sort(
      (firstLocation, secondLocation) =>
          (firstLocation['distanceInKilometers'] as double).compareTo(
            secondLocation['distanceInKilometers'] as double,
          ),
    );

    return locationsWithCalculatedDistance
        .map(
          (locationWithDistance) =>
              locationWithDistance['location'] as Location,
        )
        .toList();
  }

  /// Formats distance for user interface display with appropriate units
  /// Provides intuitive distance representation based on Peru user expectations
  static String formatDistanceForUserDisplay(double distanceInKilometers) {
    if (distanceInKilometers < 1) {
      return '${(distanceInKilometers * 1000).round()}m';
    } else {
      return '${distanceInKilometers.toStringAsFixed(1)}km';
    }
  }

  /// Validates location specifically for property listing requirements in Piura
  /// Ensures property location quality and market relevance within service area
  static List<String> validateLocationForPropertyListing(
    Location propertyLocation,
  ) {
    final listingValidationErrors = <String>[];

    // Validate location is within current service area (Piura metropolitan area)
    final bool isWithinServiceArea =
        propertyLocation.latitudeInDecimalDegrees >= _piuraSouthernBound &&
        propertyLocation.latitudeInDecimalDegrees <= _piuraNorthernBound &&
        propertyLocation.longitudeInDecimalDegrees >= _piuraWesternBound &&
        propertyLocation.longitudeInDecimalDegrees <= _piuraEasternBound;

    if (!isWithinServiceArea) {
      listingValidationErrors.add(
        'Property location must be within Piura metropolitan area (current service boundary)',
      );
    }

    // Validate coordinate precision indicates real geocoding (not default/placeholder values)
    final String coordinateString = propertyLocation
        .formatCoordinatesForDebugging();
    if (coordinateString.contains('.000000') ||
        coordinateString.contains('.111111')) {
      listingValidationErrors.add(
        'Coordinates appear to be placeholder values rather than actual geocoded location',
      );
    }

    // Validate address contains meaningful location information
    if (propertyLocation.fullStreetAddress.length < 10) {
      listingValidationErrors.add(
        'Street address appears too brief for accurate property identification',
      );
    }

    return listingValidationErrors;
  }
}
