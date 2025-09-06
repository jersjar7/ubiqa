// lib/ui/2_presentation/features/auth/pages/register_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Import widgets
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/international_phone_field.dart';

// Import domain
import '../../../../../models/1_domain/shared/value_objects/international_phone_number.dart';

// Import state management
import '../../../../1_state/features/auth/auth_bloc.dart';
import '../../../../1_state/features/auth/auth_event.dart';
import '../../../../1_state/features/auth/auth_state.dart';

// Import dependency injection
import '../../../../../services/5_injection/dependency_container.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  // International phone state
  SupportedCountryCode _selectedCountry = SupportedCountryCode.peru;
  String _fullPhoneNumber = '';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  _buildRegisterForm(),
                  const SizedBox(height: 4.0),
                  _buildSocialRegisterSection(),
                  const SizedBox(height: 12.0),
                  _buildLoginPrompt(),
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

  Widget _buildRegisterForm() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Column(
          children: [
            FullNameTextField(
              controller: _fullNameController,
              errorText: _fullNameError,
              onChanged: _onFullNameChanged,
            ),
            const SizedBox(height: 16.0),
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
            ),
            const SizedBox(height: 16.0),
            InternationalPhoneField(
              errorText: _phoneError,
              initialCountry: _selectedCountry,
              onPhoneChanged: _onPhoneChanged,
              onCountryChanged: _onCountryChanged,
            ),
            const SizedBox(height: 16.0),
            PasswordTextField(
              controller: _passwordController,
              errorText: _passwordError,
              onChanged: _onPasswordChanged,
            ),
            const SizedBox(height: 16.0),
            PasswordTextField(
              label: 'Confirmar contraseña',
              controller: _confirmPasswordController,
              errorText: _confirmPasswordError,
              isConfirmPassword: true,
              onChanged: _onConfirmPasswordChanged,
              onSubmitted: (_) => _onRegisterPressed(context),
            ),
            const SizedBox(height: 24.0),
            AuthButton(
              text: 'Crear Cuenta',
              isLoading: isLoading,
              width: double.infinity,
              onPressed: () => _onRegisterPressed(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialRegisterSection() {
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
                    'o regístrate con',
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
                  _onSocialRegisterPressed(context, SocialProvider.google),
            ),
            const SizedBox(height: 12.0),
            SocialAuthButton(
              provider: SocialProvider.apple,
              isLoading: isLoading,
              onPressed: () =>
                  _onSocialRegisterPressed(context, SocialProvider.apple),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "¿Ya tienes una cuenta? ",
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        TextAuthButton(text: 'Iniciar Sesión', onPressed: _onLoginPressed),
      ],
    );
  }

  // EVENT HANDLERS

  void _onFullNameChanged(String value) {
    if (_fullNameError != null) {
      setState(() => _fullNameError = null);
    }
  }

  void _onEmailChanged(String value) {
    if (_emailError != null) {
      setState(() => _emailError = null);
    }
  }

  void _onPhoneChanged(String phoneNumber) {
    setState(() {
      _fullPhoneNumber = phoneNumber;
    });

    if (_phoneError != null) {
      setState(() => _phoneError = null);
    }
  }

  void _onCountryChanged(SupportedCountryCode country) {
    setState(() {
      _selectedCountry = country;
    });
  }

  void _onPasswordChanged(String value) {
    if (_passwordError != null) {
      setState(() => _passwordError = null);
    }
  }

  void _onConfirmPasswordChanged(String value) {
    if (_confirmPasswordError != null) {
      setState(() => _confirmPasswordError = null);
    }
  }

  void _onRegisterPressed(BuildContext context) {
    _clearErrors();
    if (!_validateInputs()) return;

    context.read<AuthBloc>().add(
      RegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _fullPhoneNumber.isEmpty ? null : _fullPhoneNumber,
      ),
    );
  }

  void _onSocialRegisterPressed(BuildContext context, SocialProvider provider) {
    _showComingSoonDialog(provider.name);
  }

  void _onLoginPressed() {
    Navigator.of(context, rootNavigator: true).pushNamed('/login');
  }

  // VALIDATION

  void _clearErrors() {
    setState(() {
      _fullNameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });
  }

  bool _validateInputs() {
    bool isValid = true;

    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      setState(() => _fullNameError = 'El nombre completo es requerido');
      isValid = false;
    } else if (fullName.length < 2) {
      setState(
        () => _fullNameError = 'El nombre debe tener al menos 2 caracteres',
      );
      isValid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'El correo electrónico es requerido');
      isValid = false;
    } else if (!_isValidEmail(email)) {
      setState(
        () => _emailError = 'Por favor ingresa un correo electrónico válido',
      );
      isValid = false;
    }

    if (_fullPhoneNumber.isNotEmpty &&
        !_isValidInternationalPhone(_fullPhoneNumber)) {
      setState(() => _phoneError = 'Formato de teléfono inválido');
      isValid = false;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'La contraseña es requerida');
      isValid = false;
    } else if (password.length < 8) {
      setState(
        () => _passwordError = 'La contraseña debe tener al menos 8 caracteres',
      );
      isValid = false;
    } else if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]',
    ).hasMatch(password)) {
      setState(
        () => _passwordError =
            'Por tu seguridad, la contraseña debe incluir mayúsculas, minúsculas, números y símbolos',
      );
      isValid = false;
    }

    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirma tu contraseña');
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Las contraseñas no coinciden');
      isValid = false;
    }

    return isValid;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  bool _isValidInternationalPhone(String phone) {
    return InternationalPhoneNumberDomainService.isValidInternationalPhoneNumber(
      phone,
    );
  }

  // STATE MANAGEMENT

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (state is AuthError) {
      _handleAuthError(state.message);
    }
  }

  void _handleAuthError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error de Registro'),
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
        content: Text('El registro con $feature estará disponible pronto.'),
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
