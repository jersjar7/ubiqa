// lib/services/4_infrastructure/auth/apple_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import domain entities and services
import '../../../models/1_domain/shared/entities/user.dart' as domain;

// Import shared infrastructure
import '../shared/service_result.dart';

/// Apple Authentication Service
class AppleAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AppleAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sign in with Apple
  Future<ServiceResult<domain.User>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider("apple.com")
          .credential(
            idToken: credential.identityToken,
            accessToken: credential.authorizationCode,
          );

      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      if (userCredential.user == null) {
        return ServiceResult.failure(
          'Authentication failed',
          ServiceException(
            'Firebase returned null user after Apple sign-in',
            ServiceErrorType.authentication,
          ),
        );
      }

      // Build display name from Apple credential
      String? displayName;
      if (credential.givenName != null || credential.familyName != null) {
        displayName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
        if (displayName.isEmpty) displayName = null;
      }

      final user = domain.UserDomainService.createFromFirebaseWithValidation(
        firebaseUid: userCredential.user!.uid,
        email: userCredential.user!.email ?? credential.email ?? '',
        displayName: displayName ?? userCredential.user!.displayName,
      );

      // Ensure user exists in Firestore
      final persistResult = await _ensureUserInFirestore(user);
      if (!persistResult.isSuccess) {
        print(
          'Warning: Failed to save user profile: ${persistResult.getErrorMessage()}',
        );
      }

      return ServiceResult.success(user);
    } on SignInWithAppleAuthorizationException catch (e) {
      return ServiceResult.failure(
        'Apple sign-in failed',
        ServiceException(
          'Apple authorization error: ${e.message}',
          ServiceErrorType.authentication,
          e,
        ),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      return ServiceResult.failure(
        'Apple sign-in failed',
        _mapFirebaseAuthException(e),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Apple sign-in error',
        ServiceException(
          'Unexpected error during Apple sign-in: ${e.toString()}',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  /// Ensure user exists in Firestore
  Future<ServiceResult<void>> _ensureUserInFirestore(domain.User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.id.value);

      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'email': user.email,
          'name': user.name,
          'createdAt': user.createdAt.toIso8601String(),
          'updatedAt': user.updatedAt.toIso8601String(),
          'isActive': user.isActive,
          'registrationCountryCode': 'peru',
        });
      }

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to persist user',
        ServiceException(
          'Error saving user to Firestore: ${e.toString()}',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  ServiceException _mapFirebaseAuthException(
    firebase_auth.FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return ServiceException(
          'An account with this email already exists with different credentials',
          ServiceErrorType.authentication,
          e,
        );
      case 'invalid-credential':
        return ServiceException(
          'Invalid Apple credentials',
          ServiceErrorType.authentication,
          e,
        );
      case 'operation-not-allowed':
        return ServiceException(
          'Apple sign-in is not enabled',
          ServiceErrorType.configuration,
          e,
        );
      default:
        return ServiceException(
          'Firebase Auth error: ${e.message ?? e.code}',
          ServiceErrorType.unknown,
          e,
        );
    }
  }
}
