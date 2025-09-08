// lib/services/5_injection/features/auth/auth_dependencies.dart

import 'package:get_it/get_it.dart';
import 'package:ubiqa/services/4_infrastructure/auth/google_auth_service.dart';

// Import infrastructure services
import '../../../4_infrastructure/firebase/firebase_auth_service.dart';

// Import datasources
import '../../../3_datasources/features/auth/auth_api_datasource.dart';

// Import contracts
import '../../../1_contracts/features/auth/auth_repository.dart';

// Import coordinators
import '../../../2_coordinators/features/auth/auth_repository_impl.dart';

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
import '../../../../models/2_usecases/features/auth/check_phone_registration_usecase.dart';
import '../../../../models/2_usecases/features/auth/delete_user_account_usecase.dart';

// Import state management
import '../../../../ui/1_state/features/auth/auth_bloc.dart';

/// Authentication feature dependency injection
class AuthDependencies {
  /// Register all auth feature dependencies
  static Future<void> register(GetIt container) async {
    // Register datasource
    container.registerLazySingleton<AuthApiDataSource>(
      () => AuthApiDataSource(container<FirebaseAuthService>()),
    );

    // Register repository
    container.registerLazySingleton<IAuthRepository>(
      () => AuthRepositoryImpl(container<AuthApiDataSource>()),
    );

    container.registerSingleton<GoogleAuthService>(GoogleAuthService());

    // Register use cases
    container.registerLazySingleton<LoginUserUseCase>(
      () => LoginUserUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<RegisterUserUseCase>(
      () => RegisterUserUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<LogoutUserUseCase>(
      () => LogoutUserUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<UpdateUserProfileUseCase>(
      () => UpdateUserProfileUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<SendPhoneVerificationUseCase>(
      () => SendPhoneVerificationUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<VerifyPhoneNumberUseCase>(
      () => VerifyPhoneNumberUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<RequestPasswordResetUseCase>(
      () => RequestPasswordResetUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<CheckEmailRegistrationUseCase>(
      () => CheckEmailRegistrationUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<CheckPhoneRegistrationUseCase>(
      () => CheckPhoneRegistrationUseCase(container<IAuthRepository>()),
    );

    container.registerLazySingleton<DeleteUserAccountUseCase>(
      () => DeleteUserAccountUseCase(container<IAuthRepository>()),
    );

    // Register BLoC
    container.registerFactory<AuthBloc>(
      () => AuthBloc(
        loginUserUseCase: container<LoginUserUseCase>(),
        registerUserUseCase: container<RegisterUserUseCase>(),
        logoutUserUseCase: container<LogoutUserUseCase>(),
        getCurrentUserUseCase: container<GetCurrentUserUseCase>(),
        updateUserProfileUseCase: container<UpdateUserProfileUseCase>(),
        sendPhoneVerificationUseCase: container<SendPhoneVerificationUseCase>(),
        verifyPhoneNumberUseCase: container<VerifyPhoneNumberUseCase>(),
        requestPasswordResetUseCase: container<RequestPasswordResetUseCase>(),
        checkEmailRegistrationUseCase:
            container<CheckEmailRegistrationUseCase>(),
        deleteUserAccountUseCase: container<DeleteUserAccountUseCase>(),
      ),
    );

    print('✅ Auth feature dependencies registered');
  }
}
