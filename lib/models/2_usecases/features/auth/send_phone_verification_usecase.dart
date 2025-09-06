// lib/models/2_usecases/features/auth/send_phone_verification_usecase.dart

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';
import '../../../1_domain/shared/value_objects/international_phone_number.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Send Phone Verification Use Case
///
/// Initiates phone number verification for international markets.
/// Validates phone format and sends verification code via SMS.
/// Used by presentation layer for phone verification flow.
class SendPhoneVerificationUseCase {
  final IAuthRepository _authRepository;

  SendPhoneVerificationUseCase(this._authRepository);

  /// Execute phone verification code sending
  ///
  /// Validates international phone number and sends verification code.
  /// Returns success or error details on failure.
  Future<ServiceResult<void>> execute({required String phoneNumber}) async {
    try {
      // Validate use case inputs
      final validationResult = _validatePhoneVerificationInputs(
        phoneNumber: phoneNumber,
      );

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Phone verification validation failed',
          validationResult.exception!,
        );
      }

      // Apply pre-verification use case logic
      await _applyPreVerificationLogic(phoneNumber.trim());

      // Execute verification through repository
      final verificationResult = await _authRepository
          .sendPhoneVerificationCode(phoneNumber: phoneNumber.trim());

      if (!verificationResult.isSuccess) {
        return _mapVerificationError(verificationResult);
      }

      // Apply post-verification initiation logic
      await _applyPostVerificationInitiationLogic(phoneNumber.trim());

      return ServiceResult.successVoid();
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

  ServiceResult<void> _validatePhoneVerificationInputs({
    required String phoneNumber,
  }) {
    // Check phone number presence
    if (phoneNumber.trim().isEmpty) {
      return ServiceResult.failure(
        'Phone number required',
        ServiceException(
          'Phone number cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    // Validate international phone number format
    return _validateInternationalPhoneNumber(phoneNumber.trim());
  }

  ServiceResult<void> _validateInternationalPhoneNumber(String phoneNumber) {
    if (!InternationalPhoneNumberDomainService.isValidInternationalPhoneNumber(
      phoneNumber,
    )) {
      return ServiceResult.failure(
        'Invalid phone number',
        ServiceException(
          'Phone number must be in format +1XXXXXXXXXX (US) or +51XXXXXXXXX (Peru)',
          ServiceErrorType.validation,
        ),
      );
    }
    return ServiceResult.success(null);
  }

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<void> _mapVerificationError(
    ServiceResult<void> repositoryResult,
  ) {
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Authentication required',
          ServiceException(
            'Please sign in to verify your phone number',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error',
          ServiceException(
            'Unable to send verification code. Please check your connection.',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.validation:
        return ServiceResult.failure(
          'Phone number validation failed',
          ServiceException(
            'Invalid phone number format',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.serviceUnavailable:
        return ServiceResult.failure(
          'SMS service unavailable',
          ServiceException(
            'SMS verification service is temporarily unavailable. Please try again later.',
            ServiceErrorType.serviceUnavailable,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.business:
        return ServiceResult.failure(
          'Verification limit reached',
          ServiceException(
            'Too many verification attempts. Please wait before trying again.',
            ServiceErrorType.business,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Verification failed',
          ServiceException(
            'Unable to send verification code. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Pre/post verification business logic

  Future<void> _applyPreVerificationLogic(String phoneNumber) async {
    // Apply use case specific pre-verification logic
    // Example: check rate limits, log verification attempt, validate user eligibility

    // TODO: Will be filled when UI requirements are clear
  }

  Future<void> _applyPostVerificationInitiationLogic(String phoneNumber) async {
    // Apply use case specific post-verification initiation logic
    // Example: start verification timeout, update user state, send analytics event

    // TODO: Will be filled when UI requirements are clear
  }
}
