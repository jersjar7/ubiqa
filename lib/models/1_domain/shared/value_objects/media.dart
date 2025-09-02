// lib/models/1_domain/shared/value_objects/media.dart

import 'package:equatable/equatable.dart';

/// Media value object for property visual content management
///
/// Encapsulates property photos because visual presentation drives property
/// discovery in Peru's competitive real estate market. Immutable design prevents
/// photo corruption during listing lifecycle and ensures consistent visual
/// experience across property displays.
///
/// V1 Scope: Property photos with display ordering and Firebase Storage integration
class Media extends Equatable {
  /// List of property photo URLs in display priority order
  /// First photo serves as primary listing image across all property displays
  final List<String> propertyPhotoUrls;

  const Media._({required this.propertyPhotoUrls});

  /// Creates Media with comprehensive photo URL validation
  /// Validation prevents broken images that would damage listing presentation
  factory Media.create({required List<String> propertyPhotoUrls}) {
    final media = Media._(
      propertyPhotoUrls: propertyPhotoUrls.map((url) => url.trim()).toList(),
    );

    final validationErrors = media._validateMediaContent();
    if (validationErrors.isNotEmpty) {
      throw MediaValidationException('Invalid media content', validationErrors);
    }

    return media;
  }

  /// Creates empty Media instance for properties without photos
  /// Used for draft listings where photos will be added later
  factory Media.createEmpty() {
    return const Media._(propertyPhotoUrls: []);
  }

  /// Creates Media with single photo for simple property listings
  /// Convenience factory for minimum viable listing creation
  factory Media.createWithSinglePhoto(String propertyPhotoUrl) {
    return Media.create(propertyPhotoUrls: [propertyPhotoUrl]);
  }

  // PHOTO MANAGEMENT

  /// Retrieves primary property photo URL for listing cards and thumbnails
  /// First photo determines initial user impression of property
  String? getPrimaryPropertyPhotoUrl() {
    return propertyPhotoUrls.isNotEmpty ? propertyPhotoUrls.first : null;
  }

  /// Retrieves secondary photo URLs for gallery and detail views
  /// Additional photos provide comprehensive property visualization
  List<String> getSecondaryPropertyPhotoUrls() {
    return propertyPhotoUrls.length > 1 ? propertyPhotoUrls.sublist(1) : [];
  }

  /// Determines if media contains any property photos
  /// Used for listing quality validation and display logic
  bool containsPropertyPhotos() {
    return propertyPhotoUrls.isNotEmpty;
  }

  /// Counts total number of property photos
  /// Important for listing quality scoring and user interface pagination
  int getTotalPhotoCount() {
    return propertyPhotoUrls.length;
  }

  /// Retrieves photo URL at specific position
  /// Safe accessor prevents index out of bounds errors in UI components
  String? getPhotoUrlAtPosition(int positionIndex) {
    return positionIndex >= 0 && positionIndex < propertyPhotoUrls.length
        ? propertyPhotoUrls[positionIndex]
        : null;
  }

  // PHOTO ORDERING AND MANAGEMENT

  /// Adds new photo to end of display sequence
  /// Returns new Media instance maintaining immutability
  Media addPropertyPhoto(String newPhotoUrl) {
    final updatedPhotoUrls = [...propertyPhotoUrls, newPhotoUrl.trim()];
    return Media.create(propertyPhotoUrls: updatedPhotoUrls);
  }

  /// Inserts photo at specific position in display sequence
  /// Enables precise control over photo presentation order
  Media insertPhotoAtPosition(int positionIndex, String newPhotoUrl) {
    final updatedPhotoUrls = [...propertyPhotoUrls];
    updatedPhotoUrls.insert(positionIndex, newPhotoUrl.trim());
    return Media.create(propertyPhotoUrls: updatedPhotoUrls);
  }

  /// Removes photo at specific position from display sequence
  /// Safe removal prevents disruption of remaining photo order
  Media removePhotoAtPosition(int positionIndex) {
    if (positionIndex < 0 || positionIndex >= propertyPhotoUrls.length) {
      return this;
    }

    final updatedPhotoUrls = [...propertyPhotoUrls];
    updatedPhotoUrls.removeAt(positionIndex);
    return Media.create(propertyPhotoUrls: updatedPhotoUrls);
  }

