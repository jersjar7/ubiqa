// lib/models/2_usecases/features/auth/update_user_profile_usecase.dart

// Import horizontal foundation - domain entities
import '../../../1_domain/shared/entities/user.dart';

// Import horizontal foundation - value objects
import '../../../1_domain/shared/value_objects/contact_info.dart';

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Update User Profile Use Case
///
/// Handles user profile information updates.
/// Validates changes and applies business rules for profile modifications.
/// Used by presentation layer for profile editing operations.
class UpdateUserProfileUseCase {
  final IAuthRepository _authRepository;

  UpdateUserProfileUseCase(this._authRepository);

  /// Execute user profile update
  ///
  /// Validates inputs and updates user profile information.
  /// Returns updated user on success or error details on failure.
  Future<ServiceResult<User>> execute({
    required User currentUser,
    String? fullName,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? profileImageUrl,
  }) async {
    try {
      // Validate use case inputs
      final validationResult = _validateProfileUpdateInputs(
        currentUser: currentUser,
        fullName: fullName,
        phoneNumber: phoneNumber,
        preferredContactHours: preferredContactHours,
        profileImageUrl: profileImageUrl,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Profile update validation failed',
          validationResult.exception!,
        );
      }

      // Execute update through repository
      final updateResult = await _authRepository.updateUserProfile(
        currentUser: currentUser,
        fullName: fullName?.trim(),
        phoneNumber: phoneNumber?.trim(),
        preferredContactHours: preferredContactHours,
        profileImageUrl: profileImageUrl?.trim(),
      );

      if (!updateResult.isSuccess) {
        return _mapProfileUpdateError(updateResult);
      }

      // Apply post-update use case logic
      final updatedUser = updateResult.data!;
      final processedUser = _applyPostUpdateLogic(updatedUser);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Profile update execution failed',
        ServiceException(
          'Unexpected profile update error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validateProfileUpdateInputs({
    required User currentUser,
    String? fullName,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? profileImageUrl,
  }) {
    // Validate full name if provided
    if (fullName != null && fullName.trim().isNotEmpty) {
      if (fullName.trim().length < 2) {
        return ServiceResult.failure(
          'Invalid name',
          ServiceException(
            'Name must be at least 2 characters long',
            ServiceErrorType.validation,
          ),
        );
      }

      if (fullName.trim().length > 50) {
        return ServiceResult.failure(
          'Name too long',
          ServiceException(
            'Name must be 50 characters or less',
            ServiceErrorType.validation,
          ),
        );
      }
    }

    // Validate Peru phone number if provided
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      final phoneValidation = _validatePeruPhoneNumber(phoneNumber.trim());
      if (!phoneValidation.isSuccess) return phoneValidation;
    }

    // Validate profile image URL if provided
    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      final imageValidation = _validateImageUrl(profileImageUrl.trim());
      if (!imageValidation.isSuccess) return imageValidation;
    }

    // Check if at least one field is being updated
    if (_isNoUpdateProvided(
      fullName,
      phoneNumber,
      preferredContactHours,
      profileImageUrl,
    )) {
      return ServiceResult.failure(
        'No updates provided',
        ServiceException(
          'At least one field must be updated',
          ServiceErrorType.validation,
        ),
      );
    }

    return ServiceResult.success(null);
  }

  ServiceResult<void> _validatePeruPhoneNumber(String phoneNumber) {
    // Peru phone number format: +51 followed by 9 digits
    final peruPhoneRegex = RegExp(r'^\+51[0-9]{9}$');
    if (!peruPhoneRegex.hasMatch(phoneNumber)) {
      return ServiceResult.failure(
        'Invalid phone number',
        ServiceException(
          'Phone number must be in format +51XXXXXXXXX',
          ServiceErrorType.validation,
        ),
      );
    }
    return ServiceResult.success(null);
  }

  ServiceResult<void> _validateImageUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return ServiceResult.failure(
          'Invalid image URL',
          ServiceException(
            'Image URL must be a valid HTTP/HTTPS URL',
            ServiceErrorType.validation,
          ),
        );
      }
      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Invalid image URL',
        ServiceException(
          'Image URL format is invalid',
          ServiceErrorType.validation,
          e,
        ),
      );
    }
  }

  bool _isNoUpdateProvided(
    String? fullName,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? profileImageUrl,
  ) {
    return (fullName == null || fullName.trim().isEmpty) &&
        (phoneNumber == null || phoneNumber.trim().isEmpty) &&
        preferredContactHours == null &&
        (profileImageUrl == null || profileImageUrl.trim().isEmpty);
  }

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<User> _mapProfileUpdateError(
    ServiceResult<User> repositoryResult,
  ) {
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Authentication required',
          ServiceException(
            'Please sign in again to update your profile',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error',
          ServiceException(
            'Please check your internet connection and try again',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.validation:
        return ServiceResult.failure(
          'Profile validation failed',
          ServiceException(
            'Please check your information and try again',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Profile update failed',
          ServiceException(
            'Something went wrong. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Post-update business logic

  User _applyPostUpdateLogic(User user) {
    // Apply use case specific post-update logic
    // Example: recalculate profile completeness, log profile changes, send notifications

    // TODO: Will be filled when UI requirements are clear
    return user;
  }
}
