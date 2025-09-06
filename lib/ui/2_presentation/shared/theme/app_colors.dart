// lib/ui/2_presentation/shared/theme/app_colors.dart

import 'package:flutter/cupertino.dart';

/// Ubiqa App Color Palette
///
/// Inspired by Zillow's design with Cupertino adaptations.
/// Single light theme optimized for Peru real estate market.
class AppColors {
  // BRAND COLORS

  /// Primary brand blue - used for CTAs, links, active states
  static const Color primary = Color(0xFF007AFF); // CupertinoColors.activeBlue

  /// Secondary brand blue - used for secondary actions, highlights
  static const Color secondary = Color(
    0xFF5AC8FA,
  ); // CupertinoColors.systemBlue

  /// Accent orange - used for price tags, special offers, notifications
  static const Color accent = Color(0xFFFF9500); // CupertinoColors.systemOrange

  // BACKGROUND COLORS

  /// Main app background - pure white for clean property photos
  static const Color background = Color(
    0xFFFFFFFF,
  ); // CupertinoColors.systemBackground

  /// Secondary background - light gray for sections, cards
  static const Color backgroundSecondary = Color(
    0xFFF2F2F7,
  ); // CupertinoColors.systemGroupedBackground

  /// Tertiary background - grouped content background
  static const Color backgroundTertiary = Color(
    0xFFFFFFFF,
  ); // CupertinoColors.tertiarySystemGroupedBackground

  /// Surface color for cards, modals
  static const Color surface = Color(0xFFFFFFFF);

  // TEXT COLORS

  /// Primary text - dark for high contrast readability
  static const Color textPrimary = Color(0xFF000000); // CupertinoColors.label

  /// Secondary text - medium gray for descriptions, metadata
  static const Color textSecondary = Color(
    0xFF8E8E93,
  ); // CupertinoColors.secondaryLabel

  /// Tertiary text - light gray for captions, disclaimers
  static const Color textTertiary = Color(
    0xFFC7C7CC,
  ); // CupertinoColors.tertiaryLabel

  /// Placeholder text - form fields, search bars
  static const Color textPlaceholder = Color(
    0xFF8E8E93,
  ); // CupertinoColors.placeholderText

  // SEMANTIC COLORS

  /// Success green - verification, completed actions
  static const Color success = Color(0xFF30D158); // CupertinoColors.systemGreen

  /// Warning orange - alerts, pending actions
  static const Color warning = Color(
    0xFFFF9500,
  ); // CupertinoColors.systemOrange

  /// Error red - validation errors, failed actions
  static const Color error = Color(0xFFFF3B30); // CupertinoColors.systemRed

  /// Info blue - informational messages, tips
  static const Color info = Color(0xFF007AFF); // CupertinoColors.activeBlue

  // BORDER & SEPARATOR COLORS

  /// Primary borders - form fields, buttons
  static const Color border = Color(0xFFE5E5EA); // CupertinoColors.separator

  /// Opaque separator - list dividers, section breaks
  static const Color separatorOpaque = Color(
    0xFFC6C6C8,
  ); // CupertinoColors.opaqueSeparator

  /// Non-opaque separator - subtle dividers
  static const Color separator = Color(0x4C3C3C43); // CupertinoColors.separator

  // OVERLAY COLORS

  /// Modal background overlay
  static const Color overlay = Color(0x66000000);

  /// Loading indicator background
  static const Color loadingOverlay = Color(0x33000000);

  // PROPERTY-SPECIFIC COLORS

  /// Price highlight - property prices, cost emphasis
  static const Color priceHighlight = Color(0xFFFF6B35);

  /// Availability green - available properties
  static const Color available = Color(0xFF30D158);

  /// Unavailable gray - sold/rented properties
  static const Color unavailable = Color(0xFF8E8E93);

  /// Featured gold - premium listings
  static const Color featured = Color(0xFFFFD60A);

  // DISABLED STATES

  /// Disabled text color
  static const Color textDisabled = Color(0xFFC7C7CC);

  /// Disabled background color
  static const Color backgroundDisabled = Color(0xFFF2F2F7);

  /// Disabled border color
  static const Color borderDisabled = Color(0xFFE5E5EA);

  // HELPER METHODS

  /// Get color with opacity for overlays
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get appropriate text color for background
  static Color getTextOnColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : background;
  }
}
