// lib/services/1_infrastructure/google_maps/places_service.dart

import '../../../models/1_domain/shared/value_objects/location.dart';
import '../../0_config/shared/google_maps_config.dart';
import '../shared/http_client.dart';
import '../shared/service_result.dart';

/// Google Places Service for Ubiqa Address Search & Autocomplete
///
/// WHY this service exists:
/// Peru users type incomplete addresses like "cerca del mercado". This service
/// provides address suggestions and validates locations exist before property
/// creation, preventing invalid listings.
class PlacesService {
  final GoogleMapsHttpClient _httpClient;

  PlacesService({GoogleMapsHttpClient? httpClient})
    : _httpClient = httpClient ?? GoogleMapsHttpClient();

  /// Searches places by text query with autocomplete suggestions
  /// WHY: Provides address suggestions as users type during property creation
  Future<ServiceResult<List<PlaceSearchResult>>> searchPlaces(
    String query, {
    int maxResults = 5,
  }) async {
    try {
      if (query.trim().length < 2) {
        return ServiceResult.failure(
          'Search query too short',
          ServiceException('Minimum 2 characters', ServiceErrorType.validation),
        );
      }

      final url = GoogleMapsConfig.getPlacesSearchUrl(
        query: query,
        lat: GoogleMapsConfig.defaultCenterLat,
        lng: GoogleMapsConfig.defaultCenterLng,
        radiusKm: GoogleMapsConfig.defaultSearchRadiusKm,
      );

      final result = await _httpClient.getGoogleMapsApi(url: url);

      if (!result.isSuccess) {
        return ServiceResult.failure(result.errorMessage!, result.exception);
      }

      final responseData = result.data!;
      final results = responseData['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        return ServiceResult.success([]); // Empty results are valid
      }

      final places = <PlaceSearchResult>[];
      for (final result in results.take(maxResults)) {
        final place = _parsePlaceSearchResult(result as Map<String, dynamic>);
        if (place != null) {
          places.add(place);
        }
      }

      return ServiceResult.success(places);
    } catch (e) {
      return ServiceResult.failure(
        'Places search failed',
        ServiceException('Search error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Gets detailed place information and converts to Location object
  /// WHY: Converts place selection to validated Location for property creation
  Future<ServiceResult<Location>> getPlaceDetails(String placeId) async {
    try {
      final url = GoogleMapsConfig.getPlaceDetailsUrl(placeId);
      final result = await _httpClient.getGoogleMapsApi(url: url);

      if (!result.isSuccess) {
        return ServiceResult.failure(result.errorMessage!, result.exception);
      }

      final responseData = result.data!;
      final placeResult = responseData['result'] as Map<String, dynamic>?;

      if (placeResult == null) {
        return ServiceResult.failure(
          'Place details not found',
          ServiceException('No place result', ServiceErrorType.validation),
        );
      }

      final location = _parsePlaceDetailsToLocation(placeResult);

      if (!location.isSuccess) {
        return location;
      }

      // WHY: Validate location is within Piura service area
      if (!_isWithinPiuraBounds(location.data!)) {
        return ServiceResult.failure(
          'Selected place is outside Piura service area',
          ServiceException(
            'Location outside bounds',
            ServiceErrorType.business,
          ),
        );
      }

      return location;
    } catch (e) {
      return ServiceResult.failure(
        'Place details request failed',
        ServiceException('Details error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Searches for places near a specific location
  /// WHY: Finds nearby landmarks for property context ("cerca al Banco de la Nación")
  Future<ServiceResult<List<PlaceSearchResult>>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 2.0,
    String? placeType,
  }) async {
    try {
      var url =
          '${GoogleMapsConfig.placesApiUrl}/nearbysearch/json?'
          'location=$latitude,$longitude&'
          'radius=${(radiusKm * 1000).toInt()}&'
          'key=${GoogleMapsConfig.googleMapsApiKey}';

      if (placeType != null) {
        url += '&type=$placeType';
      }

      final result = await _httpClient.getGoogleMapsApi(url: url);

      if (!result.isSuccess) {
        return ServiceResult.failure(result.errorMessage!, result.exception);
      }

      final responseData = result.data!;
      final results = responseData['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        return ServiceResult.success([]);
      }

      final places = <PlaceSearchResult>[];
      for (final result in results.take(10)) {
        final place = _parsePlaceSearchResult(result as Map<String, dynamic>);
        if (place != null) {
          places.add(place);
        }
      }

      return ServiceResult.success(places);
    } catch (e) {
      return ServiceResult.failure(
        'Nearby search failed',
        ServiceException('Nearby search error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Combined search and details - returns Location directly
  /// WHY: Convenience method for simple address selection flows
  Future<ServiceResult<Location>> searchAndGetLocation(String query) async {
    final searchResult = await searchPlaces(query, maxResults: 1);

    if (!searchResult.isSuccess || searchResult.data!.isEmpty) {
      return ServiceResult.failure(
        'No places found for "$query"',
        ServiceException('No search results', ServiceErrorType.validation),
      );
    }

    final firstPlace = searchResult.data!.first;
    return getPlaceDetails(firstPlace.placeId);
  }

  // PRIVATE HELPER METHODS

  /// Parses Google Places search result
  PlaceSearchResult? _parsePlaceSearchResult(Map<String, dynamic> result) {
    try {
      final placeId = result['place_id'] as String?;
      final name = result['name'] as String?;
      final formattedAddress = result['formatted_address'] as String?;

      if (placeId == null || name == null) {
        return null;
      }

      return PlaceSearchResult(
        placeId: placeId,
        name: name,
        formattedAddress: formattedAddress ?? '',
      );
    } catch (e) {
      return null; // Skip invalid results
    }
  }

  /// Parses Google Place Details to Location object
  ServiceResult<Location> _parsePlaceDetailsToLocation(
    Map<String, dynamic> result,
  ) {
    try {
      final geometry = result['geometry'] as Map<String, dynamic>;
      final locationData = geometry['location'] as Map<String, dynamic>;

      final lat = (locationData['lat'] as num).toDouble();
      final lng = (locationData['lng'] as num).toDouble();

      final formattedAddress = result['formatted_address'] as String;

      // WHY: Extract district from address components for market segmentation
      final addressComponents = result['address_components'] as List<dynamic>?;
      final district = _extractDistrictFromComponents(addressComponents ?? []);

      final location = Location.createFromGooglePlacesApiResponse(
        latitudeInDecimalDegrees: lat,
        longitudeInDecimalDegrees: lng,
        formattedAddressFromApi: formattedAddress,
        districtFromApi: district,
      );

      return ServiceResult.success(location);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to parse place details',
        ServiceException('Parsing error', ServiceErrorType.validation, e),
      );
    }
  }

  /// Extracts district from address components
  String _extractDistrictFromComponents(List<dynamic> components) {
    for (final component in components) {
      final types = component['types'] as List<dynamic>;

      if (types.contains('administrative_area_level_2') ||
          types.contains('sublocality') ||
          types.contains('locality')) {
        return component['long_name'] as String;
      }
    }

    return 'Piura'; // Default fallback
  }

  /// Validates location is within Piura bounds
  bool _isWithinPiuraBounds(Location location) {
    return GoogleMapsConfig.isWithinPiuraBounds(
      location.latitudeInDecimalDegrees,
      location.longitudeInDecimalDegrees,
    );
  }

  /// Cleanup resources
  void dispose() {
    _httpClient.dispose();
  }
}

/// Search result from Google Places API
class PlaceSearchResult {
  final String placeId;
  final String name;
  final String formattedAddress;

  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
  });

  /// WHY: UI displays suggestion with name and address
  String get displayText {
    if (formattedAddress.isEmpty) return name;
    return '$name - $formattedAddress';
  }

  @override
  String toString() => 'PlaceSearchResult($name, $placeId)';
}
