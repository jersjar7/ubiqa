// lib/ui/2_presentation/features/auth/pages/phone_verification_page.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import theme
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

// Import widgets
import '../widgets/auth_button.dart';

// Import domain
import '../../../../../models/1_domain/shared/value_objects/international_phone_number.dart';

// Import state management
import '../../../../1_state/features/auth/auth_bloc.dart';
import '../../../../1_state/features/auth/auth_event.dart';
import '../../../../1_state/features/auth/auth_state.dart';

// Import dependency injection
import '../../../../../services/5_injection/dependency_container.dart';

class PhoneVerificationPage extends StatefulWidget {
  final String phoneNumber;

  const PhoneVerificationPage({super.key, required this.phoneNumber});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  String? _errorText;
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
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
                  _buildHeader(),
                  const SizedBox(height: 40.0),
                  _buildCodeInput(),
                  const SizedBox(height: 32.0),
                  _buildVerifyButton(),
                  const SizedBox(height: 24.0),
                  _buildResendSection(),
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
      'assets/img/logos/oqupa-logo-tr-500x500.png',
      width: 350.0,
      height: 100.0,
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80.0,
          height: 80.0,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(40.0),
          ),
          child: Icon(
            CupertinoIcons.phone_fill,
            size: 40.0,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24.0),
        Text(
          'Verificar número',
          style: AppTextStyles.title2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Text(
          'Ingresa el código de 6 dígitos enviado a:',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        Text(
          _formatPhoneNumberForDisplay(widget.phoneNumber),
          style: AppTextStyles.callout.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildCodeField(index)),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 16.0),
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle_fill,
                size: 16.0,
                color: AppColors.error,
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  _errorText!,
                  style: AppTextStyles.error.copyWith(fontSize: 12.0),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCodeField(int index) {
    return Container(
      width: 45.0,
      height: 55.0,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _errorText != null ? AppColors.error : AppColors.border,
          width: 1.0,
        ),
      ),
      child: CupertinoTextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppTextStyles.title2,
        decoration: const BoxDecoration(),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onCodeChanged(index, value),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final code = _controllers.map((c) => c.text).join();

        return AuthButton(
          text: 'Verificar código',
          isLoading: isLoading,
          enabled: code.length == 6,
          width: double.infinity,
          onPressed: () => _onVerifyPressed(context),
        );
      },
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          '¿No recibiste el código?',
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8.0),
        if (_canResend)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onResendPressed,
            child: Text(
              'Reenviar código',
              style: AppTextStyles.callout.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Text(
            'Reenviar código en ${_resendCountdown}s',
            style: AppTextStyles.callout.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
      ],
    );
  }

  // EVENT HANDLERS

  void _onCodeChanged(int index, String value) {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      _onVerifyPressed(context);
    }
  }

  void _onVerifyPressed(BuildContext context) {
    final code = _controllers.map((c) => c.text).join();

    if (code.length != 6) {
      setState(() => _errorText = 'Ingresa el código completo de 6 dígitos');
      return;
    }

    context.read<AuthBloc>().add(
      VerifyPhoneRequested(
        phoneNumber: widget.phoneNumber,
        verificationCode: code,
      ),
    );
  }

  void _onResendPressed() {
    context.read<AuthBloc>().add(
      SendPhoneVerificationRequested(phoneNumber: widget.phoneNumber),
    );
    _startResendTimer();
    _showResendConfirmation();
  }

  // HELPERS

  String _formatPhoneNumberForDisplay(String phoneNumber) {
    try {
      final internationalPhone = InternationalPhoneNumber.create(
        phoneNumber: phoneNumber,
      );
      return internationalPhone.getFormattedPhoneNumberForDisplay();
    } catch (e) {
      // Fallback to basic masking if formatting fails
      return _maskPhoneNumber(phoneNumber);
    }
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length >= 10) {
      final start = phoneNumber.substring(0, 6);
      final end = phoneNumber.substring(phoneNumber.length - 3);
      return '$start XXX $end';
    }
    return phoneNumber;
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // STATE MANAGEMENT

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is PhoneVerificationSuccess) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (state is PhoneVerificationCodeSent) {
      _showResendConfirmation();
    } else if (state is AuthError) {
      _handleAuthError(state.message);
    }
  }

  void _handleAuthError(String message) {
    setState(() => _errorText = message);
    _clearCode();
  }

  void _showResendConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Código reenviado'),
        content: Text(
          'Se ha enviado un nuevo código a ${_formatPhoneNumberForDisplay(widget.phoneNumber)}',
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