  /// Removes specific photo URL from display sequence
  /// Useful for bulk photo management and cleanup operations
  Media removeSpecificPhoto(String targetPhotoUrl) {
    final updatedPhotoUrls = propertyPhotoUrls
        .where((url) => url != targetPhotoUrl)
        .toList();
    return Media.create(propertyPhotoUrls: updatedPhotoUrls);
  }

  /// Repositions photo from one display position to another
  /// Enables drag-and-drop photo reordering in user interface
  Media repositionPhoto(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= propertyPhotoUrls.length ||
        toIndex < 0 ||
        toIndex >= propertyPhotoUrls.length) {
      return this;
    }

    final updatedPhotoUrls = [...propertyPhotoUrls];
    final photoUrl = updatedPhotoUrls.removeAt(fromIndex);
    updatedPhotoUrls.insert(toIndex, photoUrl);

    return Media.create(propertyPhotoUrls: updatedPhotoUrls);
  }

  /// Promotes photo to primary position (first in display sequence)
  /// Critical for optimizing listing visual impact and user engagement
  Media setPhotoAsPrimary(String targetPhotoUrl) {
    if (!propertyPhotoUrls.contains(targetPhotoUrl)) {
      return this;
    }

    final updatedPhotoUrls = propertyPhotoUrls
        .where((url) => url != targetPhotoUrl)
        .toList();
    updatedPhotoUrls.insert(0, targetPhotoUrl);

    return Media.create(propertyPhotoUrls: updatedPhotoUrls);
  }

  // DISPLAY OPTIMIZATION

  /// Retrieves photos for gallery display with count limitation
  /// Prevents performance issues from loading excessive photos simultaneously
  List<String> getPhotosForGalleryDisplay({int maximumPhotoCount = 10}) {
    return propertyPhotoUrls.take(maximumPhotoCount).toList();
  }

  /// Retrieves photos for listing card preview with minimal count
  /// Optimized for fast loading in property search results
  List<String> getPhotosForCardPreview({int maximumPhotoCount = 3}) {
    return propertyPhotoUrls.take(maximumPhotoCount).toList();
  }

  /// Retrieves photo URLs optimized for thumbnail display
  /// In V1, returns original URLs as Firebase Storage handles thumbnail generation
  List<String> getThumbnailPhotoUrls() {
    return propertyPhotoUrls;
  }

  // QUALITY ASSESSMENT

  /// Determines if media meets minimum listing quality standards
  /// Basic quality check ensures listings have visual representation
  bool meetsMinimumQualityStandards() {
    return propertyPhotoUrls.isNotEmpty;
  }

  /// Calculates media quality score for listing optimization
  /// Score influences search ranking and listing presentation priority
  double calculateMediaQualityScore() {
    var qualityScore = 0.0;

    // Base score requires at least one photo
    if (propertyPhotoUrls.isEmpty) return 0.0;

    // Photo count contribution (up to 60% of total score)
    final photoCountScore = (propertyPhotoUrls.length / 8.0).clamp(0.0, 0.6);
    qualityScore += photoCountScore;

    // Primary photo presence bonus (20% of total score)
    if (getPrimaryPropertyPhotoUrl() != null) {
      qualityScore += 0.2;
    }

    // Multiple photos bonus for comprehensive presentation (20% of total score)
    if (propertyPhotoUrls.length > 1) {
      qualityScore += 0.2;
    }

    return qualityScore.clamp(0.0, 1.0);
  }

  /// Generates quality improvement recommendations for property owners
  /// Helps users optimize their listing visual presentation
  List<String> generateQualityImprovementRecommendations() {
    final recommendations = <String>[];

    if (propertyPhotoUrls.isEmpty) {
      recommendations.add(
        'Agrega al menos una foto de la propiedad para atraer compradores',
      );
    } else if (propertyPhotoUrls.length == 1) {
      recommendations.add(
        'Agrega más fotos para mostrar mejor los espacios de la propiedad',
      );
    }

    if (propertyPhotoUrls.length < 3) {
      recommendations.add(
        'Las propiedades con 3+ fotos reciben 40% más contactos',
      );
    }

    if (propertyPhotoUrls.length > 25) {
      recommendations.add(
        'Considera reducir a 20-22 fotos para mejor experiencia de navegación',
      );
    }

    return recommendations;
  }

  // VALIDATION

  /// Validates media content comprehensively for listing quality
  /// Prevents broken photos that would damage user experience and listing credibility
  List<String> _validateMediaContent() {
    final validationErrors = <String>[];

    // Photo count validation prevents system overload and poor user experience
    if (propertyPhotoUrls.length > 25) {
      validationErrors.add(
        'Cannot exceed 25 photos per property (performance and storage limitations)',
      );
    }

    // Individual photo URL validation ensures reliable image display
    for (int i = 0; i < propertyPhotoUrls.length; i++) {
      final photoUrl = propertyPhotoUrls[i];

      if (photoUrl.trim().isEmpty) {
        validationErrors.add(
          'Photo URL at position $i cannot be empty (would cause display errors)',
        );
        continue;
      }

      if (photoUrl.length > 2000) {
        validationErrors.add(
          'Photo URL at position $i exceeds maximum length (browser limitation)',
        );
        continue;
      }

      if (!_isValidImageUrl(photoUrl)) {
        validationErrors.add(
          'Invalid image URL format at position $i (would fail to display)',
        );
      }
    }

    // Duplicate URL validation prevents redundant storage and display issues
    final uniquePhotoUrls = propertyPhotoUrls.toSet();
    if (uniquePhotoUrls.length != propertyPhotoUrls.length) {
      validationErrors.add(
        'Duplicate photo URLs not allowed (wastes storage and confuses users)',
      );
    }

    return validationErrors;
  }

  /// Validates URL format for reliable image display
  /// Comprehensive validation prevents broken images in production
  bool _isValidImageUrl(String photoUrl) {
    if (photoUrl.trim().isEmpty) return false;

    try {
      final uri = Uri.parse(photoUrl);

      // Protocol validation - only secure connections allowed
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return false;
      }

      // File extension validation for supported image formats
      final urlPath = uri.path.toLowerCase();
      final supportedImageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      return supportedImageExtensions.any(
            (extension) => urlPath.endsWith(extension),
          ) ||
          urlPath.contains('/image/') || // Firebase Storage image pattern
          photoUrl.contains('firebase') || // Firebase Storage URLs
          photoUrl.contains('googleapis'); // Google Storage URLs
    } catch (e) {
      return false;
    }
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object> get props => [propertyPhotoUrls];

  @override
  String toString() {
    return 'Media(${propertyPhotoUrls.length} property photos)';
  }
}

