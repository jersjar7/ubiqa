// lib/ui/2_presentation/features/auth/flows/registration_flow.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import existing pages
import '../pages/register_page.dart';
import '../pages/phone_verification_page.dart';

// Import state management
import '../../../../1_state/features/auth/auth_bloc.dart';
import '../../../../1_state/features/auth/auth_state.dart';

// Import dependency injection
import '../../../../../services/5_injection/dependency_container.dart';

/// Registration Flow Coordinator
///
/// Orchestrates navigation between existing auth pages:
/// - RegisterPage → PhoneVerificationPage
/// - Handles registration success routing
/// - Coordinates phone verification completion
class RegistrationFlow extends StatefulWidget {
  final VoidCallback? onRegistrationSuccess;
  final VoidCallback? onNavigateToLogin;

  const RegistrationFlow({
    super.key,
    this.onRegistrationSuccess,
    this.onNavigateToLogin,
  });

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UbiqaDependencyContainer.get<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: _handleAuthStateChanges,
        child: Navigator(
          key: _navigatorKey,
          initialRoute: '/register',
          onGenerateRoute: _generateRoute,
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/register':
        return CupertinoPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      case '/verify-phone':
        final phoneNumber = settings.arguments as String?;
        if (phoneNumber == null) {
          return CupertinoPageRoute(
            builder: (_) => const _ErrorPage(
              message: 'Número de teléfono requerido para verificación',
            ),
          );
        }
        return CupertinoPageRoute(
          builder: (_) => PhoneVerificationPage(phoneNumber: phoneNumber),
          settings: settings,
        );

      default:
        return null;
    }
  }

  // STATE MANAGEMENT

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      final user = state.user;

      // Check if phone verification is needed
      if (user.contactInfo?.whatsappPhoneNumber != null && !user.isVerified()) {
        _promptPhoneVerification(user.contactInfo!.whatsappPhoneNumber);
      } else {
        _navigateToHome();
      }
    } else if (state is PhoneVerificationSuccess) {
      _showRegistrationSuccess();
    } else if (state is PhoneVerificationCodeSent) {
      _showCodeSentMessage(state.phoneNumber);
    }
  }

  void _navigateToHome() {
    if (widget.onRegistrationSuccess != null) {
      widget.onRegistrationSuccess!();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _promptPhoneVerification(String phoneNumber) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Verificar teléfono'),
        content: Text(
          'Para completar tu registro, verifica tu número: $phoneNumber',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Ahora no'),
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _navigatorKey.currentState?.pushNamed(
                '/verify-phone',
                arguments: phoneNumber,
              );
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }

  void _showCodeSentMessage(String phoneNumber) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Código enviado'),
        content: Text('Código enviado a $phoneNumber. Revisa tus SMS.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showRegistrationSuccess() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('¡Bienvenido a Ubiqa!'),
        content: const Text(
          'Tu cuenta ha sido creada y verificada exitosamente.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
            child: const Text('Comenzar'),
          ),
        ],
      ),
    );
  }
}

/// Error page for invalid navigation
class _ErrorPage extends StatelessWidget {
  final String message;

  const _ErrorPage({required this.message});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Error')),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64.0,
              color: CupertinoColors.systemOrange,
            ),
            const SizedBox(height: 16.0),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24.0),
            CupertinoButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
