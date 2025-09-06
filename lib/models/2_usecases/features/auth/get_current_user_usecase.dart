// lib/models/2_usecases/features/auth/get_current_user_usecase.dart

// Import horizontal foundation - domain entities
import '../../../1_domain/shared/entities/user.dart';

// Import horizontal foundation - infrastructure
import '../../../../services/4_infrastructure/shared/service_result.dart';

// Import feature contracts
import '../../../../services/1_contracts/features/auth/auth_repository.dart';

/// Get Current User Use Case
///
/// Retrieves currently authenticated user if available.
/// Used by presentation layer to check authentication status.
class GetCurrentUserUseCase {
  final IAuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  /// Execute current user retrieval
  ///
  /// Returns current user or null if not authenticated.
  Future<ServiceResult<User?>> execute() async {
    try {
      // Get current user through repository
      final currentUserResult = await _authRepository.getCurrentUser();

      if (!currentUserResult.isSuccess) {
        return _mapCurrentUserError(currentUserResult);
      }

      // Apply user processing logic
      final user = currentUserResult.data;
      final processedUser = user != null
          ? _applyUserProcessingLogic(user)
          : null;

      return ServiceResult.success(processedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Get current user execution failed',
        ServiceException(
          'Unexpected user retrieval error',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE: Error mapping for presentation layer

  ServiceResult<User?> _mapCurrentUserError(
    ServiceResult<User?> repositoryResult,
  ) {
    // Map repository errors to user-friendly messages
    final originalError = repositoryResult.exception!;

    switch (originalError.type) {
      case ServiceErrorType.network:
        return ServiceResult.failure(
          'Connection error',
          ServiceException(
            'Unable to verify authentication status. Please check your connection.',
            ServiceErrorType.network,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.authentication:
        return ServiceResult.failure(
          'Authentication expired',
          ServiceException(
            'Your session has expired. Please sign in again.',
            ServiceErrorType.authentication,
            originalError.originalError,
          ),
        );

      case ServiceErrorType.configuration:
        return ServiceResult.failure(
          'Configuration error',
          ServiceException(
            'Authentication service unavailable. Please try again later.',
            ServiceErrorType.configuration,
            originalError.originalError,
          ),
        );

      default:
        return ServiceResult.failure(
          'User retrieval failed',
          ServiceException(
            'Unable to check authentication status. Please try again.',
            ServiceErrorType.unknown,
            originalError.originalError,
          ),
        );
    }
  }

  // PRIVATE: User processing business logic

  User _applyUserProcessingLogic(User user) {
    // Apply use case specific user processing logic
    // Example: check account status, validate permissions, update last seen

    // TODO: Will be filled when UI requirements are clear
    return user;
  }
}
