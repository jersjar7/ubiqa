// lib/models/2_usecases/features/auth/register_user_usecase.dart

// Import horizontal foundation - domain entities
import '../../../1_domain/shared/entities/user.dart';

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Register User Use Case
///
/// Handles new user account creation with email and password.
/// Encapsulates registration business logic and validation.
/// Used by presentation layer for sign-up operations.
class RegisterUserUseCase {
  final IAuthRepository _authRepository;

  RegisterUserUseCase(this._authRepository);

  /// Execute user registration with email and password
  ///
  /// Validates inputs and delegates to repository for account creation.
  /// Returns new user on success or error details on failure.
  Future<ServiceResult<User>> execute({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      // Validate use case inputs
      final validationResult = _validateRegistrationInputs(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Registration validation failed',
          validationResult.exception!,
        );
      }

      // Execute registration through repository
      final registrationResult = await _authRepository
          .registerWithEmailAndPassword(
            email: email.trim(),
            password: password,
            fullName: fullName?.trim(),
            phoneNumber: phoneNumber?.trim(),
          );

      if (!registrationResult.isSuccess) {
        return _mapRegistrationError(registrationResult);
      }

      // Apply post-registration use case logic
      final user = registrationResult.data!;
      final processedUser = _applyPostRegistrationLogic(user);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Registration execution failed',
        ServiceException(
          'Unexpected registration error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validateRegistrationInputs({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  }) {
    // Check email presence and format
    if (email.trim().isEmpty) {
      return ServiceResult.failure(
        'Email required',
        ServiceException(
          'Email address cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

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

    // Check password presence and strength
    if (password.trim().isEmpty) {
      return ServiceResult.failure(
        'Password required',
        ServiceException(
          'Password cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    if (password.length < 8) {
      return ServiceResult.failure(
        'Password too weak',
        ServiceException(
          'Password must be at least 8 characters long',
          ServiceErrorType.validation,
        ),
      );
    }

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
    }

    // Validate Peru phone number if provided
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      final phoneValidation = _validatePeruPhoneNumber(phoneNumber.trim());
      if (!phoneValidation.isSuccess) return phoneValidation;
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

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<User> _mapRegistrationError(
    ServiceResult<User> repositoryResult,
  ) {
    // Map repository errors to user-friendly messages
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Email already registered',
          ServiceException(
            'This email is already in use. Please try signing in instead.',
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
          'Registration validation failed',
          ServiceException(
            'Please check your information and try again',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.business:
        return ServiceResult.failure(
          'Registration not allowed',
          ServiceException(
            'Registration is temporarily unavailable. Please try again later.',
            ServiceErrorType.business,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Registration failed',
          ServiceException(
            'Something went wrong. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Post-registration business logic

  User _applyPostRegistrationLogic(User user) {
    // Apply use case specific post-registration logic
    // Example: send welcome email, log registration event, set initial preferences

    // For now, return user as-is
    // TODO: Will be filled when UI requirements are clear
    return user;
  }
}