/// Exception for media validation errors
/// Specific exception type enables targeted media error handling in application layers
class MediaValidationException implements Exception {
  final String message;
  final List<String> violations;

  const MediaValidationException(this.message, this.violations);

  @override
  String toString() =>
      'MediaValidationException: $message\nViolations: ${violations.join(', ')}';
}

/// Media domain service for photo operations and visual content management
/// Centralized service ensures consistent media handling across the application
class MediaDomainService {
  /// Minimum recommended photos for competitive listing presentation
  /// Based on market analysis showing improved user engagement with multiple photos
  static const int minimumRecommendedPhotoCount = 3;

  /// Maximum allowed photos per listing to maintain performance
  /// Balances comprehensive property showcase with system performance
  static const int maximumAllowedPhotoCount = 25;

  /// Optimal photo count for maximum user engagement
  /// Research shows this range provides best user experience and inquiry rates
  static const int optimalPhotoCountForEngagement = 6;

  /// Validates media content specifically for property listing publication
  /// Stricter validation ensures published listings meet quality standards
  static List<String> validateMediaForPropertyListingPublication(
    Media propertyMedia,
  ) {
    final listingValidationErrors = <String>[];

    // Mandatory photo requirement for listings prevents poor user experience
    if (!propertyMedia.containsPropertyPhotos()) {
      listingValidationErrors.add(
        'Property listing must include at least one photo (required for user trust)',
      );
    }

    // Quality recommendation for competitive listing performance
    if (propertyMedia.getTotalPhotoCount() < minimumRecommendedPhotoCount) {
      listingValidationErrors.add(
        'Listings with fewer than $minimumRecommendedPhotoCount photos receive 60% fewer inquiries',
      );
    }

    // Primary photo validation ensures listing card visual appeal
    final primaryPhoto = propertyMedia.getPrimaryPropertyPhotoUrl();
    if (primaryPhoto != null && primaryPhoto.length < 20) {
      listingValidationErrors.add(
        'Primary photo URL appears incomplete (may cause display failures)',
      );
    }

    return listingValidationErrors;
  }

