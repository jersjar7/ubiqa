// lib/services/1_infrastructure/google_maps/geocoding_service.dart

import '../../../models/1_domain/shared/value_objects/location.dart';
import '../../0_config/shared/google_maps_config.dart';
import '../shared/http_client.dart';
import '../shared/service_result.dart';

/// Google Maps Geocoding Service for Ubiqa Location Validation
///
/// WHY this service exists:
/// Peru's real estate requires precise location validation because property
/// ownership documents must contain exact addresses and coordinates.
/// Invalid locations can cause legal issues and property discovery failures.
class GeocodingService {
  final GoogleMapsHttpClient _httpClient;

  GeocodingService({GoogleMapsHttpClient? httpClient})
    : _httpClient = httpClient ?? GoogleMapsHttpClient();

  /// Converts address to GPS coordinates with Piura bounds validation
  /// WHY: Property listings need accurate coordinates for map display and distance search
  Future<ServiceResult<Location>> geocodeAddress(String address) async {
    try {
      if (address.trim().isEmpty) {
        return ServiceResult.failure(
          'Address cannot be empty',
          ServiceException('Empty address', ServiceErrorType.validation),
        );
      }

      final url = GoogleMapsConfig.getGeocodingUrl(address);
      final result = await _httpClient.getGoogleMapsApi(url: url);

      if (!result.isSuccess) {
        return ServiceResult.failure(result.errorMessage!, result.exception);
      }

      final responseData = result.data!;
      final results = responseData['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        return ServiceResult.failure(
          'Address not found in Piura area',
          ServiceException('No geocoding results', ServiceErrorType.validation),
        );
      }

      // Use first result (most relevant)
      final firstResult = results[0] as Map<String, dynamic>;
      final location = _parseGeocodingResult(firstResult);

      if (!location.isSuccess) {
        return location;
      }

      // WHY: Validate coordinates are within Piura service area
      if (!_isWithinPiuraBounds(location.data!)) {
        return ServiceResult.failure(
          'Address is outside Piura service area',
          ServiceException(
            'Location outside bounds',
            ServiceErrorType.business,
          ),
        );
      }

      return location;
    } catch (e) {
      return ServiceResult.failure(
        'Geocoding request failed',
        ServiceException('Geocoding error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Converts GPS coordinates to address (reverse geocoding)
  /// WHY: When users select location on map, we need human-readable address
  Future<ServiceResult<Location>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // WHY: Validate coordinates are reasonable values before API call
      if (!_areValidCoordinates(latitude, longitude)) {
        return ServiceResult.failure(
          'Invalid GPS coordinates',
          ServiceException('Invalid coordinates', ServiceErrorType.validation),
        );
      }

      final url =
          '${GoogleMapsConfig.geocodingUrl}/json?'
          'latlng=$latitude,$longitude&'
          'result_type=street_address|route|subpremise&'
          'key=${GoogleMapsConfig.apiKey}';

      final result = await _httpClient.getGoogleMapsApi(url: url);

      if (!result.isSuccess) {
        return ServiceResult.failure(result.errorMessage!, result.exception);
      }

      final responseData = result.data!;
      final results = responseData['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        return ServiceResult.failure(
          'No address found for these coordinates',
          ServiceException(
            'No reverse geocoding results',
            ServiceErrorType.validation,
          ),
        );
      }

      // WHY: Use most specific address result (street_address preferred)
      final firstResult = results[0] as Map<String, dynamic>;
      return _parseGeocodingResult(firstResult);
    } catch (e) {
      return ServiceResult.failure(
        'Reverse geocoding request failed',
        ServiceException(
          'Reverse geocoding error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  /// Validates if address exists and returns detailed location info
  /// WHY: Before creating property listing, confirm address is real and precise
  Future<ServiceResult<LocationValidationResult>> validateAddressForProperty(
    String address,
  ) async {
    final geocodingResult = await geocodeAddress(address);

    if (!geocodingResult.isSuccess) {
      return ServiceResult.failure(
        geocodingResult.errorMessage!,
        geocodingResult.exception,
      );
    }

    final location = geocodingResult.data!;

    // WHY: Use domain service for business rule validation
    final domainViolations =
        LocationDomainService.validateLocationForPropertyListing(location);

    final validationResult = LocationValidationResult(
      location: location,
      isValid: domainViolations.isEmpty,
      validationErrors: domainViolations,
    );

    return ServiceResult.success(validationResult);
  }

  // PRIVATE HELPER METHODS

  /// Parses Google Geocoding API result into domain Location object
  ServiceResult<Location> _parseGeocodingResult(Map<String, dynamic> result) {
    try {
      final geometry = result['geometry'] as Map<String, dynamic>;
      final locationData = geometry['location'] as Map<String, dynamic>;

      final lat = (locationData['lat'] as num).toDouble();
      final lng = (locationData['lng'] as num).toDouble();

      final formattedAddress = result['formatted_address'] as String;

      // WHY: Extract district from address components for market segmentation
      final addressComponents = result['address_components'] as List<dynamic>;
      final district = _extractDistrictFromComponents(addressComponents);

      // WHY: Use domain factory specifically designed for Google Places API
      final location = Location.createFromGooglePlacesApiResponse(
        latitudeInDecimalDegrees: lat,
        longitudeInDecimalDegrees: lng,
        formattedAddressFromApi: formattedAddress,
        districtFromApi: district,
      );

      return ServiceResult.success(location);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to parse location data',
        ServiceException(
          'Geocoding parsing error',
          ServiceErrorType.validation,
          e,
        ),
      );
    }
  }

  /// Extracts district name from Google address components
  /// WHY: District is critical for Peru real estate market analysis
  String _extractDistrictFromComponents(List<dynamic> components) {
    for (final component in components) {
      final types = component['types'] as List<dynamic>;

      // WHY: Look for administrative_area_level_2 (district level in Peru)
      if (types.contains('administrative_area_level_2') ||
          types.contains('sublocality') ||
          types.contains('locality')) {
        return component['long_name'] as String;
      }
    }

    return 'Piura'; // Default to Piura if no district found
  }

  /// Validates coordinates are within Piura metropolitan bounds
  bool _isWithinPiuraBounds(Location location) {
    return GoogleMapsConfig.isWithinPiuraBounds(
      location.latitudeInDecimalDegrees,
      location.longitudeInDecimalDegrees,
    );
  }

  /// Basic coordinate validation
  bool _areValidCoordinates(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Cleanup resources
  void dispose() {
    _httpClient.dispose();
  }
}

/// Result container for address validation operations
class LocationValidationResult {
  final Location location;
  final bool isValid;
  final List<String> validationErrors;

  const LocationValidationResult({
    required this.location,
    required this.isValid,
    required this.validationErrors,
  });

  /// WHY: UI can show user-friendly validation feedback
  String get validationSummary {
    if (isValid) return 'Address validated successfully';
    return 'Validation failed: ${validationErrors.first}';
  }

  @override
  String toString() {
    return 'LocationValidationResult(isValid: $isValid, errors: ${validationErrors.length})';
  }
}
