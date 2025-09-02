// lib/models/1_domain/shared/value_objects/media.dart

import 'package:equatable/equatable.dart';

/// Media value object for property visual content
///
/// This immutable value object handles property photos and their display
/// order for Ubiqa's visual-first property discovery experience.
///
/// V1 Scope: Property photos with basic ordering and validation
class Media extends Equatable {
  /// List of photo URLs in display order
  final List<String> photoUrls;

  const Media._({required this.photoUrls});

  /// Creates Media with validation
  factory Media.create({required List<String> photoUrls}) {
    final media = Media._(
      photoUrls: photoUrls.map((url) => url.trim()).toList(),
    );

    final violations = media._validate();
    if (violations.isNotEmpty) {
      throw MediaException('Invalid media data', violations);
    }

    return media;
  }

  /// Creates empty Media (no photos)
  factory Media.empty() {
    return const Media._(photoUrls: []);
  }

  /// Creates Media with single photo
  factory Media.singlePhoto(String photoUrl) {
    return Media.create(photoUrls: [photoUrl]);
  }

  // PHOTO MANAGEMENT

  /// Gets primary photo URL (first photo)
  String? getPrimaryPhoto() {
    return photoUrls.isNotEmpty ? photoUrls.first : null;
  }

  /// Gets all photo URLs except primary
  List<String> getSecondaryPhotos() {
    return photoUrls.length > 1 ? photoUrls.sublist(1) : [];
  }

  /// Checks if media has any photos
  bool hasPhotos() {
    return photoUrls.isNotEmpty;
  }

  /// Gets total photo count
  int getPhotoCount() {
    return photoUrls.length;
  }

  /// Gets photo at specific index (null if out of bounds)
  String? getPhotoAt(int index) {
    return index >= 0 && index < photoUrls.length ? photoUrls[index] : null;
  }

  // PHOTO ORDERING

  /// Adds photo to the end of the list
  Media addPhoto(String photoUrl) {
    final updatedUrls = [...photoUrls, photoUrl.trim()];
    return Media.create(photoUrls: updatedUrls);
  }

  /// Adds photo at specific position
  Media insertPhotoAt(int index, String photoUrl) {
    final updatedUrls = [...photoUrls];
    updatedUrls.insert(index, photoUrl.trim());
    return Media.create(photoUrls: updatedUrls);
  }

  /// Removes photo at specific index
  Media removePhotoAt(int index) {
    if (index < 0 || index >= photoUrls.length) {
      return this;
    }

    final updatedUrls = [...photoUrls];
    updatedUrls.removeAt(index);
    return Media.create(photoUrls: updatedUrls);
  }

  /// Removes specific photo URL
  Media removePhoto(String photoUrl) {
    final updatedUrls = photoUrls.where((url) => url != photoUrl).toList();
    return Media.create(photoUrls: updatedUrls);
  }

  /// Moves photo from one position to another
  Media movePhoto(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= photoUrls.length ||
        toIndex < 0 ||
        toIndex >= photoUrls.length) {
      return this;
    }

    final updatedUrls = [...photoUrls];
    final photo = updatedUrls.removeAt(fromIndex);
    updatedUrls.insert(toIndex, photo);

    return Media.create(photoUrls: updatedUrls);
  }

  /// Sets photo as primary (moves to first position)
  Media setAsPrimary(String photoUrl) {
    if (!photoUrls.contains(photoUrl)) {
      return this;
    }

    final updatedUrls = photoUrls.where((url) => url != photoUrl).toList();
    updatedUrls.insert(0, photoUrl);

    return Media.create(photoUrls: updatedUrls);
  }

  // DISPLAY HELPERS

  /// Gets photos for gallery display (limited count)
  List<String> getPhotosForGallery({int maxPhotos = 10}) {
    return photoUrls.take(maxPhotos).toList();
  }

  /// Gets photos for listing card preview (first few photos)
  List<String> getPhotosForPreview({int maxPhotos = 3}) {
    return photoUrls.take(maxPhotos).toList();
  }

  /// Gets photo URLs suitable for thumbnail display
  List<String> getThumbnailUrls() {
    // In V1, same as regular URLs - Firebase Storage can handle thumbnail generation
    return photoUrls;
  }

  // VALIDATION AND QUALITY CHECKS

  /// Checks if media meets minimum quality standards
  bool meetsMinimumStandards() {
    // V1: Just check if has at least one photo
    return photoUrls.isNotEmpty;
  }

  /// Gets quality score (0.0 to 1.0)
  double getQualityScore() {
    var score = 0.0;

    // Base score for having photos
    if (photoUrls.isEmpty) return 0.0;

    // Photo count contribution (up to 0.6)
    final photoCountScore = (photoUrls.length / 8.0).clamp(0.0, 0.6);
    score += photoCountScore;

    // Primary photo bonus (0.2)
    if (getPrimaryPhoto() != null) {
      score += 0.2;
    }

    // Multiple photos bonus (0.2)
    if (photoUrls.length > 1) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Gets recommendations for improving media quality
  List<String> getQualityRecommendations() {
    final recommendations = <String>[];

    if (photoUrls.isEmpty) {
      recommendations.add('Agrega al menos una foto de la propiedad');
    } else if (photoUrls.length == 1) {
      recommendations.add('Agrega más fotos para mostrar mejor la propiedad');
    }

    if (photoUrls.length < 3) {
      recommendations.add('Las propiedades con 3+ fotos reciben más interés');
    }

    if (photoUrls.length > 15) {
      recommendations.add(
        'Considera reducir el número de fotos para mejor experiencia',
      );
    }

    return recommendations;
  }

  // URL PROCESSING

  /// Checks if URL appears to be a valid image URL
  bool _isValidImageUrl(String url) {
    if (url.trim().isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Must be HTTP/HTTPS
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return false;
      }

      // Basic image file extension check
      final path = uri.path.toLowerCase();
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      return imageExtensions.any((ext) => path.endsWith(ext)) ||
          path.contains('/image/') || // Firebase Storage pattern
          url.contains('firebase') || // Firebase URLs
          url.contains('googleapis'); // Google Storage URLs
    } catch (e) {
      return false;
    }
  }

  // VALIDATION

  /// Validates media data
  List<String> _validate() {
    final errors = <String>[];

    // Photo count validation
    if (photoUrls.length > 20) {
      errors.add('Cannot have more than 20 photos');
    }

    // Individual photo validation
    for (int i = 0; i < photoUrls.length; i++) {
      final url = photoUrls[i];

      if (url.trim().isEmpty) {
        errors.add('Photo URL at index $i cannot be empty');
        continue;
      }

      if (url.length > 1000) {
        errors.add('Photo URL at index $i is too long');
        continue;
      }

      if (!_isValidImageUrl(url)) {
        errors.add('Invalid image URL at index $i');
      }
    }

    // Check for duplicate URLs
    final uniqueUrls = photoUrls.toSet();
    if (uniqueUrls.length != photoUrls.length) {
      errors.add('Duplicate photo URLs are not allowed');
    }

    return errors;
  }

  // VALUE OBJECT EQUALITY - Based on all fields
  @override
  List<Object> get props => [photoUrls];

  @override
  String toString() {
    return 'Media(${photoUrls.length} photos)';
  }
}