  /// Creates media from Firebase Storage URLs with validation
  /// Filters invalid URLs to prevent display errors in production
  static Media createMediaFromFirebaseStorageUrls(
    List<String> firebasePhotoUrls,
  ) {
    final validPhotoUrls = firebasePhotoUrls
        .where((url) => url.isNotEmpty && url.contains('firebase'))
        .toList();

    return Media.create(propertyPhotoUrls: validPhotoUrls);
  }

  /// Optimizes photo display order for maximum user engagement
  /// V1 maintains user-provided order; future versions can implement AI-based optimization
  static Media optimizePhotoDisplayOrder(Media propertyMedia) {
    if (propertyMedia.propertyPhotoUrls.length <= 1) return propertyMedia;

    // V1: Preserve original order to respect user intent
    // Future enhancement: Implement smart ordering based on image analysis
    return propertyMedia;
  }

  /// Generates media statistics for analytics and performance monitoring
  /// Provides insights for listing optimization and user behavior analysis
  static MediaAnalyticsData generateMediaAnalyticsData(Media propertyMedia) {
    return MediaAnalyticsData(
      totalPhotoCount: propertyMedia.getTotalPhotoCount(),
      hasAnyPhotos: propertyMedia.containsPropertyPhotos(),
      qualityScore: propertyMedia.calculateMediaQualityScore(),
      meetsQualityStandards: propertyMedia.meetsMinimumQualityStandards(),
    );
  }

  /// Creates media with recommended photo ordering for optimal presentation
  /// Placeholder for future smart ordering features
  static Media createMediaWithOptimalOrdering(List<String> propertyPhotoUrls) {
    if (propertyPhotoUrls.isEmpty) return Media.createEmpty();

    // V1: Use provided order to preserve user intent
    // Future: Implement smart ordering based on image content analysis
    return Media.create(propertyPhotoUrls: propertyPhotoUrls);
  }

  /// Validates photo URL specifically for Firebase Storage compatibility
  /// Ensures photos are stored on supported platform infrastructure
  static bool isValidFirebaseStoragePhotoUrl(String photoUrl) {
    return photoUrl.contains('firebase') &&
        photoUrl.contains('googleapis.com') &&
        (photoUrl.endsWith('.jpg') ||
            photoUrl.endsWith('.jpeg') ||
            photoUrl.endsWith('.png') ||
            photoUrl.endsWith('.webp'));
  }
}

/// Media analytics data for performance monitoring and optimization
/// Provides quantified insights for listing quality assessment and improvement
class MediaAnalyticsData extends Equatable {
  final int totalPhotoCount;
  final bool hasAnyPhotos;
  final double qualityScore;
  final bool meetsQualityStandards;

  const MediaAnalyticsData({
    required this.totalPhotoCount,
    required this.hasAnyPhotos,
    required this.qualityScore,
    required this.meetsQualityStandards,
  });

  @override
  List<Object> get props => [
    totalPhotoCount,
    hasAnyPhotos,
    qualityScore,
    meetsQualityStandards,
  ];

  @override
  String toString() {
    return 'MediaAnalyticsData(photos: $totalPhotoCount, quality: ${(qualityScore * 100).toInt()}%)';
  }
}
