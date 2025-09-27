// lib/services/4_infrastructure/firebase/firebase_storage_service.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';

// Import domain entities for type safety
import '../../../models/1_domain/shared/entities/property.dart';
import '../../../models/1_domain/shared/entities/user.dart';

// Import configuration
import '../../0_config/shared/firebase_config.dart';

// Import shared infrastructure
import '../shared/service_result.dart';

/// Firebase Storage Service for Ubiqa Photo Management
///
/// WHY this service exists:
/// Peru's real estate market is mobile-heavy with expensive data plans.
/// Property photos must load quickly and consume minimal bandwidth while
/// maintaining visual quality. This service optimizes images for Peru's
/// mobile infrastructure constraints.
///
/// WORKFLOW:
/// 1. Receive raw image file from user device
/// 2. Resize to optimal dimensions (1200px max width)
/// 3. Convert to .webp format with 85% quality
/// 4. Generate thumbnail version (300px) for listing cards
/// 5. Upload both optimized files to Firebase Storage
/// 6. Return URLs for Media value object
/// 7. firestore_service.dart saves URLs as structured data
class FirebaseStorageService {
  // PHOTO UPLOAD OPERATIONS
  // WHY: Property photos are the primary engagement driver in real estate

  /// Uploads property photos with optimization for Peru mobile market
  /// Returns both full-size and thumbnail URLs for different UI contexts
  Future<ServiceResult<PropertyPhotoUrls>> uploadPropertyPhotos({
    required PropertyId propertyId,
    required List<File> imageFiles,
  }) async {
    try {
      if (imageFiles.isEmpty) {
        return ServiceResult.failure(
          'No images provided for upload',
          ServiceException('Empty image list', ServiceErrorType.validation),
        );
      }

      if (imageFiles.length > 10) {
        return ServiceResult.failure(
          'Maximum 10 photos allowed per property',
          ServiceException('Photo limit exceeded', ServiceErrorType.validation),
        );
      }

      // Validate each image file before processing
      // WHY: Early validation prevents wasted compression/upload attempts
      for (int index = 0; index < imageFiles.length; index++) {
        final imageFile = imageFiles[index];

        // Validate file type using private validation method
        if (!_isValidImageFile(imageFile)) {
          return ServiceResult.failure(
            'Invalid image format for photo ${index + 1}. Supported: JPG, PNG, WebP',
            ServiceException(
              'Invalid image format',
              ServiceErrorType.validation,
            ),
          );
        }

        // Validate file size using private validation method (10MB limit for property photos)
        final fileSizeMB = await _getFileSizeInMB(imageFile);
        if (fileSizeMB > 10.0) {
          return ServiceResult.failure(
            'Photo ${index + 1} is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum 10MB allowed',
            ServiceException('File size exceeded', ServiceErrorType.validation),
          );
        }
      }

      final photoUrls = <String>[];
      final thumbnailUrls = <String>[];

      // Process each image with optimization
      for (int index = 0; index < imageFiles.length; index++) {
        final imageFile = imageFiles[index];

        // Generate unique filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final baseFileName = 'property-${propertyId.value}-$timestamp-$index';

        // Upload full-size optimized image
        final fullSizeResult = await _uploadOptimizedImage(
          imageFile: imageFile,
          storagePath:
              'property-photos/${propertyId.value}/full-$baseFileName.webp',
          maxWidth: 1200,
          quality: 85,
        );

        if (!fullSizeResult.isSuccess) {
          return ServiceResult.failure(
            'Failed to upload property photo ${index + 1}',
            fullSizeResult.exception!,
          );
        }

        // Upload thumbnail for fast loading
        final thumbnailResult = await _uploadOptimizedImage(
          imageFile: imageFile,
          storagePath:
              'property-photos/${propertyId.value}/thumb-$baseFileName.webp',
          maxWidth: 300,
          quality: 80,
        );

        if (!thumbnailResult.isSuccess) {
          return ServiceResult.failure(
            'Failed to upload photo thumbnail ${index + 1}',
            thumbnailResult.exception!,
          );
        }

        photoUrls.add(fullSizeResult.data!);
        thumbnailUrls.add(thumbnailResult.data!);
      }

      final result = PropertyPhotoUrls(
        fullSizeUrls: photoUrls,
        thumbnailUrls: thumbnailUrls,
      );

      return ServiceResult.success(result);
    } catch (e) {
      return ServiceResult.failure(
        'Property photo upload failed',
        ServiceException('Photo upload error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Uploads user profile photo with consistent optimization
  /// WHY: Profile photos enhance trust and communication in Peru market
  Future<ServiceResult<String>> uploadUserProfilePhoto({
    required UserId userId,
    required File imageFile,
  }) async {
    try {
      // Validate file type using private validation method
      if (!_isValidImageFile(imageFile)) {
        return ServiceResult.failure(
          'Invalid image format. Supported: JPG, PNG, WebP',
          ServiceException('Invalid image format', ServiceErrorType.validation),
        );
      }

      // Validate file size using private validation method (5MB limit for profile photos)
      final fileSizeMB = await _getFileSizeInMB(imageFile);
      if (fileSizeMB > 5.0) {
        return ServiceResult.failure(
          'Profile photo is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum 5MB allowed',
          ServiceException('File size exceeded', ServiceErrorType.validation),
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile-${userId.value}-$timestamp.webp';

      final result = await _uploadOptimizedImage(
        imageFile: imageFile,
        storagePath: 'user-photos/$fileName',
        maxWidth: 400,
        quality: 85,
      );

      if (!result.isSuccess) {
        return ServiceResult.failure(
          'Failed to upload profile photo',
          result.exception!,
        );
      }

      return ServiceResult.success(result.data!);
    } catch (e) {
      return ServiceResult.failure(
        'Profile photo upload failed',
        ServiceException('Profile photo error', ServiceErrorType.unknown, e),
      );
    }
  }

  // PHOTO DELETION OPERATIONS
  // WHY: Storage cost management and user privacy requirements

  /// Deletes property photos when listing is removed
  /// WHY: Prevents storage costs accumulation and ensures user privacy
  Future<ServiceResult<void>> deletePropertyPhotos({
    required PropertyId propertyId,
  }) async {
    try {
      final propertyFolderRef = FirebaseConfig.propertyPhotosRef.child(
        propertyId.value,
      );

      // List all files in the property folder
      final listResult = await propertyFolderRef.listAll();

      // Delete all photos for this property
      final deleteTasks = listResult.items.map((item) => item.delete());
      await Future.wait(deleteTasks);

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to delete property photos',
        ServiceException('Photo deletion error', ServiceErrorType.unknown, e),
      );
    }
  }

  /// Deletes user profile photo
  /// WHY: User privacy and account cleanup
  Future<ServiceResult<void>> deleteUserProfilePhoto({
    required UserId userId,
  }) async {
    try {
      // List all profile photos for this user (in case of multiple versions)
      final userFolderRef = FirebaseConfig.userPhotosRef;
      final listResult = await userFolderRef.listAll();

      final userPhotoRefs = listResult.items.where(
        (item) => item.name.startsWith('profile-${userId.value}'),
      );

      final deleteTasks = userPhotoRefs.map((ref) => ref.delete());
      await Future.wait(deleteTasks);

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to delete profile photo',
        ServiceException(
          'Profile photo deletion error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE VALIDATION AND HELPER METHODS
  // WHY: Centralized validation and optimization logic for consistent results

  /// Validates image file before processing
  /// WHY: Prevent processing invalid files that would cause errors
  /// USED BY: uploadPropertyPhotos() and uploadUserProfilePhoto()
  bool _isValidImageFile(File imageFile) {
    final extension = path_utils.extension(imageFile.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return validExtensions.contains(extension);
  }

  /// Gets image file size in MB for validation
  /// WHY: Prevent upload of excessively large files that would consume data
  /// USED BY: uploadPropertyPhotos() and uploadUserProfilePhoto()
  Future<double> _getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024); // Convert to MB
  }

  /// Optimizes and uploads single image with WebP conversion
  /// Core optimization workflow for Peru's mobile-heavy market
  Future<ServiceResult<String>> _uploadOptimizedImage({
    required File imageFile,
    required String storagePath,
    required int maxWidth,
    required int quality,
  }) async {
    try {
      // Get temporary directory for processing
      final tempDir = await getTemporaryDirectory();
      final tempFileName = path_utils.basenameWithoutExtension(storagePath);
      final tempFilePath = path_utils.join(tempDir.path, '$tempFileName.webp');

      // Optimize image: resize and convert to WebP
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: maxWidth,
        minHeight: maxWidth, // Maintain aspect ratio
        quality: quality,
        format: CompressFormat.webp,
      );

      if (compressedBytes == null) {
        return ServiceResult.failure(
          'Image compression failed',
          ServiceException('Compression error', ServiceErrorType.unknown),
        );
      }

      // Write optimized file to temporary location
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(compressedBytes);

      // Upload to Firebase Storage
      final storageRef = FirebaseConfig.storage.ref(storagePath);
      final uploadTask = await storageRef.putFile(
        tempFile,
        SettableMetadata(
          contentType: 'image/webp',
          cacheControl: 'public, max-age=31536000', // 1 year cache
        ),
      );

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return ServiceResult.success(downloadUrl);
    } catch (e) {
      return ServiceResult.failure(
        'Image optimization and upload failed',
        ServiceException(
          'Upload processing error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }
}

/// Result container for property photo upload operations
/// Contains both full-size and thumbnail URLs for flexible UI usage
class PropertyPhotoUrls {
  final List<String> fullSizeUrls;
  final List<String> thumbnailUrls;

  const PropertyPhotoUrls({
    required this.fullSizeUrls,
    required this.thumbnailUrls,
  });

  /// Converts to format expected by Media value object
  /// WHY: Domain layer expects simple URL list, not complex structure
  List<String> toMediaPhotoUrls() => fullSizeUrls;

  @override
  String toString() {
    return 'PropertyPhotoUrls(${fullSizeUrls.length} photos uploaded)';
  }
}
