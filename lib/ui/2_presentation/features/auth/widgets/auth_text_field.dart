// lib/ui/2_presentation/features/auth/widgets/auth_text_field.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

/// Authentication Text Field Widget
///
/// Cupertino-styled text field for auth forms with validation support.
/// Handles email, password, and general text input with proper styling.
class AuthTextField extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? errorText;
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode; // Allow external focus node
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool isPassword;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;

  const AuthTextField({
    super.key,
    this.label,
    this.placeholder,
    this.errorText,
    this.initialValue,
    this.controller,
    this.focusNode, // Add this parameter
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.isPassword = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.prefix,
    this.suffix,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode; // Properly managed focus node
  late bool _obscureText;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode(); // Use provided or create new
    _obscureText = widget.isPassword;

    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }

    // Add focus listener properly
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // Remove listener before disposing
    _focusNode.removeListener(_onFocusChange);

    // Only dispose if we created the focus node
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    // Only dispose controller if we created it
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.formLabel),
          const SizedBox(height: 6.0),
        ],

        // Text Field Container
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.backgroundSecondary
                : AppColors.backgroundDisabled,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _getBorderColor(),
              width: _hasFocus ? 2.0 : 1.0,
            ),
          ),
          child: CupertinoTextField(
            controller: _controller,
            focusNode: _focusNode, // Use the properly managed focus node
            placeholder: widget.placeholder,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: _obscureText,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            style: widget.enabled
                ? AppTextStyles.formInput
                : AppTextStyles.disabled(AppTextStyles.formInput),
            placeholderStyle: AppTextStyles.formPlaceholder,
            decoration: const BoxDecoration(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            prefix: widget.prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: widget.prefix,
                  )
                : null,
            suffix: _buildSuffix(),
            onChanged: widget.onChanged,
            onEditingComplete: widget.onEditingComplete,
            onSubmitted: widget.onSubmitted,
            // Remove the onTap handler - focus is managed by FocusNode
          ),
        ),

        // Error Text
        if (widget.errorText != null) ...[
          const SizedBox(height: 6.0),
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
                  widget.errorText!,
                  style: AppTextStyles.error.copyWith(fontSize: 12.0),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffix() {
    Widget? suffixWidget;

    // Password visibility toggle
    if (widget.isPassword) {
      suffixWidget = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: widget.enabled ? _togglePasswordVisibility : null,
        minimumSize: const Size(0, 0),
        child: Icon(
          _obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
          size: 20.0,
          color: widget.enabled
              ? AppColors.textSecondary
              : AppColors.textDisabled,
        ),
      );
    } else if (widget.suffix != null) {
      suffixWidget = widget.suffix;
    }

    return suffixWidget != null
        ? Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: suffixWidget,
          )
        : null;
  }

  Color _getBorderColor() {
    if (!widget.enabled) {
      return AppColors.borderDisabled;
    }
    if (widget.errorText != null) {
      return AppColors.error;
    }
    if (_hasFocus) {
      return AppColors.primary;
    }
    return AppColors.border;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  // FIXED: Proper focus change handling
  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode
          .hasFocus; // Use focusNode.hasFocus instead of controller.selection
    });
  }
}

// PREDEFINED AUTH TEXT FIELD VARIANTS

/// Email text field with proper configuration
class EmailTextField extends StatelessWidget {
  final String? label;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const EmailTextField({
    super.key,
    this.label,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      label: label ?? 'Email',
      placeholder: 'Ingresa tu correo electronico',
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
      ],
      prefix: Icon(
        CupertinoIcons.mail,
        size: 20.0,
        color: AppColors.textSecondary,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

/// Password text field with visibility toggle
class PasswordTextField extends StatelessWidget {
  final String? label;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isConfirmPassword;

  const PasswordTextField({
    super.key,
    this.label,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.isConfirmPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      label:
          label ?? (isConfirmPassword ? 'Confirmar contraseña' : 'Contraseña'),
      placeholder: isConfirmPassword
          ? 'Confirma tu contraseña'
          : 'Ingresa tu contraseña',
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: isConfirmPassword
          ? TextInputAction.done
          : TextInputAction.next,
      isPassword: true,
      prefix: Icon(
        CupertinoIcons.lock,
        size: 20.0,
        color: AppColors.textSecondary,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

/// Full name text field with proper configuration
class FullNameTextField extends StatelessWidget {
  final String? label;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const FullNameTextField({
    super.key,
    this.label,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      label: label ?? 'Nombre completo',
      placeholder: 'Ingresa tu nombre completo',
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      enabled: enabled,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ\s]')),
      ],
      prefix: Icon(
        CupertinoIcons.person,
        size: 20.0,
        color: AppColors.textSecondary,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
