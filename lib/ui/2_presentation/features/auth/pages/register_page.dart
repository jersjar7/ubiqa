// lib/ui/2_presentation/features/auth/pages/register_page.dart

import 'package:flutter/cupertino.dart';
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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus Nodes for proper focus management
  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // Error states
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
    // Dispose controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Dispose focus nodes
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                _buildLoginPrompt(),
                const SizedBox(height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/img/logos/oqupa-logo-tr-500x500.png',
      width: 350.0,
      height: 100.0,
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
            // Full Name Field with Focus Node
            FullNameTextField(
              controller: _fullNameController,
              focusNode: _fullNameFocusNode,
              errorText: _fullNameError,
              onChanged: _onFullNameChanged,
              onSubmitted: (_) => _moveToNextField(_emailFocusNode),
            ),
            const SizedBox(height: 16.0),

            // Email Field with Focus Node
            AuthTextField(
              label: 'Correo electrónico',
              placeholder: 'Ingresa tu correo electrónico',
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailError,
              prefix: Icon(
                CupertinoIcons.mail,
                size: 20.0,
                color: AppColors.textSecondary,
              ),
              onChanged: _onEmailChanged,
              onSubmitted: (_) => _moveToNextField(_phoneFocusNode),
            ),
            const SizedBox(height: 16.0),

            // Phone Field with Focus Node
            InternationalPhoneField(
              focusNode: _phoneFocusNode,
              errorText: _phoneError,
              initialCountry: _selectedCountry,
              onPhoneChanged: _onPhoneChanged,
              onCountryChanged: _onCountryChanged,
              onSubmitted: (_) => _moveToNextField(_passwordFocusNode),
            ),
            const SizedBox(height: 16.0),

            // Password Field with Focus Node
            PasswordTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              errorText: _passwordError,
              onChanged: _onPasswordChanged,
              onSubmitted: (_) => _moveToNextField(_confirmPasswordFocusNode),
            ),
            const SizedBox(height: 16.0),

            // Confirm Password Field with Focus Node
            PasswordTextField(
              label: 'Confirmar contraseña',
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              errorText: _confirmPasswordError,
              isConfirmPassword: true,
              onChanged: _onConfirmPasswordChanged,
              onSubmitted: (_) => _onRegisterPressed(context),
            ),
            const SizedBox(height: 24.0),

            // Register Button
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

  // FOCUS MANAGEMENT

  /// Helper method to smoothly transition focus between fields
  void _moveToNextField(FocusNode nextFocusNode) {
    FocusScope.of(context).requestFocus(nextFocusNode);
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
    // Dismiss keyboard when register is pressed
    FocusScope.of(context).unfocus();

    _clearErrors();
    if (!_validateInputs()) return;

    context.read<AuthBloc>().add(
      RegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _fullPhoneNumber.isEmpty ? null : _fullPhoneNumber,
        countryCode: _selectedCountry,
      ),
    );
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
      Navigator.of(context, rootNavigator: true).pushReplacementNamed('/home');
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
}
