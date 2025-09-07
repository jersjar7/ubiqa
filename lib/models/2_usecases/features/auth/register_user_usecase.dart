// lib/models/2_usecases/features/auth/register_user_usecase.dart

// Import horizontal foundation - domain entities
import '../../../1_domain/shared/entities/user.dart';

// Import horizontal foundation - value objects
import '../../../1_domain/shared/value_objects/international_phone_number.dart';

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Register User Use Case
///
/// Handles new user account creation with email and password.
/// Encapsulates registration business logic and validation.
/// Used by presentation layer for sign-up operations.
///
/// Updated: Now supports international phone numbers for Peru and US markets
class RegisterUserUseCase {
  final IAuthRepository _authRepository;

  RegisterUserUseCase(this._authRepository);

  /// Execute user registration with email and password
  ///
  /// Validates inputs and delegates to repository for account creation.
  /// Returns new user on success or error details on failure.
  /// Supports international phone numbers with country code context
  Future<ServiceResult<User>> execute({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    SupportedCountryCode? countryCode,
  }) async {
    try {
      // Validate use case inputs
      final validationResult = _validateRegistrationInputs(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
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
            countryCode: countryCode,
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
    SupportedCountryCode? countryCode,
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

    // Validate international phone number if provided
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      final phoneValidation = _validateInternationalPhoneNumber(
        phoneNumber.trim(),
        countryCode,
      );
      if (!phoneValidation.isSuccess) return phoneValidation;
    }

    return ServiceResult.success(null);
  }

  ServiceResult<void> _validateInternationalPhoneNumber(
    String phoneNumber,
    SupportedCountryCode? expectedCountryCode,
  ) {
    // Use domain service for international phone validation
    if (!InternationalPhoneNumberDomainService.isValidInternationalPhoneNumber(
      phoneNumber,
    )) {
      String errorMessage = 'Phone number must be in international format';

      // Provide country-specific guidance
      if (expectedCountryCode != null) {
        final example =
            InternationalPhoneNumberDomainService.getFormatExampleForCountry(
              expectedCountryCode,
            );
        errorMessage += ' (example: $example)';
      } else {
        errorMessage += ' (+51XXXXXXXXX for Peru, +1XXXXXXXXXX for US)';
      }

      return ServiceResult.failure(
        'Invalid phone number',
        ServiceException(errorMessage, ServiceErrorType.validation),
      );
    }

    // Optional: Validate that phone number matches expected country
    if (expectedCountryCode != null) {
      try {
        final internationalPhone = InternationalPhoneNumber.create(
          phoneNumber: phoneNumber,
        );
        if (internationalPhone.detectedCountryCode != expectedCountryCode) {
          return ServiceResult.failure(
            'Phone number country mismatch',
            ServiceException(
              'Phone number does not match selected country (${expectedCountryCode.countryDisplayName})',
              ServiceErrorType.validation,
            ),
          );
        }
      } catch (e) {
        // Phone number creation failed, but we already validated format above
        // This should not happen, but provide fallback error
        return ServiceResult.failure(
          'Phone number validation error',
          ServiceException(
            'Unable to validate phone number format',
            ServiceErrorType.validation,
            e,
          ),
        );
      }
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
