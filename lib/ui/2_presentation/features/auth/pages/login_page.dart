// lib/ui/2_presentation/features/auth/pages/login_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Import widgets
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

// Import state management
import '../../../../1_state/features/auth/auth_bloc.dart';
import '../../../../1_state/features/auth/auth_event.dart';
import '../../../../1_state/features/auth/auth_state.dart';

// Import dependency injection
import '../../../../../services/5_injection/dependency_container.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UbiqaDependencyContainer.get<AuthBloc>(),
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listener: _handleAuthStateChanges,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 80.0),
                  _buildLogo(),
                  const SizedBox(height: 0.0),
                  _buildWelcomeText(),
                  const SizedBox(height: 40.0),
                  _buildLoginForm(),
                  const SizedBox(height: 4.0),
                  _buildForgotPasswordButton(),
                  const SizedBox(height: 12.0),
                  _buildSocialLoginSection(),
                  const SizedBox(height: 12.0),
                  _buildSignUpPrompt(),
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/img/logos/ubiqa-h.webp',
      width: 280.0,
      height: 80.0,
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Alquila  ·  Compra  ·  Vende\n\n\nÚnica app para encontrar y anunciar\ntu propiedad perfecta en Piura',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          children: [
            AuthTextField(
              label: 'Correo electrónico',
              placeholder: 'Ingresa tu correo electrónico',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              prefix: Icon(
                CupertinoIcons.mail,
                size: 20.0,
                color: AppColors.textSecondary,
              ),
              onChanged: _onEmailChanged,
              onSubmitted: (_) => _onLoginPressed(context),
            ),
            const SizedBox(height: 16.0),
            PasswordTextField(
              label: 'Contraseña',
              controller: _passwordController,
              errorText: _passwordError,
              onChanged: _onPasswordChanged,
              onSubmitted: (_) => _onLoginPressed(context),
            ),
            const SizedBox(height: 24.0),
            AuthButton(
              text: 'Iniciar Sesión',
              isLoading: isLoading,
              width: double.infinity,
              onPressed: () => _onLoginPressed(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextAuthButton(
        text: '¿Olvidaste tu contraseña?',
        onPressed: _onForgotPasswordPressed,
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          children: [
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.separator)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'o continúa con',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.separator)),
              ],
            ),
            const SizedBox(height: 20.0),
            SocialAuthButton(
              provider: SocialProvider.google,
              isLoading: isLoading,
              onPressed: () =>
                  _onSocialLoginPressed(context, SocialProvider.google),
            ),
            const SizedBox(height: 12.0),
            SocialAuthButton(
              provider: SocialProvider.apple,
              isLoading: isLoading,
              onPressed: () =>
                  _onSocialLoginPressed(context, SocialProvider.apple),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "¿No tienes una cuenta? ",
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        TextAuthButton(text: 'Regístrate', onPressed: _onSignUpPressed),
      ],
    );
  }

  // EVENT HANDLERS

  void _onEmailChanged(String value) {
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _onPasswordChanged(String value) {
    if (_passwordError != null) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  void _onLoginPressed(BuildContext context) {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate inputs
    if (!_validateInputs()) return;

    // Trigger login event
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _onForgotPasswordPressed() {
    // Navigate to forgot password page
    Navigator.of(context).pushNamed('/forgot-password');
  }

  void _onSocialLoginPressed(BuildContext context, SocialProvider provider) {
    if (provider == SocialProvider.google) {
      context.read<AuthBloc>().add(const GoogleSignInRequested());
    } else {
      _showComingSoonDialog(provider.name);
    }
  }

  void _onSignUpPressed() {
    // Navigate to registration page
    Navigator.of(context, rootNavigator: true).pushNamed('/register');
  }

  // VALIDATION

  bool _validateInputs() {
    bool isValid = true;

    // Email validation
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'El correo electrónico es requerido';
      });
      isValid = false;
    } else if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Por favor ingresa un correo electrónico válido';
      });
      isValid = false;
    }

    // Password validation
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'La contraseña es requerida';
      });
      isValid = false;
    }

    return isValid;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  // STATE MANAGEMENT

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      // Navigate to main app
      Navigator.of(context, rootNavigator: true).pushReplacementNamed('/home');
    } else if (state is AuthError) {
      _handleAuthError(state.message);
    }
  }

  void _handleAuthError(String message) {
    // Show error dialog
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error de Inicio de Sesión'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Próximamente'),
        content: Text(
          'El inicio de sesión con $feature estará disponible pronto.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
