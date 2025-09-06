// lib/models/2_usecases/features/auth/login_user_usecase.dart

// Import horizontal foundation - domain entities
import '../../../1_domain/shared/entities/user.dart';

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Login User Use Case
///
/// Handles user authentication with email and password.
/// Encapsulates authentication business logic and validation.
/// Used by presentation layer for sign-in operations.
class LoginUserUseCase {
  final IAuthRepository _authRepository;

  LoginUserUseCase(this._authRepository);

  /// Execute user login with email and password
  ///
  /// Validates inputs and delegates to repository for authentication.
  /// Returns authenticated user on success or error details on failure.
  Future<ServiceResult<User>> execute({
    required String email,
    required String password,
  }) async {
    try {
      // Validate use case inputs
      final validationResult = _validateLoginInputs(
        email: email,
        password: password,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Login validation failed',
          validationResult.exception!,
        );
      }

      // Execute authentication through repository
      final loginResult = await _authRepository.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (!loginResult.isSuccess) {
        return _mapAuthenticationError(loginResult);
      }

      // Apply post-login use case logic
      final user = loginResult.data!;
      final processedUser = _applyPostLoginLogic(user);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Login execution failed',
        ServiceException('Unexpected login error', ServiceErrorType.unknown, e),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validateLoginInputs({
    required String email,
    required String password,
  }) {
    // Check email presence and basic format
    if (email.trim().isEmpty) {
      return ServiceResult.failure(
        'Email required',
        ServiceException(
          'Email address cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    // Check password presence
    if (password.trim().isEmpty) {
      return ServiceResult.failure(
        'Password required',
        ServiceException(
          'Password cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    // Basic email format validation
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

  ServiceResult<User> _mapAuthenticationError(
    ServiceResult<User> repositoryResult,
  ) {
    // Map repository errors to user-friendly messages
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Invalid email or password',
          ServiceException(
            'Please check your credentials and try again',
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
          'Account validation issue',
          ServiceException(
            'There was an issue with your account. Please contact support.',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Login failed',
          ServiceException(
            'Something went wrong. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Post-login business logic

  User _applyPostLoginLogic(User user) {
    // Apply use case specific post-login logic
    // Example: log login event, check account status, update last login

    // For now, return user as-is
    // TODO: Will be filled when UI requirements are clear
    return user;
  }
}