/// Exception for media validation errors
class MediaException implements Exception {
  final String message;
  final List<String> violations;

  const MediaException(this.message, this.violations);

  @override
  String toString() =>
      'MediaException: $message\nViolations: ${violations.join(', ')}';
}

/// Media domain service for common operations
class MediaDomainService {
  /// Minimum recommended photos for listings
  static const int minRecommendedPhotos = 3;

  /// Maximum allowed photos per listing
  static const int maxPhotosPerListing = 20;

  /// Optimal photo count for best user engagement
  static const int optimalPhotoCount = 6;

  /// Validates media for property listing
  static List<String> validateForListing(Media media) {
    final errors = <String>[];

    // Must have at least one photo
    if (!media.hasPhotos()) {
      errors.add('Property listing must have at least one photo');
    }

    // Quality recommendations
    if (media.getPhotoCount() < minRecommendedPhotos) {
      errors.add(
        'Listings with fewer than $minRecommendedPhotos photos receive less interest',
      );
    }

    return errors;
  }

  /// Creates media from Firebase Storage URLs
  static Media createFromFirebaseUrls(List<String> firebaseUrls) {
    // Filter out any invalid URLs
    final validUrls = firebaseUrls
        .where((url) => url.isNotEmpty && url.contains('firebase'))
        .toList();

    return Media.create(photoUrls: validUrls);
  }

  /// Optimizes photo order for best presentation
  static Media optimizePhotoOrder(Media media) {
    if (media.photoUrls.length <= 1) return media;

    // V1: Keep original order (more sophisticated ordering logic can be added later)
    // Future: Could analyze image content, lighting, etc.
    return media;
  }

  /// Gets media statistics for analytics
  static MediaStatistics getStatistics(Media media) {
    return MediaStatistics(
      photoCount: media.getPhotoCount(),
      hasPhotos: media.hasPhotos(),
      qualityScore: media.getQualityScore(),
      meetsMinimumStandards: media.meetsMinimumStandards(),
    );
  }

  /// Creates media with recommended photo order
  static Media createWithRecommendedOrder(List<String> photoUrls) {
    if (photoUrls.isEmpty) return Media.empty();

    // V1: Use provided order
    // Future: Could implement smart ordering based on image analysis
    return Media.create(photoUrls: photoUrls);
  }

  /// Validates photo URL format specifically for Firebase Storage
  static bool isValidFirebaseStorageUrl(String url) {
    return url.contains('firebase') &&
        url.contains('googleapis.com') &&
        (url.endsWith('.jpg') ||
            url.endsWith('.jpeg') ||
            url.endsWith('.png') ||
            url.endsWith('.webp'));
  }
}

/// Media statistics for analytics and reporting
class MediaStatistics extends Equatable {
  final int photoCount;
  final bool hasPhotos;
  final double qualityScore;
  final bool meetsMinimumStandards;

  const MediaStatistics({
    required this.photoCount,
    required this.hasPhotos,
    required this.qualityScore,
    required this.meetsMinimumStandards,
  });

  @override
  List<Object> get props => [
    photoCount,
    hasPhotos,
    qualityScore,
    meetsMinimumStandards,
  ];

  @override
  String toString() {
    return 'MediaStatistics(photos: $photoCount, quality: ${(qualityScore * 100).toInt()}%)';
  }
}
