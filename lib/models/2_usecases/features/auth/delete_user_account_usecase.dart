// lib/models/2_usecases/features/auth/delete_user_account_usecase.dart

// Import horizontal foundation - domain entities
import '../../../1_domain/shared/entities/user.dart';

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Delete User Account Use Case
///
/// Handles permanent user account deletion.
/// Validates deletion eligibility and applies cleanup logic.
/// Used by presentation layer for account deletion operations.
class DeleteUserAccountUseCase {
  final IAuthRepository _authRepository;

  DeleteUserAccountUseCase(this._authRepository);

  /// Execute user account deletion
  ///
  /// Validates deletion eligibility and permanently deletes account.
  /// Returns success or error details on failure.
  Future<ServiceResult<void>> execute({required User user}) async {
    try {
      // Validate use case inputs
      final validationResult = _validateAccountDeletionInputs(user: user);

      if (!validationResult.isSuccess) {
        return ServiceResult.failure(
          'Account deletion validation failed',
          validationResult.exception!,
        );
      }

      // Apply pre-deletion use case logic
      await _applyPreDeletionLogic(user);

      // Execute account deletion through repository
      final deletionResult = await _authRepository.deleteUserAccount(
        user: user,
      );

      if (!deletionResult.isSuccess) {
        return _mapAccountDeletionError(deletionResult);
      }

      // Apply post-deletion use case logic
      await _applyPostDeletionLogic(user);

      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Account deletion execution failed',
        ServiceException(
          'Unexpected account deletion error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Input validation

  ServiceResult<void> _validateAccountDeletionInputs({required User user}) {
    // Check if user is valid
    if (user.id.value.isEmpty) {
      return ServiceResult.failure(
        'Invalid user',
        ServiceException(
          'User ID cannot be empty',
          ServiceErrorType.validation,
        ),
      );
    }

    // Check if user is active
    if (!user.isActive) {
      return ServiceResult.failure(
        'Account already inactive',
        ServiceException(
          'User account is already inactive',
          ServiceErrorType.business,
        ),
      );
    }

    // Additional business rule validations would go here
    // Example: check for active listings, pending payments, etc.

    return ServiceResult.success(null);
  }

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<void> _mapAccountDeletionError(
    ServiceResult<void> repositoryResult,
  ) {
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Authentication required',
          ServiceException(
            'Please sign in again to delete your account',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error',
          ServiceException(
            'Unable to delete account. Please check your connection.',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.business:
        return ServiceResult.failure(
          'Deletion not allowed',
          ServiceException(
            'Account cannot be deleted due to active commitments',
            ServiceErrorType.business,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.validation:
        return ServiceResult.failure(
          'Account validation failed',
          ServiceException(
            'Unable to validate account for deletion',
            ServiceErrorType.validation,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Account deletion failed',
          ServiceException(
            'Unable to delete account. Please contact support.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Pre/post deletion business logic

  Future<void> _applyPreDeletionLogic(User user) async {
    // Apply use case specific pre-deletion logic
    // Example: backup user data, cancel subscriptions, notify related services

    // Will be filled when UI requirements are clear
  }

  Future<void> _applyPostDeletionLogic(User user) async {
    // Apply use case specific post-deletion logic
    // Example: send confirmation email, log deletion event, clear local cache

    // Will be filled when UI requirements are clear
  }
}
