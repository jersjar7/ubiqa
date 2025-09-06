// lib/ui/2_presentation/features/auth/flows/login_flow.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import existing pages
import '../pages/login_page.dart';
import '../pages/forgot_password_page.dart';

// Import state management
import '../../../../1_state/features/auth/auth_bloc.dart';
import '../../../../1_state/features/auth/auth_state.dart';

// Import dependency injection
import '../../../../../services/5_injection/dependency_container.dart';

/// Login Flow Coordinator
///
/// Orchestrates navigation between existing auth pages:
/// - LoginPage → ForgotPasswordPage
/// - Handles authentication success routing
/// - Coordinates with RegistrationFlow when needed
class LoginFlow extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onNavigateToRegister;

  const LoginFlow({super.key, this.onLoginSuccess, this.onNavigateToRegister});

  @override
  State<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends State<LoginFlow> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UbiqaDependencyContainer.get<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthStateChanges,
        child: Navigator(
          key: _navigatorKey,
          initialRoute: '/login',
          onGenerateRoute: _generateRoute,
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return CupertinoPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case '/forgot-password':
        return CupertinoPageRoute(
          builder: (_) => const ForgotPasswordPage(),
          settings: settings,
        );

      default:
        return null;
    }
  }

  // STATE MANAGEMENT

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      _navigateToHome();
    } else if (state is PasswordResetEmailSent) {
      _showPasswordResetSuccess(state.email);
    }
  }

  void _navigateToHome() {
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      // Navigate back to main app
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _showPasswordResetSuccess(String email) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Correo enviado'),
        content: Text(
          'Se ha enviado un enlace de recuperación a $email. '
          'Revisa tu bandeja de entrada y spam.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              // Return to login page
              _navigatorKey.currentState?.popUntil(
                (route) => route.settings.name == '/login',
              );
            },
          ),
        ],
      ),
    );
  }
}
