// lib/ui/1_state/features/auth/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ubiqa/services/4_infrastructure/auth/apple_auth_service.dart';
import 'package:ubiqa/services/4_infrastructure/auth/google_auth_service.dart';
import 'package:ubiqa/services/5_injection/dependency_container.dart';

// Import auth events and states
import 'auth_event.dart';
import 'auth_state.dart';

// Import use cases
import '../../../../models/2_usecases/features/auth/login_user_usecase.dart';
import '../../../../models/2_usecases/features/auth/register_user_usecase.dart';
import '../../../../models/2_usecases/features/auth/logout_user_usecase.dart';
import '../../../../models/2_usecases/features/auth/get_current_user_usecase.dart';
import '../../../../models/2_usecases/features/auth/update_user_profile_usecase.dart';
import '../../../../models/2_usecases/features/auth/send_phone_verification_usecase.dart';
import '../../../../models/2_usecases/features/auth/verify_phone_number_usecase.dart';
import '../../../../models/2_usecases/features/auth/request_password_reset_usecase.dart';
import '../../../../models/2_usecases/features/auth/check_email_registration_usecase.dart';
import '../../../../models/2_usecases/features/auth/delete_user_account_usecase.dart';

/// Authentication BLoC
///
/// Manages authentication state for the entire application.
/// Coordinates between UI events and auth use cases.
/// No business logic - delegates all operations to use cases.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUserUseCase _loginUserUseCase;
  final RegisterUserUseCase _registerUserUseCase;
  final LogoutUserUseCase _logoutUserUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final SendPhoneVerificationUseCase _sendPhoneVerificationUseCase;
  final VerifyPhoneNumberUseCase _verifyPhoneNumberUseCase;
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;
  final CheckEmailRegistrationUseCase _checkEmailRegistrationUseCase;
  final DeleteUserAccountUseCase _deleteUserAccountUseCase;

  AuthBloc({
    required LoginUserUseCase loginUserUseCase,
    required RegisterUserUseCase registerUserUseCase,
    required LogoutUserUseCase logoutUserUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required SendPhoneVerificationUseCase sendPhoneVerificationUseCase,
    required VerifyPhoneNumberUseCase verifyPhoneNumberUseCase,
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
    required CheckEmailRegistrationUseCase checkEmailRegistrationUseCase,
    required DeleteUserAccountUseCase deleteUserAccountUseCase,
  }) : _loginUserUseCase = loginUserUseCase,
       _registerUserUseCase = registerUserUseCase,
       _logoutUserUseCase = logoutUserUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _updateUserProfileUseCase = updateUserProfileUseCase,
       _sendPhoneVerificationUseCase = sendPhoneVerificationUseCase,
       _verifyPhoneNumberUseCase = verifyPhoneNumberUseCase,
       _requestPasswordResetUseCase = requestPasswordResetUseCase,
       _checkEmailRegistrationUseCase = checkEmailRegistrationUseCase,
       _deleteUserAccountUseCase = deleteUserAccountUseCase,
       super(const AuthInitial()) {
    // Register event handlers
    on<GetCurrentUserRequested>(_onGetCurrentUserRequested);
    on<LoginRequested>(_onLoginRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<AppleSignInRequested>(_onAppleSignInRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<SendPhoneVerificationRequested>(_onSendPhoneVerificationRequested);
    on<VerifyPhoneRequested>(_onVerifyPhoneRequested);
    on<RequestPasswordResetRequested>(_onRequestPasswordResetRequested);
    on<CheckEmailRegistrationRequested>(_onCheckEmailRegistrationRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  // EVENT HANDLERS

  /// Handle current user check
  Future<void> _onGetCurrentUserRequested(
    GetCurrentUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 [AuthBloc] GetCurrentUserRequested event received');
    emit(const AuthLoading());
    print('🔄 [AuthBloc] Emitted AuthLoading state');

    try {
      print('🔄 [AuthBloc] Calling getCurrentUserUseCase.execute()');
      final result = await _getCurrentUserUseCase.execute();
      print(
        '🔄 [AuthBloc] getCurrentUserUseCase completed - isSuccess: ${result.isSuccess}',
      );

      if (result.isSuccess) {
        final user = result.data;
        print(
          '🔄 [AuthBloc] User data received - user is null: ${user == null}',
        );

        if (user != null) {
          print('✅ [AuthBloc] User found, emitting AuthAuthenticated');
          print('✅ [AuthBloc] User email: ${user.email}');
          emit(AuthAuthenticated(user));
        } else {
          print('❌ [AuthBloc] No user found, emitting AuthUnauthenticated');
          emit(const AuthUnauthenticated());
        }
      } else {
        print(
          '🚨 [AuthBloc] getCurrentUser failed - ${result.getErrorMessage()}',
        );
        emit(AuthError(result.getErrorMessage(), operation: 'getCurrentUser'));
      }
    } catch (e, stackTrace) {
      print('🚨 [AuthBloc] Exception in _onGetCurrentUserRequested: $e');
      print('🚨 [AuthBloc] Stack trace: $stackTrace');
      emit(
        AuthError(
          'Failed to check authentication: $e',
          operation: 'getCurrentUser',
        ),
      );
    }
  }

  /// Handle user login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 [AuthBloc] Login requested for: ${event.email}');
    emit(const AuthLoading());

    final result = await _loginUserUseCase.execute(
      email: event.email,
      password: event.password,
    );
    print('🔄 [AuthBloc] Login result success: ${result.isSuccess}');

    if (result.isSuccess) {
      print(
        '✅ [AuthBloc] Emitting AuthAuthenticated for: ${result.data!.email}',
      );
      emit(AuthAuthenticated(result.data!));
    } else {
      print('❌ [AuthBloc] Login failed: ${result.getErrorMessage()}');
      emit(AuthError(result.getErrorMessage(), operation: 'login'));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final googleAuthService = UbiqaDependencyContainer.get<GoogleAuthService>();
    final result = await googleAuthService.signInWithGoogle();

    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(result.getErrorMessage(), operation: 'googleSignIn'));
    }
  }

  Future<void> _onAppleSignInRequested(
    AppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final appleAuthService = UbiqaDependencyContainer.get<AppleAuthService>();
    final result = await appleAuthService.signInWithApple();

    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(result.getErrorMessage(), operation: 'appleSignIn'));
    }
  }

  /// Handle user registration
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _registerUserUseCase.execute(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      phoneNumber: event.phoneNumber,
      countryCode: event.countryCode,
    );

    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(result.getErrorMessage(), operation: 'register'));
    }
  }

  /// Handle user logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _logoutUserUseCase.execute();

    if (result.isSuccess) {
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthError(result.getErrorMessage(), operation: 'logout'));
    }
  }

  /// Handle profile update
  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _updateUserProfileUseCase.execute(
      currentUser: event.currentUser,
      fullName: event.fullName,
      phoneNumber: event.phoneNumber,
      preferredContactHours: event.preferredContactHours,
      profileImageUrl: event.profileImageUrl,
    );

    if (result.isSuccess) {
      emit(ProfileUpdateSuccess(result.data!));
      // Automatically transition to authenticated state
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(result.getErrorMessage(), operation: 'updateProfile'));
    }
  }

  /// Handle phone verification code sending
  Future<void> _onSendPhoneVerificationRequested(
    SendPhoneVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _sendPhoneVerificationUseCase.execute(
      phoneNumber: event.phoneNumber,
    );

    if (result.isSuccess) {
      emit(PhoneVerificationCodeSent(event.phoneNumber));
    } else {
      emit(
        AuthError(result.getErrorMessage(), operation: 'sendPhoneVerification'),
      );
    }
  }

  /// Handle phone number verification
  Future<void> _onVerifyPhoneRequested(
    VerifyPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _verifyPhoneNumberUseCase.execute(
      phoneNumber: event.phoneNumber,
      verificationCode: event.verificationCode,
    );

    if (result.isSuccess) {
      emit(PhoneVerificationSuccess(result.data!));
      // Automatically transition to authenticated state
      emit(AuthAuthenticated(result.data!));
    } else {
      emit(AuthError(result.getErrorMessage(), operation: 'verifyPhone'));
    }
  }

  /// Handle password reset request
  Future<void> _onRequestPasswordResetRequested(
    RequestPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _requestPasswordResetUseCase.execute(
      email: event.email,
    );

    if (result.isSuccess) {
      emit(PasswordResetEmailSent(event.email));
    } else {
      emit(
        AuthError(result.getErrorMessage(), operation: 'requestPasswordReset'),
      );
    }
  }

  /// Handle email registration check
  Future<void> _onCheckEmailRegistrationRequested(
    CheckEmailRegistrationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _checkEmailRegistrationUseCase.execute(
      email: event.email,
    );

    if (result.isSuccess) {
      emit(
        EmailRegistrationCheckComplete(
          email: event.email,
          isRegistered: result.data!,
        ),
      );
    } else {
      emit(
        AuthError(
          result.getErrorMessage(),
          operation: 'checkEmailRegistration',
        ),
      );
    }
  }

  /// Handle account deletion
  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _deleteUserAccountUseCase.execute(user: event.user);

    if (result.isSuccess) {
      emit(const AccountDeletionSuccess());
      // Automatically transition to unauthenticated state
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthError(result.getErrorMessage(), operation: 'deleteAccount'));
    }
  }
}
