// lib/ui/1_state/features/auth/auth_state.dart

import 'package:equatable/equatable.dart';

// Import domain entities
import '../../../../models/1_domain/shared/entities/user.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when auth BLoC is created
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state for any auth operation in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is successfully authenticated
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

/// State when user is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when auth operation fails
class AuthError extends AuthState {
  final String message;
  final String? operation;

  const AuthError(this.message, {this.operation});

  @override
  List<Object?> get props => [message, operation];
}

/// State when profile update is successful
class ProfileUpdateSuccess extends AuthState {
  final User updatedUser;

  const ProfileUpdateSuccess(this.updatedUser);

  @override
  List<Object> get props => [updatedUser];
}

/// State when phone verification code is sent
class PhoneVerificationCodeSent extends AuthState {
  final String phoneNumber;

  const PhoneVerificationCodeSent(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

/// State when phone verification is successful
class PhoneVerificationSuccess extends AuthState {
  final User verifiedUser;

  const PhoneVerificationSuccess(this.verifiedUser);

  @override
  List<Object> get props => [verifiedUser];
}

/// State when password reset email is sent
class PasswordResetEmailSent extends AuthState {
  final String email;

  const PasswordResetEmailSent(this.email);

  @override
  List<Object> get props => [email];
}

/// State when email registration check is complete
class EmailRegistrationCheckComplete extends AuthState {
  final String email;
  final bool isRegistered;

  const EmailRegistrationCheckComplete({
    required this.email,
    required this.isRegistered,
  });

  @override
  List<Object> get props => [email, isRegistered];
}

/// State when account deletion is successful
class AccountDeletionSuccess extends AuthState {
  const AccountDeletionSuccess();
}
