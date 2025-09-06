// lib/models/2_usecases/features/auth/request_password_reset_usecase.dart

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Request Password Reset Use Case
///
/// Initiates password reset flow via email.
/// Validates email and sends reset instructions to user.
/// Used by presentation layer for forgot password operations.
class RequestPasswordResetUseCase {
  final IAuthRepository _authRepository;

  RequestPasswordResetUseCase(this._authRepository);

  /// Execute password reset request
  ///
  /// Validates email and sends password reset email.
  /// Returns success or error details on failure.
  Future<ServiceResult<void>> execute({required String email}) async {
    try {
      // Validate use case inputs
      final validationResult = _validatePasswordResetInputs(email: email);

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Password reset validation failed',
          validationResult.exception!,
        );
      }

      // Apply pre-reset request logic
      await _applyPreResetRequestLogic(email.trim());

      // Execute password reset through repository
      final resetResult = await _authRepository.requestPasswordReset(
        email: email.trim(),
      );

      if (!resetResult.isSuccess) {
        return _mapPasswordResetError(resetResult);
      }

      // Apply post-reset request logic
      await _applyPostResetRequestLogic(email.trim());

      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Password reset execution failed',
        ServiceException(
          'Unexpected password reset error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validatePasswordResetInputs({required String email}) {
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

  ServiceResult<void> _mapPasswordResetError(
    ServiceResult<void> repositoryResult,
  ) {
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Email not found',
          ServiceException(
            'No account found with this email address',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error',
          ServiceException(
            'Unable to send reset email. Please check your connection.',
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

      case ServiceErrorType.business:
        return ServiceResult.failure(
          'Reset limit reached',
          ServiceException(
            'Too many reset requests. Please wait before trying again.',
            ServiceErrorType.business,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.serviceUnavailable:
        return ServiceResult.failure(
          'Email service unavailable',
          ServiceException(
            'Email service is temporarily unavailable. Please try again later.',
            ServiceErrorType.serviceUnavailable,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Password reset failed',
          ServiceException(
            'Unable to send reset email. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Pre/post reset request business logic

  Future<void> _applyPreResetRequestLogic(String email) async {
    // Apply use case specific pre-reset logic
    // Example: check rate limits, log reset attempt, validate account status

    // TODO: Will be filled when UI requirements are clear
  }

  Future<void> _applyPostResetRequestLogic(String email) async {
    // Apply use case specific post-reset logic
    // Example: log successful reset request, send analytics event

    // TODO: Will be filled when UI requirements are clear
  }
}
