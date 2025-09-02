// lib/models/1_domain/shared/entities/user.dart

import 'package:equatable/equatable.dart';

// Import value objects
import '../value_objects/contact_info.dart';

/// Strongly-typed identifier for User entities
class UserId extends Equatable {
  final String value;

  const UserId._(this.value);

  /// Creates UserId from Firebase UID
  factory UserId.fromFirebaseUid(String firebaseUid) {
    if (firebaseUid.trim().isEmpty) {
      throw ArgumentError('Firebase UID cannot be empty');
    }
    return UserId._(firebaseUid.trim());
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}

/// User entity representing a person who interacts with the Ubiqa platform
class User extends Equatable {
  /// Unique identifier (Firebase UID)
  final UserId id;

  /// User's email from Firebase Auth
  final String email;

  /// User's display name (optional)
  final String? name;

  /// Contact information (phone, WhatsApp, preferences)
  final ContactInfo? contactInfo;

  /// Account creation timestamp
  final DateTime createdAt;

  /// Last profile update timestamp
  final DateTime updatedAt;

  /// Whether account is active
  final bool isActive;

  const User._({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.name,
    this.contactInfo,
  });

  /// Factory: Create new user from Firebase registration
  factory User.createFromFirebaseAuth({
    required String firebaseUid,
    required String email,
    String? displayName,
  }) {
    final now = DateTime.now();
    return User._(
      id: UserId.fromFirebaseUid(firebaseUid),
      email: email.trim().toLowerCase(),
      name: displayName?.trim(),
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  /// Creates copy with updated fields
  User copyWith({
    String? name,
    ContactInfo? contactInfo,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User._(
      id: id,
      email: email,
      name: name ?? this.name,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  // CORE USER BUSINESS LOGIC

  /// Whether user has verified contact information
  bool isVerified() {
    return contactInfo != null && isActive;
  }

  /// Whether user has complete profile information
  bool hasCompleteProfile() {
    return name != null && name!.trim().isNotEmpty && contactInfo != null;
  }

  /// Gets display name with fallback
  String getDisplayName() {
    if (name?.trim().isNotEmpty == true) {
      return name!.trim();
    }

    final emailPrefix = email.split('@').first;
    return emailPrefix.length > 12
        ? '${emailPrefix.substring(0, 12)}...'
        : emailPrefix;
  }

  /// Gets WhatsApp contact URL for direct communication
  String? getWhatsAppContactUrl([String? message]) {
    if (!isVerified() || contactInfo == null) return null;
    return contactInfo!.getWhatsAppUrl(message);
  }

  /// Gets formatted phone for display
  String? getFormattedPhone() {
    return contactInfo?.getFormattedNumber();
  }

  /// Gets user account age
  Duration getAccountAge() {
    return DateTime.now().difference(createdAt);
  }

  /// Checks if user is new (less than 7 days)
  bool isNewUser() {
    return getAccountAge().inDays < 7;
  }

  // ENTITY IDENTITY - Based on ID only
  @override
  List<Object> get props => [id];

  @override
  String toString() {
    return 'User(id: ${id.value}, email: $email, verified: ${isVerified()})';
  }
}

/// Domain exception for user business rule violations
class UserDomainException implements Exception {
  final String message;
  final List<String> violations;

  const UserDomainException(this.message, this.violations);

  @override
  String toString() =>
      'UserDomainException: $message\nViolations: ${violations.join(', ')}';
}

/// User domain service for validation and creation
class UserDomainService {
  /// Creates user from Firebase with validation
  static User createFromFirebaseWithValidation({
    required String firebaseUid,
    required String email,
    String? displayName,
  }) {
    return User.createFromFirebaseAuth(
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
    );
  }

  /// Sets user contact information
  static User setContactInfo({
    required User user,
    required String phoneNumber,
    ContactHours preferredHours = ContactHours.anytime,
    String? instructions,
  }) {
    final contactInfo = ContactInfo.create(
      whatsappNumber: phoneNumber,
      preferredHours: preferredHours,
      instructions: instructions,
    );

    return user.copyWith(contactInfo: contactInfo);
  }

  /// Updates user profile information
  static User updateProfile({
    required User user,
    String? name,
    String? phoneNumber,
    ContactHours? preferredHours,
    String? contactInstructions,
  }) {
    var updatedUser = user;

    if (name != null && name.trim().length >= 2) {
      updatedUser = updatedUser.copyWith(name: name.trim());
    }

    if (phoneNumber != null) {
      updatedUser = setContactInfo(
        user: updatedUser,
        phoneNumber: phoneNumber,
        preferredHours: preferredHours ?? ContactHours.anytime,
        instructions: contactInstructions,
      );
    }

    return updatedUser;
  }
}
