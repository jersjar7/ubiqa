// lib/services/1_infrastructure/firebase/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

// Import domain entities and value objects
import '../../../models/1_domain/shared/entities/user.dart';
import '../../../models/1_domain/shared/value_objects/contact_info.dart';

// Import configuration
import '../../0_config/shared/firebase_config.dart';

// Import shared infrastructure
import '../shared/service_result.dart';

/// Firebase Authentication Service
///
/// Implements user authentication and profile management infrastructure
/// following the domain layer contracts defined in User entity and
/// ContactInfo value object. Integrates with Peru market requirements.
class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthService() : _firebaseAuth = FirebaseConfig.auth;

  // AUTHENTICATION OPERATIONS

  /// Registers new user with email and password
  /// Creates User entity and persists to Firestore following domain rules
  Future<ServiceResult<User>> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Validate email format for Peru market
      if (!_isValidEmailFormat(email)) {
        return ServiceResult.failure(
          'Invalid email format',
          ServiceException(
            'Email must be valid format',
            ServiceErrorType.validation,
          ),
        );
      }

      // Create Firebase Auth user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return ServiceResult.failure(
          'Failed to create user account',
          ServiceException(
            'Firebase Auth returned null user',
            ServiceErrorType.authentication,
          ),
        );
      }

      // Update display name if provided
      if (displayName?.trim().isNotEmpty == true) {
        await credential.user!.updateDisplayName(displayName!.trim());
        await credential.user!.reload();
      }

      // Create domain User entity using domain factory
      final user = UserDomainService.createFromFirebaseWithValidation(
        firebaseUid: credential.user!.uid,
        email: email,
        displayName: displayName,
      );

      // Persist user to Firestore
      final persistResult = await _persistUserToFirestore(user);
      if (!persistResult.isSuccess) {
        // Rollback Firebase Auth user if Firestore fails
        await credential.user!.delete();
        return ServiceResult.failure(
          'Failed to save user profile',
          persistResult.exception,
        );
      }

      return ServiceResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return ServiceResult.failure(
        _getAuthErrorMessage(e),
        ServiceException(
          e.message ?? 'Authentication error',
          ServiceErrorType.authentication,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Registration failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Signs in existing user with email and password
  /// Returns User entity with current profile data
  Future<ServiceResult<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return ServiceResult.failure(
          'Sign in failed',
          ServiceException(
            'Firebase Auth returned null user',
            ServiceErrorType.authentication,
          ),
        );
      }

      // Retrieve user profile from Firestore
      final userResult = await getUserProfile(credential.user!.uid);
      if (!userResult.isSuccess) {
        return ServiceResult.failure(
          'Failed to load user profile',
          userResult.exception,
        );
      }

      return ServiceResult.success(userResult.data!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return ServiceResult.failure(
        _getAuthErrorMessage(e),
        ServiceException(
          e.message ?? 'Authentication error',
          ServiceErrorType.authentication,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Sign in failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Signs out current user
  Future<ServiceResult<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Sign out failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Gets currently authenticated user if available
  Future<ServiceResult<User?>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return ServiceResult.success(null);
      }

      final userResult = await getUserProfile(firebaseUser.uid);
      if (!userResult.isSuccess) {
        return ServiceResult.failure(
          'Failed to load current user profile',
          userResult.exception,
        );
      }

      return ServiceResult.success(userResult.data);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to get current user',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  // PROFILE MANAGEMENT

  /// Retrieves user profile from Firestore by Firebase UID
  Future<ServiceResult<User>> getUserProfile(String firebaseUid) async {
    try {
      final doc = await FirebaseCollections.users.doc(firebaseUid).get();

      if (!doc.exists) {
        return ServiceResult.failure(
          'User profile not found',
          ServiceException(
            'No profile document for UID: $firebaseUid',
            ServiceErrorType.validation,
          ),
        );
      }

      final userData = doc.data() as Map<String, dynamic>;

      // Reconstruct User entity from Firestore data
      final user = _userFromFirestoreData(userData, firebaseUid);

      return ServiceResult.success(user);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to retrieve user profile',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Updates user profile information
  /// Validates changes against domain rules before persisting
  Future<ServiceResult<User>> updateUserProfile({
    required User currentUser,
    String? name,
    String? phoneNumber,
    ContactHours? preferredContactHours,
    String? contactInstructions,
  }) async {
    try {
      // Use domain service to update profile with validation
      final updatedUser = UserDomainService.updateProfile(
        user: currentUser,
        name: name,
        phoneNumber: phoneNumber,
        preferredHours: preferredContactHours,
        contactInstructions: contactInstructions,
      );

      // Persist updated profile to Firestore
      final persistResult = await _persistUserToFirestore(updatedUser);
      if (!persistResult.isSuccess) {
        return ServiceResult.failure(
          'Failed to save profile updates',
          persistResult.exception,
        );
      }

      // Update Firebase Auth display name if changed
      if (name != null && name.trim() != currentUser.name) {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.updateDisplayName(name.trim());
        }
      }

      return ServiceResult.success(updatedUser);
    } on ContactInfoValidationException catch (e) {
      return ServiceResult.failure(
        'Invalid contact information',
        ServiceException(
          e.violations.join(', '),
          ServiceErrorType.validation,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Profile update failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Sets or updates user contact information
  /// Validates WhatsApp number for Peru market requirements
  Future<ServiceResult<User>> setUserContactInfo({
    required User currentUser,
    required String whatsappPhoneNumber,
    ContactHours preferredContactHours = ContactHours.anytime,
    String? additionalContactNotes,
  }) async {
    try {
      // Use domain service to set contact info with validation
      final updatedUser = UserDomainService.setContactInfo(
        user: currentUser,
        phoneNumber: whatsappPhoneNumber,
        preferredHours: preferredContactHours,
        instructions: additionalContactNotes,
      );

      // Persist to Firestore
      final persistResult = await _persistUserToFirestore(updatedUser);
      if (!persistResult.isSuccess) {
        return ServiceResult.failure(
          'Failed to save contact information',
          persistResult.exception,
        );
      }

      return ServiceResult.success(updatedUser);
    } on ContactInfoValidationException catch (e) {
      return ServiceResult.failure(
        'Invalid WhatsApp phone number',
        ServiceException(
          e.violations.join(', '),
          ServiceErrorType.validation,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Contact info update failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Deactivates user account (soft delete)
  /// Sets isActive to false while preserving user data
  Future<ServiceResult<User>> deactivateAccount(User user) async {
    try {
      final deactivatedUser = user.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      final persistResult = await _persistUserToFirestore(deactivatedUser);
      if (!persistResult.isSuccess) {
        return ServiceResult.failure(
          'Failed to deactivate account',
          persistResult.exception,
        );
      }

      return ServiceResult.success(deactivatedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Account deactivation failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Reactivates previously deactivated user account
  Future<ServiceResult<User>> reactivateAccount(User user) async {
    try {
      final reactivatedUser = user.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      final persistResult = await _persistUserToFirestore(reactivatedUser);
      if (!persistResult.isSuccess) {
        return ServiceResult.failure(
          'Failed to reactivate account',
          persistResult.exception,
        );
      }

      return ServiceResult.success(reactivatedUser);
    } catch (e) {
      return ServiceResult.failure(
        'Account reactivation failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  // PASSWORD MANAGEMENT

  /// Sends password reset email
  Future<ServiceResult<void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return ServiceResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return ServiceResult.failure(
        _getAuthErrorMessage(e),
        ServiceException(
          e.message ?? 'Password reset error',
          ServiceErrorType.authentication,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Password reset failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Updates user password (requires current authentication)
  Future<ServiceResult<void>> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return ServiceResult.failure(
          'No authenticated user',
          ServiceException(
            'User must be authenticated to change password',
            ServiceErrorType.authentication,
          ),
        );
      }

      await user.updatePassword(newPassword);
      return ServiceResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return ServiceResult.failure(
        _getAuthErrorMessage(e),
        ServiceException(
          e.message ?? 'Password update error',
          ServiceErrorType.authentication,
          e,
        ),
      );
    } catch (e) {
      return ServiceResult.failure(
        'Password update failed',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  // PRIVATE HELPER METHODS

  /// Persists User entity to Firestore
  Future<ServiceResult<void>> _persistUserToFirestore(User user) async {
    try {
      final userData = _userToFirestoreData(user);

      await FirebaseCollections.users
          .doc(user.id.value)
          .set(userData, SetOptions(merge: true));

      return ServiceResult.success(null);
    } catch (e) {
      return ServiceResult.failure(
        'Failed to save user to database',
        ServiceException(e.toString(), ServiceErrorType.unknown, e),
      );
    }
  }

  /// Converts User entity to Firestore document data
  Map<String, dynamic> _userToFirestoreData(User user) {
    final data = <String, dynamic>{
      'email': user.email,
      'name': user.name,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'updatedAt': Timestamp.fromDate(user.updatedAt),
      'isActive': user.isActive,
    };

    // Add contact info if present
    if (user.contactInfo != null) {
      data['contactInfo'] = {
        'whatsappPhoneNumber': user.contactInfo!.whatsappPhoneNumber,
        'preferredContactTimeSlot':
            user.contactInfo!.preferredContactTimeSlot.name,
        'additionalContactNotes': user.contactInfo!.additionalContactNotes,
      };
    }

    return data;
  }

  /// Reconstructs User entity from Firestore document data
  User _userFromFirestoreData(Map<String, dynamic> data, String firebaseUid) {
    // Extract basic user data
    final email = data['email'] as String;
    final name = data['name'] as String?;
    final createdAt = (data['createdAt'] as Timestamp).toDate();
    final updatedAt = (data['updatedAt'] as Timestamp).toDate();
    final isActive = data['isActive'] as bool? ?? true;

    // Reconstruct contact info if present
    ContactInfo? contactInfo;
    if (data['contactInfo'] != null) {
      final contactData = data['contactInfo'] as Map<String, dynamic>;

      final contactHoursName =
          contactData['preferredContactTimeSlot'] as String?;
      final contactHours = ContactHours.values.firstWhere(
        (hours) => hours.name == contactHoursName,
        orElse: () => ContactHours.anytime,
      );

      contactInfo = ContactInfo.create(
        whatsappPhoneNumber: contactData['whatsappPhoneNumber'] as String,
        preferredContactTimeSlot: contactHours,
        additionalContactNotes:
            contactData['additionalContactNotes'] as String?,
      );
    }

    // Use domain factory to reconstruct User with preserved timestamps
    return User.fromStoredData(
      firebaseUid: firebaseUid,
      email: email,
      name: name,
      contactInfo: contactInfo,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  /// Validates email format for Peru market
  bool _isValidEmailFormat(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Converts Firebase Auth errors to user-friendly messages in Spanish
  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'Email no válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'requires-recent-login':
        return 'Necesitas iniciar sesión nuevamente para esta acción';
      default:
        return 'Error de autenticación: ${e.message ?? 'Desconocido'}';
    }
  }
}
