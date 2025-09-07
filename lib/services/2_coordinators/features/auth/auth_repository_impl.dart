// lib/services/2_coordinators/features/auth/auth_repository_impl.dart

// Import horizontal foundation - domain entities
import '../../../../models/1_domain/shared/entities/user.dart';

// Import horizontal foundation - value objects
import '../../../../models/1_domain/shared/value_objects/contact_info.dart';
import '../../../../models/1_domain/shared/value_objects/international_phone_number.dart';

// Import horizontal foundation - infrastructure
import '../../../4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../1_contracts/features/auth/auth_repository.dart';

// Import feature datasources
import '../../../3_datasources/features/auth/auth_api_datasource.dart';

/// Authentication repository implementation
///
/// Coordinates authentication operations between datasources and domain layer.
/// Implements business rules and domain validation for auth operations.
/// Updated: Now handles international phone numbers for Peru and US markets.
class AuthRepositoryImpl implements IAuthRepository {
  final AuthApiDataSource _authDataSource;

  AuthRepositoryImpl(this._authDataSource);

  @override
  Future<ServiceResult<User>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    SupportedCountryCode? countryCode,
  }) async {
    try {
      // Validate registration inputs according to domain rules
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

      // Delegate to datasource for registration
      final registrationResult = await _authDataSource
          .registerWithEmailAndPassword(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber,
            countryCode: countryCode,
          );

      if (!registrationResult.isSuccess) {
        return registrationResult;
      }

      // Apply post-registration business logic
      final user = registrationResult.data!;
      final processedUser = _applyPostRegistrationLogic(user);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Registration coordination failed',
        ServiceException(
          'Unexpected registration error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate sign-in inputs
      final validationResult = _validateSignInInputs(
        email: email,
        password: password,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Sign-in validation failed',
          validationResult.exception!,
        );
      }

      // Delegate to datasource for authentication
      final signInResult = await _authDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!signInResult.isSuccess) {
        return signInResult;
      }

      // Apply post-authentication business logic
      final user = signInResult.data!;
      final processedUser = _applyPostAuthenticationLogic(user);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Sign-in coordination failed',
        ServiceException(
          'Unexpected sign-in error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<void>> signOut() async {
    try {
      // Apply pre-signout business logic if needed
      _applyPreSignOutLogic();

      // Delegate to datasource
      return await _authDataSource.signOut();
    } catch (e) {
      return ServiceResult.failure(
        'Sign-out coordination failed',
        ServiceException(
          'Unexpected sign-out error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<User?>> getCurrentUser() async {
    try {
      return await _authDataSource.getCurrentUser();
    } catch (e) {
      return ServiceResult.failure(
        'Get current user failed',
        ServiceException(
          'Unexpected user retrieval error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<User>> updateUserProfile({
    required User currentUser,
    String? fullName,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? profileImageUrl,
  }) async {
    try {
      // Validate profile update according to domain rules
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

      // Delegate to datasource
      final updateResult = await _authDataSource.updateUserProfile(
        currentUser: currentUser,
        fullName: fullName,
        phoneNumber: phoneNumber,
        preferredContactHours: preferredContactHours,
        profileImageUrl: profileImageUrl,
      );

      if (!updateResult.isSuccess) {
        return updateResult;
      }

      // Apply post-update business logic
      final updatedUser = updateResult.data!;
      final processedUser = _applyPostProfileUpdateLogic(updatedUser);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Profile update coordination failed',
        ServiceException(
          'Unexpected profile update error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<void>> sendPhoneVerificationCode({
    required String phoneNumber,
  }) async {
    try {
      // Validate international phone number format
      final validationResult = _validateInternationalPhoneNumber(phoneNumber);

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Phone number validation failed',
          validationResult.exception!,
        );
      }

      // Delegate to datasource
      return await _authDataSource.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      return ServiceResult.failure(
        'Phone verification initiation failed',
        ServiceException(
          'Unexpected phone verification error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<User>> verifyPhoneNumber({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      // Validate verification inputs
      final validationResult = _validatePhoneVerificationInputs(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Phone verification validation failed',
          validationResult.exception!,
        );
      }

      // Delegate to datasource
      final verificationResult = await _authDataSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      );

      if (!verificationResult.isSuccess) {
        return verificationResult;
      }

      // Apply post-verification business logic
      final verifiedUser = verificationResult.data!;
      final processedUser = _applyPostPhoneVerificationLogic(verifiedUser);

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Phone verification coordination failed',
        ServiceException(
          'Unexpected phone verification error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<void>> requestPasswordReset({
    required String email,
  }) async {
    try {
      // Validate email format
      final validationResult = _validateEmailFormat(email);

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Email validation failed',
          validationResult.exception!,
        );
      }

      // Delegate to datasource
      return await _authDataSource.requestPasswordReset(email: email);
    } catch (e) {
      return ServiceResult.failure(
        'Password reset coordination failed',
        ServiceException(
          'Unexpected password reset error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<bool>> isEmailRegistered({required String email}) async {
    try {
      // Validate email format
      final validationResult = _validateEmailFormat(email);

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Email validation failed',
          validationResult.exception!,
        );
      }

      // Delegate to datasource
      return await _authDataSource.isEmailRegistered(email: email);
    } catch (e) {
      return ServiceResult.failure(
        'Email check coordination failed',
        ServiceException(
          'Unexpected email check error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  @override
  Future<ServiceResult<void>> deleteUserAccount({required User user}) async {
    try {
      // Apply pre-deletion business logic
      final validationResult = _validateAccountDeletion(user);

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Account deletion validation failed',
          validationResult.exception!,
        );
      }

      // Apply pre-deletion cleanup
      await _applyPreAccountDeletionLogic(user);

      // Delegate to datasource
      return await _authDataSource.deleteUserAccount(user: user);
    } catch (e) {
      return ServiceResult.failure(
        'Account deletion coordination failed',
        ServiceException(
          'Unexpected account deletion error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Domain validation methods

  ServiceResult<void> _validateRegistrationInputs({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    SupportedCountryCode? countryCode,
  }) {
    // Email validation
    final emailValidation = _validateEmailFormat(email);
    if (!emailValidation.isSuccess) return emailValidation;

    // Password validation
    final passwordValidation = _validatePasswordStrength(password);
    if (!passwordValidation.isSuccess) return passwordValidation;

    // International phone number validation if provided
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final phoneValidation = _validateInternationalPhoneNumber(
        phoneNumber,
        expectedCountryCode: countryCode,
      );
      if (!phoneValidation.isSuccess) return phoneValidation;
    }

    return ServiceResult.success(null);
  }

  ServiceResult<void> _validateSignInInputs({
    required String email,
    required String password,
  }) {
    // Email validation
    final emailValidation = _validateEmailFormat(email);
    if (!emailValidation.isSuccess) return emailValidation;

    // Basic password presence check
    if (password.trim().isEmpty) {
      return ServiceResult.failure(
        'Password required',
        ServiceException(
          'Password cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    return ServiceResult.success(null);
  }

  ServiceResult<void> _validateProfileUpdateInputs({
    required User currentUser,
    String? fullName,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? profileImageUrl,
  }) {
    // Validate phone number if provided using international validation
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final phoneValidation = _validateInternationalPhoneNumber(phoneNumber);
      if (!phoneValidation.isSuccess) return phoneValidation;
    }

    // Validate profile image URL if provided
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      final imageValidation = _validateImageUrl(profileImageUrl);
      if (!imageValidation.isSuccess) return imageValidation;
    }

    return ServiceResult.success(null);
  }

  ServiceResult<void> _validatePhoneVerificationInputs({
    required String phoneNumber,
    required String verificationCode,
  }) {
    // International phone number validation
    final phoneValidation = _validateInternationalPhoneNumber(phoneNumber);
    if (!phoneValidation.isSuccess) return phoneValidation;

    // Verification code validation
    if (verificationCode.trim().isEmpty || verificationCode.length < 4) {
      return ServiceResult.failure(
        'Invalid verification code',
        ServiceException(
          'Verification code must be at least 4 characters',
          ServiceErrorType.validation,
        ),
      );
    }

    return ServiceResult.success(null);
  }

  ServiceResult<void> _validateEmailFormat(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ServiceResult.failure(
        'Invalid email format',
        ServiceException(
          'Email must be in valid format',
          ServiceErrorType.validation,
        ),
      );
    }
    return ServiceResult.success(null);
  }

  ServiceResult<void> _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return ServiceResult.failure(
        'Password too weak',
        ServiceException(
          'Password must be at least 8 characters',
          ServiceErrorType.validation,
        ),
      );
    }
    return ServiceResult.success(null);
  }

  ServiceResult<void> _validateInternationalPhoneNumber(
    String phoneNumber, {
    SupportedCountryCode? expectedCountryCode,
  }) {
    // Use domain service for international phone validation
    if (!InternationalPhoneNumberDomainService.isValidInternationalPhoneNumber(
      phoneNumber,
    )) {
      String errorMessage = 'Phone number must be in international format';

      // Provide country-specific guidance if expected country is known
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
        'Invalid phone number format',
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
      } on InternationalPhoneNumberValidationException catch (e) {
        return ServiceResult.failure(
          'Phone number validation error',
          ServiceException(
            e.violations.join(', '),
            ServiceErrorType.validation,
            e,
          ),
        );
      }
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

  ServiceResult<void> _validateAccountDeletion(User user) {
    // Basic validation - user must be active
    if (!user.isActive) {
      return ServiceResult.failure(
        'Account already inactive',
        ServiceException(
          'Cannot delete inactive account',
          ServiceErrorType.business,
        ),
      );
    }

    // TODO: Future: Check for active listings or pending payments
    // This will coordinate with other features when implemented
    return ServiceResult.success(null);
  }

  // PRIVATE: Business logic methods

  User _applyPostRegistrationLogic(User user) {
    // Mark user as new for UI onboarding flows
    // Profile completeness is already calculated by User entity
    return user;
  }

  User _applyPostAuthenticationLogic(User user) {
    // Validate account is still active
    if (!user.isActive) {
      throw ServiceException(
        'Account is deactivated',
        ServiceErrorType.business,
      );
    }

    // Return user - session tracking handled by infrastructure
    return user;
  }

  void _applyPreSignOutLogic() {
    // Clear any cached sensitive data
    // Infrastructure layer handles Firebase sign out
    // TODO: Future: Save pending draft data, clear secure storage
  }

  User _applyPostProfileUpdateLogic(User user) {
    // User entity already recalculates profile completeness
    // TODO: Future: Send analytics event, check verification status changes
    return user;
  }

  User _applyPostPhoneVerificationLogic(User user) {
    // User is now verified and can access full platform features
    // User.isVerified() method handles verification logic

    // TODO: Future: Send welcome notification, unlock listing creation
    return user;
  }

  Future<void> _applyPreAccountDeletionLogic(User user) async {
    // TODO: Future: Archive user data, cancel any active listings
    // TODO: Future: Notify related services about account deletion
    // For now, basic validation is sufficient
  }
}
