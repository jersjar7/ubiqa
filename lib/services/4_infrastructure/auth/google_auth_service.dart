// lib/services/4_infrastructure/auth/google_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import domain entities and services
import '../../../models/1_domain/shared/entities/user.dart' as domain;

// Import shared infrastructure
import '../shared/service_result.dart';

/// Google Authentication Service
///
/// Handles Google Sign-In integration with Firebase Auth.
/// Uses google_sign_in v6 pattern (downgrade from v7+).
class GoogleAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  GoogleAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Sign in with Google using v6 pattern
  Future<ServiceResult<domain.User>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return ServiceResult.failure(
          'Sign in cancelled',
          ServiceException(
            'Google sign-in was cancelled by user',
            ServiceErrorType.authentication,
          ),
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        return ServiceResult.failure(
          'Authentication failed',
          ServiceException(
            'Firebase returned null user after Google sign-in',
            ServiceErrorType.authentication,
          ),
        );
      }

      // Convert to domain User entity
      final user = domain.UserDomainService.createFromFirebaseWithValidation(
        firebaseUid: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        displayName: userCredential.user!.displayName,
      );

      // Check if user exists in Firestore, create if not
      final persistResult = await _ensureUserInFirestore(user);
      if (!persistResult.isSuccess) {
        // User authenticated but profile not saved - this could be non-critical
        // Log error but don't fail the sign-in
        print(
          'Warning: Failed to save user profile: ${persistResult.getErrorMessage()}',
        );
      }

      return ServiceResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return ServiceResult.failure(
        'Google sign-in failed',
        _mapFirebaseAuthException(e),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Google sign-in error',
        ServiceException(
          'Unexpected error during Google sign-in: ${e.toString()}',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  /// Sign out from Google and Firebase
  Future<ServiceResult<void>> signOut() async {
    try {
      await Future.wait([_googleSignIn.signOut(), _firebaseAuth.signOut()]);

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Sign out failed',
        ServiceException(
          'Error during sign out: ${e.toString()}',
          ServiceErrorType.unknown,
          e,
        ),
      );
    }
  }

  // PRIVATE HELPERS

  /// Ensure user exists in Firestore, create if missing
  Future<ServiceResult<void>> _ensureUserInFirestore(domain.User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.id.value);

      // Check if user already exists
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        // Create new user document for Google sign-in users
        await userDoc.set({
          'email': user.email,
          'name': user.name,
          'createdAt': user.createdAt.toIso8601String(),
          'updatedAt': user.updatedAt.toIso8601String(),
          'isActive': user.isActive,
          'registrationCountryCode': 'peru', // Default for Google users
          // contactInfo will be null initially - collected later when needed
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
          'Invalid Google credentials',
          ServiceErrorType.authentication,
          e,
        );
      case 'operation-not-allowed':
        return ServiceException(
          'Google sign-in is not enabled',
          ServiceErrorType.configuration,
          e,
        );
      case 'user-disabled':
        return ServiceException(
          'This account has been disabled',
          ServiceErrorType.authentication,
          e,
        );
      case 'network-request-failed':
        return ServiceException(
          'Network error during sign-in',
          ServiceErrorType.network,
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
