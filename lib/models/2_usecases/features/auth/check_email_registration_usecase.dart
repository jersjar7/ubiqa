// lib/models/2_usecases/features/auth/check_email_registration_usecase.dart

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Check Email Registration Use Case
///
/// Verifies if email address is already registered.
/// Used by presentation layer for registration flow UX optimization.
class CheckEmailRegistrationUseCase {
  final IAuthRepository _authRepository;

  CheckEmailRegistrationUseCase(this._authRepository);

  /// Execute email registration check
  ///
  /// Returns true if email is registered, false if available.
  Future<ServiceResult<bool>> execute({required String email}) async {
    try {
      // Validate use case inputs
      final validationResult = _validateEmailCheckInputs(email: email);

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Email check validation failed',
          validationResult.exception!,
        );
      }

      // Execute email check through repository
      final checkResult = await _authRepository.isEmailRegistered(
        email: email.trim(),
      );

      if (!checkResult.isSuccess) {
        return _mapEmailCheckError(checkResult);
      }

      // Apply post-check logic
      final isRegistered = checkResult.data!;
      _applyPostEmailCheckLogic(email.trim(), isRegistered);

      return ServiceResult.success(isRegistered);
    } catch (e) {
      return ServiceResult.failure(
        'Email check execution failed',
        ServiceException(
          'Unexpected email check error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validateEmailCheckInputs({required String email}) {
    // Check email presence
    if (email.trim().isEmpty) {
      return ServiceResult.failure(
        'Email required',
        ServiceException(
          'Email address cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ServiceResult.failure(
        'Invalid email format',
        ServiceException(
          'Please enter a valid email address',
          ServiceErrorType.validation,
        ),
      );
    }

    return ServiceResult.success(null);
  }

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<bool> _mapEmailCheckError(
    ServiceResult<bool> repositoryResult,
  ) {
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error',
          ServiceException(
            'Unable to check email availability. Please check your connection.',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.validation:
        return ServiceResult.failure(
          'Email validation failed',
          ServiceException(
            'Invalid email address format',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.serviceUnavailable:
        return ServiceResult.failure(
          'Service unavailable',
          ServiceException(
            'Email verification service is temporarily unavailable.',
            ServiceErrorType.serviceUnavailable,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.business:
        return ServiceResult.failure(
          'Check limit reached',
          ServiceException(
            'Too many email checks. Please wait before trying again.',
            ServiceErrorType.business,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Email check failed',
          ServiceException(
            'Unable to verify email availability. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Post-check business logic

  void _applyPostEmailCheckLogic(String email, bool isRegistered) {
    // Apply use case specific post-check logic
    // Example: log email check event, update UI guidance, analytics tracking

    // TODO: Will be filled when UI requirements are clear
  }
}
