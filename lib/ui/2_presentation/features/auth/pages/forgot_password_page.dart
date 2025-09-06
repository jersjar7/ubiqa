// lib/ui/2_presentation/features/auth/pages/forgot_password_page.dart

import 'package:flutter/cupertino.dart';
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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UbiqaDependencyContainer.get<AuthBloc>(),
      child: CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.background,
          border: null,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.back),
          ),
        ),
        child: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listener: _handleAuthStateChanges,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60.0),
                  _buildLogo(),
                  const SizedBox(height: 40.0),
                  _buildContent(),
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
      width: 250.0,
      height: 70.0,
    );
  }

  Widget _buildContent() {
    if (_emailSent) {
      return _buildSuccessContent();
    } else {
      return _buildFormContent();
    }
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        Text(
          'Recuperar contraseña',
          style: AppTextStyles.title2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Text(
          'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32.0),
        _buildForm(),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      children: [
        Container(
          width: 80.0,
          height: 80.0,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40.0),
          ),
          child: Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 50.0,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24.0),
        Text(
          'Correo enviado',
          style: AppTextStyles.title2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Text(
          'Hemos enviado un enlace de recuperación a:\n${_emailController.text}',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Text(
          'Revisa tu bandeja de entrada y spam.',
          style: AppTextStyles.footnote.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32.0),
        AuthButton(
          text: 'Volver al inicio',
          width: double.infinity,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 16.0),
        TextAuthButton(text: 'Reenviar correo', onPressed: _onResendPressed),
      ],
    );
  }

  Widget _buildForm() {
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
              onSubmitted: (_) => _onSendPressed(context),
            ),
            const SizedBox(height: 24.0),
            AuthButton(
              text: 'Enviar enlace',
              isLoading: isLoading,
              width: double.infinity,
              onPressed: () => _onSendPressed(context),
            ),
            const SizedBox(height: 24.0),
            TextAuthButton(
              text: 'Volver al inicio de sesión',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // EVENT HANDLERS

  void _onEmailChanged(String value) {
    if (_emailError != null) {
      setState(() => _emailError = null);
    }
  }

  void _onSendPressed(BuildContext context) {
    setState(() => _emailError = null);

    if (!_validateEmail()) return;

    context.read<AuthBloc>().add(
      RequestPasswordResetRequested(email: _emailController.text.trim()),
    );
  }

  void _onResendPressed() {
    context.read<AuthBloc>().add(
      RequestPasswordResetRequested(email: _emailController.text.trim()),
    );
  }

  // VALIDATION

  bool _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'El correo electrónico es requerido');
      return false;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(
        () => _emailError = 'Por favor ingresa un correo electrónico válido',
      );
      return false;
    }

    return true;
  }

  // STATE MANAGEMENT

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is PasswordResetEmailSent) {
      setState(() => _emailSent = true);
    } else if (state is AuthError) {
      _handleAuthError(state.message);
    }
  }

  void _handleAuthError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
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
}
