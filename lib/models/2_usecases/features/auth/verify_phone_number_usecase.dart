// lib/models/2_usecases/features/auth/verify_phone_number_usecase.dart

// Import horizontal foundation - domain entities
import '../../../1_domain/shared/entities/user.dart';

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Verify Phone Number Use Case
///
/// Completes phone number verification for Peru market requirements.
/// Validates verification code and marks user as verified.
/// Used by presentation layer for phone verification completion.
class VerifyPhoneNumberUseCase {
  final IAuthRepository _authRepository;

  VerifyPhoneNumberUseCase(this._authRepository);

  /// Execute phone number verification
  ///
  /// Validates verification code and completes phone verification.
  /// Returns verified user on success or error details on failure.
  Future<ServiceResult<User>> execute({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      // Validate use case inputs
      final validationResult = _validateVerificationInputs(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Verification validation failed',
          validationResult.exception!,
        );
      }

      // Execute verification through repository
      final verificationResult = await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber.trim(),
        verificationCode: verificationCode.trim(),
      );

      if (!verificationResult.isSuccess) {
        return _mapVerificationError(verificationResult);
      }

      // Apply post-verification use case logic
      final verifiedUser = verificationResult.data!;
      final processedUser = _applyPostVerificationLogic(verifiedUser);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Phone verification execution failed',
        ServiceException(
          'Unexpected phone verification error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validateVerificationInputs({
    required String phoneNumber,
    required String verificationCode,
  }) {
    // Check phone number presence and format
    if (phoneNumber.trim().isEmpty) {
      return ServiceResult.failure(
        'Phone number required',
        ServiceException(
          'Phone number cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    final phoneValidation = _validatePeruPhoneNumber(phoneNumber.trim());
    if (!phoneValidation.isSuccess) return phoneValidation;

    // Check verification code presence and format
    if (verificationCode.trim().isEmpty) {
      return ServiceResult.failure(
        'Verification code required',
        ServiceException(
          'Verification code cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    if (verificationCode.trim().length < 4 ||
        verificationCode.trim().length > 8) {
      return ServiceResult.failure(
        'Invalid verification code',
        ServiceException(
          'Verification code must be between 4 and 8 characters',
          ServiceErrorType.validation,
        ),
      );
    }

    // Check for numeric verification code
    final numericCodeRegex = RegExp(r'^[0-9]+$');
    if (!numericCodeRegex.hasMatch(verificationCode.trim())) {
      return ServiceResult.failure(
        'Invalid verification code format',
        ServiceException(
          'Verification code must contain only numbers',
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
        'Invalid Peru phone number',
        ServiceException(
          'Phone number must be in format +51XXXXXXXXX for Peru',
          ServiceErrorType.validation,
        ),
      );
    }
    return ServiceResult.success(null);
  }

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<User> _mapVerificationError(
    ServiceResult<User> repositoryResult,
  ) {
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Invalid verification code',
          ServiceException(
            'The verification code is incorrect. Please check and try again.',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error',
          ServiceException(
            'Unable to verify code. Please check your connection.',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.validation:
        return ServiceResult.failure(
          'Verification failed',
          ServiceException(
            'Invalid verification code or phone number',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.business:
        return ServiceResult.failure(
          'Verification expired',
          ServiceException(
            'Verification code has expired. Please request a new code.',
            ServiceErrorType.business,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.serviceUnavailable:
        return ServiceResult.failure(
          'Verification service unavailable',
          ServiceException(
            'Phone verification service is temporarily unavailable.',
            ServiceErrorType.serviceUnavailable,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Verification failed',
          ServiceException(
            'Unable to verify phone number. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Post-verification business logic

  User _applyPostVerificationLogic(User user) {
    // Apply use case specific post-verification logic
    // Example: unlock platform features, send welcome message, update user capabilities

    // TODO: Will be filled when UI requirements are clear
    return user;
  }
}
