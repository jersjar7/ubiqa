// lib/ui/2_presentation/features/auth/widgets/auth_button.dart

import 'package:flutter/cupertino.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

/// Primary authentication button
class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Widget? icon;
  final double? width;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || isLoading;

    return SizedBox(
      width: width,
      height: 48.0,
      child: CupertinoButton(
        onPressed: isDisabled ? null : onPressed,
        color: isDisabled ? AppColors.backgroundDisabled : AppColors.primary,
        borderRadius: BorderRadius.circular(8.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CupertinoActivityIndicator(
                      color: AppColors.background,
                      radius: 8.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    'Loading...',
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: isDisabled
                          ? AppColors.textDisabled
                          : AppColors.background,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8.0)],
                  Text(
                    text,
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: isDisabled
                          ? AppColors.textDisabled
                          : AppColors.background,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text button for navigation and secondary actions
class TextAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final Widget? icon;
  final Color? textColor;

  const TextAuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
    this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: enabled ? onPressed : null,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      minimumSize: Size(0, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6.0)],
          Text(
            text,
            style: AppTextStyles.buttonTertiary.copyWith(
              color: enabled
                  ? (textColor ?? AppColors.primary)
                  : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

/// Social authentication button for Google and Apple
class SocialAuthButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  const SocialAuthButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !enabled || isLoading;

    return Container(
      width: double.infinity,
      height: 48.0,
      decoration: BoxDecoration(
        color: isDisabled
            ? AppColors.backgroundDisabled
            : provider._backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: provider._borderColor, width: 1.0),
      ),
      child: CupertinoButton(
        onPressed: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(8.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: isLoading
            ? CupertinoActivityIndicator(
                color: provider._textColor,
                radius: 8.0,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  provider._icon,
                  const SizedBox(width: 12.0),
                  Text(
                    provider._text,
                    style: AppTextStyles.buttonPrimary.copyWith(
                      color: isDisabled
                          ? AppColors.textDisabled
                          : provider._textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum SocialProvider {
  google,
  apple;

  String get _text {
    switch (this) {
      case SocialProvider.google:
        return 'Continúa con Google';
      case SocialProvider.apple:
        return 'Continúa con Apple';
    }
  }

  Widget get _icon {
    switch (this) {
      case SocialProvider.google:
        return Image.asset(
          'assets/img/logos/google.webp',
          width: 20.0,
          height: 20.0,
        );
      case SocialProvider.apple:
        return Image.asset(
          'assets/img/logos/apple.webp',
          width: 40.0,
          height: 40.0,
        );
    }
  }

  Color get _backgroundColor {
    switch (this) {
      case SocialProvider.google:
        return AppColors.background;
      case SocialProvider.apple:
        return AppColors.textPrimary;
    }
  }

  Color get _textColor {
    switch (this) {
      case SocialProvider.google:
        return AppColors.textPrimary;
      case SocialProvider.apple:
        return AppColors.background;
    }
  }

  Color get _borderColor {
    switch (this) {
      case SocialProvider.google:
        return AppColors.border;
      case SocialProvider.apple:
        return AppColors.textPrimary;
    }
  }
}
