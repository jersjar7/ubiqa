// lib/services/3_datasources/features/auth/auth_api_datasource.dart

// Import horizontal foundation - domain entities
import '../../../../models/1_domain/shared/entities/user.dart';

// Import horizontal foundation - value objects
import 'package:ubiqa/models/1_domain/shared/value_objects/contact_info.dart';
import 'package:ubiqa/models/1_domain/shared/value_objects/international_phone_number.dart';

// Import horizontal foundation - infrastructure
import 'package:ubiqa/services/4_infrastructure/shared/service_result.dart';
import '../../../4_infrastructure/firebase/firebase_auth_service.dart';

/// Authentication API data source
///
/// Handles authentication operations through Firebase Auth infrastructure.
/// Thin wrapper around FirebaseAuthService that follows datasource patterns.
/// Returns ServiceResult for consistent error handling.
///
/// Updated: Now supports international phone numbers with country code context
class AuthApiDataSource {
  final FirebaseAuthService _firebaseAuthService;

  AuthApiDataSource(this._firebaseAuthService);

  /// Register new user with Firebase Auth
  /// Supports international phone numbers for Peru and US markets
  Future<ServiceResult<User>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    SupportedCountryCode? countryCode,
  }) async {
    return await _firebaseAuthService.registerWithEmailAndPassword(
      email: email,
      password: password,
      displayName: fullName,
      countryCode: countryCode,
    );
  }

  /// Sign in user with Firebase Auth
  Future<ServiceResult<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out from Firebase Auth
  Future<ServiceResult<void>> signOut() async {
    return await _firebaseAuthService.signOut();
  }

  /// Get current authenticated user from Firebase Auth
  Future<ServiceResult<User?>> getCurrentUser() async {
    return await _firebaseAuthService.getCurrentUser();
  }

  /// Update user profile through Firebase services
  /// Supports international phone number updates
  Future<ServiceResult<User>> updateUserProfile({
    required User currentUser,
    String? fullName,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? profileImageUrl,
  }) async {
    return await _firebaseAuthService.updateUserProfile(
      currentUser: currentUser,
      name: fullName,
      phoneNumber: phoneNumber,
      preferredContactHours: preferredContactHours,
      profileImageUrl: profileImageUrl,
    );
  }

  /// Send phone verification code via Firebase Auth
  /// Phone number should be in international format
  Future<ServiceResult<void>> sendPhoneVerificationCode({
    required String phoneNumber,
  }) async {
    return await _firebaseAuthService.sendPhoneVerificationCode(
      phoneNumber: phoneNumber,
    );
  }

  /// Verify phone number with Firebase Auth
  /// Phone number should be in international format
  Future<ServiceResult<User>> verifyPhoneNumber({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    return await _firebaseAuthService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCode: verificationCode,
    );
  }

  /// Request password reset through Firebase Auth
  Future<ServiceResult<void>> requestPasswordReset({
    required String email,
  }) async {
    return await _firebaseAuthService.sendPasswordResetEmail(email);
  }

  /// Check email registration status via Firebase Auth
  Future<ServiceResult<bool>> isEmailRegistered({required String email}) async {
    return await _firebaseAuthService.isEmailRegistered(email: email);
  }

  /// Delete user account through Firebase Auth
  Future<ServiceResult<void>> deleteUserAccount({required User user}) async {
    return await _firebaseAuthService.deleteUserAccount(user: user);
  }
}
