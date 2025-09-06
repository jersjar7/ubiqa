// lib/ui/2_presentation/shared/theme/app_text_styles.dart

import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

/// Ubiqa App Text Styles
///
/// Follows iOS Human Interface Guidelines with Zillow-inspired hierarchy.
/// Optimized for property listings and real estate content readability.
class AppTextStyles {
  // DISPLAY STYLES - Major headings and hero text

  /// Large titles - app headers, welcome messages
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.374,
    height: 1.12,
    decoration: TextDecoration.none,
  );

  /// Main titles - page headers, section titles
  static const TextStyle title1 = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.364,
    height: 1.14,
    decoration: TextDecoration.none,
  );

  /// Secondary titles - subsection headers
  static const TextStyle title2 = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 0.352,
    height: 1.18,
    decoration: TextDecoration.none,
  );

  /// Tertiary titles - card headers, modal titles
  static const TextStyle title3 = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.38,
    height: 1.20,
    decoration: TextDecoration.none,
  );

  // CONTENT STYLES - Body text and reading content

  /// Headlines - emphasized content, important information
  static const TextStyle headline = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.408,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  /// Body text - main reading content, descriptions
  static const TextStyle body = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: -0.408,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  /// Callout text - slightly smaller emphasis
  static const TextStyle callout = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: -0.32,
    height: 1.31,
    decoration: TextDecoration.none,
  );

  /// Subheadline - secondary content
  static const TextStyle subheadline = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: -0.24,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  // UI ELEMENT STYLES - Interface components

  /// Footnotes - small details, metadata
  static const TextStyle footnote = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: -0.08,
    height: 1.38,
    decoration: TextDecoration.none,
  );

  /// Captions - image captions, fine print
  static const TextStyle caption1 = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: 0.0,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  /// Smaller captions - legal text, disclaimers
  static const TextStyle caption2 = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    letterSpacing: 0.066,
    height: 1.36,
    decoration: TextDecoration.none,
  );

  // BUTTON STYLES - Interactive elements

  /// Primary button text - main CTAs
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    color: AppColors.background,
    letterSpacing: -0.408,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  /// Secondary button text - secondary actions
  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: -0.408,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  /// Tertiary button text - subtle actions
  static const TextStyle buttonTertiary = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.normal,
    color: AppColors.primary,
    letterSpacing: -0.408,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  // FORM STYLES - Input and form elements

  /// Form labels - field labels, form headers
  static const TextStyle formLabel = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.32,
    height: 1.31,
    decoration: TextDecoration.none,
  );

  /// Form input text - user entered text
  static const TextStyle formInput = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    letterSpacing: -0.408,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  /// Form placeholder text - hints, examples
  static const TextStyle formPlaceholder = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textPlaceholder,
    letterSpacing: -0.408,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  /// Form helper text - validation, instructions
  static const TextStyle formHelper = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: -0.08,
    height: 1.38,
    decoration: TextDecoration.none,
  );

  // PROPERTY-SPECIFIC STYLES - Real estate content

  /// Property prices - emphasized pricing
  static const TextStyle propertyPrice = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.bold,
    color: AppColors.priceHighlight,
    letterSpacing: 0.352,
    height: 1.18,
    decoration: TextDecoration.none,
  );

  /// Property address - location emphasis
  static const TextStyle propertyAddress = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.24,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  /// Property details - specs, features
  static const TextStyle propertyDetails = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    letterSpacing: -0.154,
    height: 1.36,
    decoration: TextDecoration.none,
  );

  // SEMANTIC STYLES - Status and state indication

  /// Success text - confirmations, positive states
  static const TextStyle success = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    letterSpacing: -0.32,
    height: 1.31,
    decoration: TextDecoration.none,
  );

  /// Warning text - alerts, cautions
  static const TextStyle warning = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
    letterSpacing: -0.32,
    height: 1.31,
    decoration: TextDecoration.none,
  );

  /// Error text - validation errors, failures
  static const TextStyle error = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    letterSpacing: -0.32,
    height: 1.31,
    decoration: TextDecoration.none,
  );

  /// Info text - informational messages
  static const TextStyle info = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.info,
    letterSpacing: -0.32,
    height: 1.31,
    decoration: TextDecoration.none,
  );

  // UTILITY METHODS

  /// Apply color override to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight override to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply size override to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  /// Create disabled version of text style
  static TextStyle disabled(TextStyle style) {
    return style.copyWith(color: AppColors.textDisabled);
  }
}
