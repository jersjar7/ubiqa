// lib/services/1_contracts/features/auth/auth_repository.dart

// Import horizontal foundation - domain entities
import 'package:ubiqa/models/1_domain/shared/entities/user.dart';

// Import horizontal foundation - value objects
import 'package:ubiqa/models/1_domain/shared/value_objects/contact_info.dart';

// Import horizontal foundation - infrastructure
import 'package:ubiqa/services/4_infrastructure/shared/service_result.dart';

/// Authentication repository contract
///
/// Defines authentication operations without implementation details.
/// Implemented by coordinators layer, used by use cases layer.
/// Uses ServiceResult for consistent error handling across all auth operations.
abstract class IAuthRepository {
  /// Register new user with email and password
  /// Creates user profile following domain validation rules
  Future<ServiceResult<User>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
  });

  /// Sign in existing user with email and password
  /// Returns user with current profile state
  Future<ServiceResult<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out current authenticated user
  /// Clears local authentication state
  Future<ServiceResult<void>> signOut();

  /// Get currently authenticated user if available
  /// Returns null if no user is signed in
  Future<ServiceResult<User?>> getCurrentUser();

  /// Update user profile information
  /// Validates updates against domain rules before persisting
  Future<ServiceResult<User>> updateUserProfile({
    required User currentUser,
    String? fullName,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? profileImageUrl,
  });

  /// Send phone verification code to user
  /// Required for user verification in Peru market
  Future<ServiceResult<void>> sendPhoneVerificationCode({
    required String phoneNumber,
  });

  /// Verify phone number with received code
  /// Marks user as verified enabling full platform features
  Future<ServiceResult<User>> verifyPhoneNumber({
    required String phoneNumber,
    required String verificationCode,
  });

  /// Request password reset email
  /// Initiates Firebase password reset flow
  Future<ServiceResult<void>> requestPasswordReset({required String email});

  /// Check if email is already registered
  /// Useful for registration flow UX
  Future<ServiceResult<bool>> isEmailRegistered({required String email});

  /// Delete user account and all associated data
  /// Permanent operation - requires user confirmation
  Future<ServiceResult<void>> deleteUserAccount({required User user});
}
