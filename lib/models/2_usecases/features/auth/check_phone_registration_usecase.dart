// lib/models/2_usecases/features/auth/check_phone_registration_usecase.dart

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import horizontal foundation - value objects
import '../../../1_domain/shared/value_objects/international_phone_number.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Check Phone Registration Use Case
///
/// Verifies if phone number is already registered.
/// Prevents duplicate WhatsApp contact information in the system.
class CheckPhoneRegistrationUseCase {
  final IAuthRepository _authRepository;

  CheckPhoneRegistrationUseCase(this._authRepository);

  /// Execute phone registration check
  ///
  /// Returns true if phone is registered, false if available.
  Future<ServiceResult<bool>> execute({required String phoneNumber}) async {
    try {
      // Validate phone number format
      if (!InternationalPhoneNumberDomainService.isValidInternationalPhoneNumber(
        phoneNumber,
      )) {
        return ServiceResult.failure(
          'Invalid phone format',
          ServiceException(
            'Phone number must be in international format',
            ServiceErrorType.validation,
          ),
        );
      }

      // Execute phone check through repository
      final checkResult = await _authRepository.isPhoneNumberRegistered(
        phoneNumber: phoneNumber.trim(),
      );

      return checkResult;
    } catch (e) {
      return ServiceResult.failure(
        'Phone check failed',
        ServiceException(
          'Unable to verify phone availability',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }
}
