// services/0_config/shared/google_maps_config.dart

import 'secrets.dart';

/// Google Maps configuration for Ubiqa location services
class GoogleMapsConfig {
  /// Google Maps API key for all services
  static final String googleMapsApiKey = Secrets.googleMapsApiKey;

  /// Base URLs for Google Maps services
  static const String placesApiUrl =
      'https://maps.googleapis.com/maps/api/place';
  static const String staticMapsUrl =
      'https://maps.googleapis.com/maps/api/staticmap';
  static const String geocodingUrl =
      'https://maps.googleapis.com/maps/api/geocode';

  /// Piura, Peru geographic bounds for search restrictions
  static const double piuraMinLat = -5.3;
  static const double piuraMaxLat = -5.1;
  static const double piuraMinLng = -80.8;
  static const double piuraMaxLng = -80.5;

  /// Default map center (Piura city center)
  static const double defaultCenterLat = -5.1945;
  static const double defaultCenterLng = -80.6328;

  /// Default search radius in kilometers
  static const double defaultSearchRadiusKm = 25.0;

  /// Static map default settings
  static const int defaultMapWidth = 400;
  static const int defaultMapHeight = 300;
  static const int defaultMapZoom = 15;

  /// Check if coordinates are within Piura bounds
  static bool isWithinPiuraBounds(double lat, double lng) {
    return lat >= piuraMinLat &&
        lat <= piuraMaxLat &&
        lng >= piuraMinLng &&
        lng <= piuraMaxLng;
  }

  /// Generate Google Maps URL for navigation
  static String getNavigationUrl(double lat, double lng) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
  }

  /// Generate static map URL for property images
  static String getStaticMapUrl({
    required double lat,
    required double lng,
    int width = defaultMapWidth,
    int height = defaultMapHeight,
    int zoom = defaultMapZoom,
  }) {
    return '$staticMapsUrl?'
        'center=$lat,$lng&'
        'zoom=$zoom&'
        'size=${width}x$height&'
        'markers=color:red%7C$lat,$lng&'
        'key=$googleMapsApiKey';
  }

  /// Generate Places API search URL
  static String getPlacesSearchUrl({
    required String query,
    double? lat,
    double? lng,
    double radiusKm = defaultSearchRadiusKm,
  }) {
    var url =
        '$placesApiUrl/textsearch/json?'
        'query=${Uri.encodeComponent(query)}&'
        'key=$googleMapsApiKey';

    if (lat != null && lng != null) {
      final radiusMeters = (radiusKm * 1000).toInt();
      url += '&location=$lat,$lng&radius=$radiusMeters';
    }

    return url;
  }

  /// Generate Places API details URL
  static String getPlaceDetailsUrl(String placeId) {
    return '$placesApiUrl/details/json?'
        'place_id=$placeId&'
        'fields=name,formatted_address,geometry,address_components&'
        'key=$googleMapsApiKey';
  }

  /// Generate Geocoding API URL
  static String getGeocodingUrl(String address) {
    return '$geocodingUrl/json?'
        'address=${Uri.encodeComponent(address)}&'
        'bounds=$piuraMinLat,$piuraMinLng%7C$piuraMaxLat,$piuraMaxLng&'
        'key=$googleMapsApiKey';
  }

  /// Validate API key format
  static bool isValidApiKey(String key) {
    return key.isNotEmpty && key.startsWith('AIza') && key.length == 39;
  }
}
