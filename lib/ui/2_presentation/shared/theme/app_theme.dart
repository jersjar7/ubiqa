// lib/ui/2_presentation/shared/theme/app_theme.dart

import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Ubiqa App Theme Configuration
///
/// Pure Cupertino theme for Peru real estate market.
/// Individual widgets are styled directly using AppColors and AppTextStyles.
class AppTheme {
  /// Main app theme data for CupertinoApp
  static CupertinoThemeData get theme => CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    primaryContrastingColor: AppColors.background,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.backgroundSecondary,
    textTheme: _buildTextTheme(),
  );

  /// Text theme for Cupertino widgets
  static CupertinoTextThemeData _buildTextTheme() => CupertinoTextThemeData(
    primaryColor: AppColors.primary,
    textStyle: AppTextStyles.body,
    actionTextStyle: AppTextStyles.buttonPrimary,
    tabLabelTextStyle: AppTextStyles.caption1,
    navTitleTextStyle: AppTextStyles.title1,
    navLargeTitleTextStyle: AppTextStyles.largeTitle,
    navActionTextStyle: AppTextStyles.buttonSecondary,
    pickerTextStyle: AppTextStyles.body,
    dateTimePickerTextStyle: AppTextStyles.body,
  );
}
