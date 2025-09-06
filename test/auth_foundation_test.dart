// test/auth_foundation_test.dart

import 'package:flutter_test/flutter_test.dart';

// Import dependency container
import 'package:ubiqa/services/5_injection/dependency_container.dart';

// Import what we want to test
import 'package:ubiqa/ui/1_state/features/auth/auth_bloc.dart';
import 'package:ubiqa/ui/1_state/features/auth/auth_event.dart';
import 'package:ubiqa/models/2_usecases/features/auth/login_user_usecase.dart';
import 'package:ubiqa/services/1_contracts/features/auth/auth_repository.dart';

void main() {
  group('Auth Vertical Foundation Tests', () {
    setUp(() async {
      // Initialize horizontal foundation
      await UbiqaDependencyContainer.initializeHorizontalFoundation();

      // Initialize vertical features (includes auth)
      await UbiqaDependencyContainer.initializeVerticalFeatures();
    });

    tearDown(() async {
      await UbiqaDependencyContainer.reset();
    });

    test('Can resolve AuthBloc from DI container', () {
      expect(() => UbiqaDependencyContainer.get<AuthBloc>(), returnsNormally);
    });

    test('Can resolve all use cases', () {
      expect(
        () => UbiqaDependencyContainer.get<LoginUserUseCase>(),
        returnsNormally,
      );
    });

    test('Can resolve repository', () {
      expect(
        () => UbiqaDependencyContainer.get<IAuthRepository>(),
        returnsNormally,
      );
    });

    test('AuthBloc can handle GetCurrentUserRequested event', () async {
      final authBloc = UbiqaDependencyContainer.get<AuthBloc>();

      // This should not throw
      expect(
        () => authBloc.add(const GetCurrentUserRequested()),
        returnsNormally,
      );

      await authBloc.close();
    });
  });
}
