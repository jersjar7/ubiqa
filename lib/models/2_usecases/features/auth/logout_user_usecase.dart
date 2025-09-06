// lib/models/2_usecases/features/auth/logout_user_usecase.dart

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Logout User Use Case
///
/// Handles user sign-out operations.
/// Clears authentication state and applies cleanup logic.
/// Used by presentation layer for logout operations.
class LogoutUserUseCase {
  final IAuthRepository _authRepository;

  LogoutUserUseCase(this._authRepository);

  /// Execute user logout
  ///
  /// Signs out current user and applies cleanup logic.
  /// Returns success or error details on failure.
  Future<ServiceResult<void>> execute() async {
    try {
      // Apply pre-logout use case logic
      await _applyPreLogoutLogic();

      // Execute logout through repository
      final logoutResult = await _authRepository.signOut();

      if (!logoutResult.isSuccess) {
        return _mapLogoutError(logoutResult);
      }

      // Apply post-logout use case logic
      await _applyPostLogoutLogic();

      return ServiceResult.successVoid();
    } catch (e) {
      return ServiceResult.failure(
        'Logout execution failed',
        ServiceException(
          'Unexpected logout error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<void> _mapLogoutError(ServiceResult<void> repositoryResult) {
    // Map repository errors to user-friendly messages
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error during logout',
          ServiceException(
            'Logout completed locally. Some data may sync when connection returns.',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Logout authentication issue',
          ServiceException(
            'User already signed out',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'Logout failed',
          ServiceException(
            'Something went wrong during logout. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: Pre/post logout business logic

  Future<void> _applyPreLogoutLogic() async {
    // Apply use case specific pre-logout logic
    // Example: save pending data, clear sensitive caches, log logout event

    // TODO: Will be filled when UI requirements are clear
  }

  Future<void> _applyPostLogoutLogic() async {
    // Apply use case specific post-logout logic
    // Example: clear local storage, reset app state, navigate to login

    // TODO: Will be filled when UI requirements are clear
  }
}
