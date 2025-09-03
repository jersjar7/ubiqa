// lib/services/1_infrastructure/shared/http_client.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'service_result.dart';

/// HTTP client for external API communication
///
/// WHY this service exists:
/// Peru's mobile networks can be unreliable. This client provides consistent
/// error handling, retry logic, and timeout management for Google Maps APIs
/// and other external services critical to property location accuracy.
class HttpClient {
  final http.Client _client;
  final Duration _defaultTimeout;

  HttpClient({http.Client? client, Duration? defaultTimeout})
    : _client = client ?? http.Client(),
      _defaultTimeout = defaultTimeout ?? const Duration(seconds: 10);

  /// Performs GET request with comprehensive error handling
  /// Returns parsed JSON response wrapped in ServiceResult
  Future<ServiceResult<Map<String, dynamic>>> getJson({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders(headers))
          .timeout(timeout ?? _defaultTimeout);

      return _handleJsonResponse(response, url);
    } on SocketException {
      return ServiceResult.failure(
        'No internet connection available',
        ServiceException(
          'Network connectivity failed',
          ServiceErrorType.network,
        ),
      );
    } on HttpException catch (e) {
      return ServiceResult.failure(
        'Network request failed',
        ServiceException(
          'HTTP error: ${e.message}',
          ServiceErrorType.network,
          e,
        ),
      );
    } on FormatException catch (e) {
      return ServiceResult.failure(
        'Invalid response format from server',
        ServiceException(
          'JSON parsing failed: ${e.message}',
          ServiceErrorType.validation,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Request failed unexpectedly',
        ServiceException('Unknown HTTP error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Performs POST request with JSON payload
  /// Used for APIs requiring data submission
  Future<ServiceResult<Map<String, dynamic>>> postJson({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _buildHeaders(headers, includeJson: true),
            body: json.encode(body),
          )
          .timeout(timeout ?? _defaultTimeout);

      return _handleJsonResponse(response, url);
    } on SocketException {
      return ServiceResult.failure(
        'No internet connection available',
        ServiceException(
          'Network connectivity failed',
          ServiceErrorType.network,
        ),
      );
    } on HttpException catch (e) {
      return ServiceResult.failure(
        'Network request failed',
        ServiceException(
          'HTTP error: ${e.message}',
          ServiceErrorType.network,
          e,
        ),
      );
    } on FormatException catch (e) {
      return ServiceResult.failure(
        'Invalid response format from server',
        ServiceException(
          'JSON parsing failed: ${e.message}',
          ServiceErrorType.validation,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Request failed unexpectedly',
        ServiceException('Unknown HTTP error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Downloads binary data (for future use with images/documents)
  Future<ServiceResult<List<int>>> downloadBytes({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders(headers))
          .timeout(timeout ?? _defaultTimeout);

      if (response.statusCode == 200) {
        return ServiceResult.success(response.bodyBytes);
      } else {
        return ServiceResult.failure(
          'Download failed with status ${response.statusCode}',
          ServiceException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            _getErrorTypeFromStatusCode(response.statusCode),
          ),
        );
      }
    } on SocketException {
      return ServiceResult.failure(
        'No internet connection available',
        ServiceException(
          'Network connectivity failed',
          ServiceErrorType.network,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Download failed unexpectedly',
        ServiceException('Unknown download error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Performs request with retry logic for flaky connections
  /// WHY: Peru mobile networks can be unstable, retries improve reliability
  Future<ServiceResult<Map<String, dynamic>>> getJsonWithRetry({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    ServiceResult<Map<String, dynamic>>? lastResult;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      lastResult = await getJson(url: url, headers: headers, timeout: timeout);

      if (lastResult.isSuccess) {
        return lastResult;
      }

      // Don't retry for certain error types
      if (lastResult.exception?.type == ServiceErrorType.authentication ||
          lastResult.exception?.type == ServiceErrorType.validation) {
        break;
      }

      // Wait before retry (except on last attempt)
      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }

    return lastResult!;
  }

  /// Cancels all pending requests and cleans up resources
  void dispose() {
    _client.close();
  }

  // PRIVATE HELPER METHODS

  /// Builds HTTP headers with consistent defaults
  Map<String, String> _buildHeaders(
    Map<String, String>? customHeaders, {
    bool includeJson = false,
  }) {
    final headers = <String, String>{
      'User-Agent': 'Ubiqa/1.0 (Peru Real Estate App)',
      ...?customHeaders,
    };

    if (includeJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }

    return headers;
  }

  /// Handles HTTP response and converts to ServiceResult
  ServiceResult<Map<String, dynamic>> _handleJsonResponse(
    http.Response response,
    String url,
  ) {
    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ServiceResult.success(jsonData);
      } catch (e) {
        return ServiceResult.failure(
          'Invalid JSON response from server',
          ServiceException(
            'JSON parsing failed: ${e.toString()}',
            ServiceErrorType.validation,
            e,
          ),
        );
      }
    } else {
      return ServiceResult.failure(
        _getErrorMessageFromStatusCode(response.statusCode),
        ServiceException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          _getErrorTypeFromStatusCode(response.statusCode),
        ),
      );
    }
  }

  /// Maps HTTP status codes to appropriate error types
  ServiceErrorType _getErrorTypeFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return ServiceErrorType.validation;
      case 401:
      case 403:
        return ServiceErrorType.authentication;
      case 404:
        return ServiceErrorType.validation;
      case 429:
        return ServiceErrorType.serviceUnavailable;
      case 500:
      case 502:
      case 503:
      case 504:
        return ServiceErrorType.serviceUnavailable;
      default:
        return ServiceErrorType.unknown;
    }
  }

  /// Gets user-friendly error message from HTTP status code
  String _getErrorMessageFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request parameters';
      case 401:
        return 'Authentication required';
      case 403:
        return 'Access denied';
      case 404:
        return 'Requested resource not found';
      case 429:
        return 'Too many requests. Please try again later';
      case 500:
        return 'Server error. Please try again';
      case 502:
        return 'Service temporarily unavailable';
      case 503:
        return 'Service unavailable. Please try again later';
      case 504:
        return 'Request timeout. Please try again';
      default:
        return 'Request failed with status code $statusCode';
    }
  }
}

/// HTTP client specifically configured for Google Maps APIs
/// Includes Google-specific error handling and configuration
class GoogleMapsHttpClient extends HttpClient {
  GoogleMapsHttpClient({Duration? timeout})
    : super(defaultTimeout: timeout ?? const Duration(seconds: 15));

  /// Performs Google Maps API request with enhanced error handling
  Future<ServiceResult<Map<String, dynamic>>> getGoogleMapsApi({
    required String url,
    Map<String, String>? additionalHeaders,
    Duration? timeout,
  }) async {
    final result = await getJsonWithRetry(
      url: url,
      headers: _buildGoogleMapsHeaders(additionalHeaders),
      timeout: timeout,
      maxRetries: 2, // Conservative retry for paid API
    );

    if (result.isSuccess) {
      return _handleGoogleMapsResponse(result.data!);
    }

    return result;
  }

  /// Builds headers optimized for Google Maps APIs
  Map<String, String> _buildGoogleMapsHeaders(
    Map<String, String>? customHeaders,
  ) {
    return {
      'Accept': 'application/json',
      'Accept-Language': 'es-PE,es;q=0.9,en;q=0.8', // Peru market preference
      ...?customHeaders,
    };
  }

  /// Handles Google Maps API specific responses and error codes
  ServiceResult<Map<String, dynamic>> _handleGoogleMapsResponse(
    Map<String, dynamic> responseData,
  ) {
    final status = responseData['status'] as String?;

    // Google Maps API returns 200 but includes status field for API errors
    switch (status) {
      case 'OK':
        return ServiceResult.success(responseData);
      case 'ZERO_RESULTS':
        return ServiceResult.failure(
          'No results found for this location',
          ServiceException(
            'Google Maps API returned no results',
            ServiceErrorType.validation,
          ),
        );
      case 'OVER_DAILY_LIMIT':
      case 'OVER_QUERY_LIMIT':
        return ServiceResult.failure(
          'Service temporarily unavailable',
          ServiceException(
            'Google Maps API quota exceeded',
            ServiceErrorType.serviceUnavailable,
          ),
        );
      case 'REQUEST_DENIED':
        return ServiceResult.failure(
          'Location service access denied',
          ServiceException(
            'Google Maps API request denied',
            ServiceErrorType.authentication,
          ),
        );
      case 'INVALID_REQUEST':
        return ServiceResult.failure(
          'Invalid location request',
          ServiceException(
            'Google Maps API invalid request',
            ServiceErrorType.validation,
          ),
        );
      default:
        return ServiceResult.failure(
          'Location service error',
          ServiceException(
            'Google Maps API error: $status',
            ServiceErrorType.unknown,
          ),
        );
    }
  }
}
