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
      print('DEBUG: Use case - validating inputs');
      final validationResult = await _validateRegistrationInputs(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
      );

      if (!validationResult.isSuccess) {
        print(
          'DEBUG: Use case validation failed: ${validationResult.exception}',
        );
        return ServiceResult<User>.failure(
          validationResult.exception!.message,
          validationResult.exception!,
        );
      }

      // Execute registration through repository
      print('DEBUG: Use case - calling repository');
      final registrationResult = await _authRepository
          .registerWithEmailAndPassword(
            email: email.trim(),
            password: password,
            fullName: fullName?.trim(),
            phoneNumber: phoneNumber?.trim(),
            countryCode: countryCode,
          );

      print(
        'DEBUG: Repository result - Success: ${registrationResult.isSuccess}',
      );
      if (!registrationResult.isSuccess) {
        print('DEBUG: Repository error: ${registrationResult.exception}');
        return _mapRegistrationError(registrationResult);
      }

      // Apply post-registration use case logic
      final user = registrationResult.data!;
      final processedUser = _applyPostRegistrationLogic(user);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Ejecución del registro falló',
        ServiceException(
          'Error inesperado de registro',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  Future<ServiceResult<void>> _validateRegistrationInputs({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    SupportedCountryCode? countryCode,
  }) async {
    // Check email presence and format
    if (email.trim().isEmpty) {
      return ServiceResult.failure(
        'Correo electrónico requerido',
        ServiceException(
          'El correo electrónico no puede estar vacío',
          ServiceErrorType.validation,
        ),
      );
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ServiceResult.failure(
        'Formato de correo electrónico inválido',
        ServiceException(
          'Por favor ingresa un correo electrónico válido',
          ServiceErrorType.validation,
        ),
      );
    }

    // Check password presence and strength
    if (password.trim().isEmpty) {
      return ServiceResult.failure(
        'Contraseña requerida',
        ServiceException(
          'La contraseña no puede estar vacía',
          ServiceErrorType.validation,
        ),
      );
    }

    if (password.length < 8) {
      return ServiceResult.failure(
        'Contraseña muy débil',
        ServiceException(
          'La contraseña debe tener al menos 8 caracteres',
          ServiceErrorType.validation,
        ),
      );
    }

    // Validate full name if provided
    if (fullName != null && fullName.trim().isNotEmpty) {
      if (fullName.trim().length < 2) {
        return ServiceResult.failure(
          'Nombre inválido',
          ServiceException(
            'El nombre debe tener al menos 2 caracteres',
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

      // Check for duplicate phone number
      print('DEBUG: Checking phone duplicate for: ${phoneNumber.trim()}');
      final phoneCheckResult = await _authRepository.isPhoneNumberRegistered(
        phoneNumber: phoneNumber.trim(),
      );
      print(
        'DEBUG: Phone check result - exists: ${phoneCheckResult.data}, success: ${phoneCheckResult.isSuccess}',
      );

      if (!phoneCheckResult.isSuccess) {
        return ServiceResult.failure(
          'Verificación de teléfono falló',
          phoneCheckResult.exception!,
        );
      }

      if (phoneCheckResult.data == true) {
        return ServiceResult.failure(
          'Número de teléfono ya registrado',
          ServiceException(
            'Este número de teléfono ya está en uso. Por favor usa un número diferente.',
            ServiceErrorType.validation,
          ),
        );
      }
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
      String errorMessage =
          'El número de teléfono debe estar en formato internacional';

      // Provide country-specific guidance
      if (expectedCountryCode != null) {
        final example =
            InternationalPhoneNumberDomainService.getFormatExampleForCountry(
              expectedCountryCode,
            );
        errorMessage += ' (ejemplo: $example)';
      } else {
        errorMessage +=
            ' (+51XXXXXXXXX para Perú, +1XXXXXXXXXX para Estados Unidos)';
      }

      return ServiceResult.failure(
        'Número de teléfono inválido',
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
            'El país del número de teléfono no coincide',
            ServiceException(
              'El número de teléfono no coincide con el país seleccionado (${expectedCountryCode.countryDisplayName})',
              ServiceErrorType.validation,
            ),
          );
        }
      } catch (e) {
        // Phone number creation failed, but we already validated format above
        // This should not happen, but provide fallback error
        return ServiceResult.failure(
          'Error de validación del número de teléfono',
          ServiceException(
            'No se pudo validar el formato del número de teléfono',
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
          'Correo electrónico ya registrado',
          ServiceException(
            'Este correo electrónico ya está en uso. Por favor intenta iniciar sesión en su lugar.',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Error de conexión',
          ServiceException(
            'Por favor verifica tu conexión a internet e intenta de nuevo',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.validation:
        return ServiceResult.failure(
          'Validación de registro falló',
          ServiceException(
            'Por favor verifica tu información e intenta de nuevo',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.business:
        return ServiceResult.failure(
          'Registro no permitido',
          ServiceException(
            'El registro está temporalmente no disponible. Por favor intenta más tarde.',
            ServiceErrorType.business,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Registro falló',
          ServiceException(
            'Algo salió mal. Por favor intenta de nuevo.',
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
