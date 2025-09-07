// lib/ui/1_state/features/auth/auth_event.dart

import 'package:equatable/equatable.dart';

// Import domain entities and value objects
import '../../../../models/1_domain/shared/entities/user.dart';
import '../../../../models/1_domain/shared/value_objects/contact_info.dart';
import 'package:ubiqa/models/1_domain/shared/value_objects/international_phone_number.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check current authentication status
class GetCurrentUserRequested extends AuthEvent {
  const GetCurrentUserRequested();
}

/// Event to sign in user with email and password
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

/// Event to register new user account
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? fullName;
  final String? phoneNumber;
  final SupportedCountryCode? countryCode;

  const RegisterRequested({
    required this.email,
    required this.password,
    this.fullName,
    this.phoneNumber,
    this.countryCode,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    fullName,
    phoneNumber,
    countryCode,
  ];
}

/// Event to sign out current user
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event to update user profile information
class UpdateProfileRequested extends AuthEvent {
  final User currentUser;
  final String? fullName;
  final String? phoneNumber;
  final ContactHours? preferredContactHours;
  final String? profileImageUrl;

  const UpdateProfileRequested({
    required this.currentUser,
    this.fullName,
    this.phoneNumber,
    this.preferredContactHours,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [
    currentUser,
    fullName,
    phoneNumber,
    preferredContactHours,
    profileImageUrl,
  ];
}

/// Event to send phone verification code
class SendPhoneVerificationRequested extends AuthEvent {
  final String phoneNumber;

  const SendPhoneVerificationRequested({required this.phoneNumber});

  @override
  List<Object> get props => [phoneNumber];
}

/// Event to verify phone number with code
class VerifyPhoneRequested extends AuthEvent {
  final String phoneNumber;
  final String verificationCode;

  const VerifyPhoneRequested({
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  List<Object> get props => [phoneNumber, verificationCode];
}

/// Event to request password reset email
class RequestPasswordResetRequested extends AuthEvent {
  final String email;

  const RequestPasswordResetRequested({required this.email});

  @override
  List<Object> get props => [email];
}

/// Event to check if email is already registered
class CheckEmailRegistrationRequested extends AuthEvent {
  final String email;

  const CheckEmailRegistrationRequested({required this.email});

  @override
  List<Object> get props => [email];
}

/// Event to delete user account
class DeleteAccountRequested extends AuthEvent {
  final User user;

  const DeleteAccountRequested({required this.user});

  @override
  List<Object> get props => [user];
}
