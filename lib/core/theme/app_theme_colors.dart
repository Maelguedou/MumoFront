import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppThemeColors {
  AppThemeColors(this.context);

  final BuildContext context;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get background =>
      isDark ? AppColors.blackBackground : AppColors.background;

  Color get surface => isDark ? AppColors.blackSurface : AppColors.surface;

  Color get surfaceElevated =>
      isDark ? AppColors.blackSurfaceElevated : AppColors.surface;

  Color get surfaceAlt =>
      isDark ? AppColors.blackSurfaceAlt : AppColors.surfaceAlt;

  Color get pressed => isDark ? AppColors.blackPressed : AppColors.surfaceAlt;

  Color get border => isDark ? AppColors.blackBorder : AppColors.borderLight;

  Color get textPrimary =>
      isDark ? AppColors.blackTextPrimary : AppColors.textPrimary;

  Color get textSecondary =>
      isDark ? AppColors.blackTextSecondary : AppColors.textSecondary;

  Color get textTertiary =>
      isDark ? AppColors.blackTextTertiary : AppColors.textTertiary;

  Color get primary => isDark ? AppColors.primaryDarkMode : AppColors.primary;

  Color get primarySoft =>
      isDark ? AppColors.primarySoftDark : AppColors.primarySoft;

  Color get primarySoftBorder =>
      isDark ? AppColors.primarySoftBorderDark : AppColors.primarySoftBorder;

  Color get successBg => isDark ? AppColors.successBgDark : AppColors.successBg;

  Color get pendingBg => isDark ? AppColors.pendingBgDark : AppColors.pendingBg;

  Color get errorBg => isDark ? AppColors.errorBgDark : AppColors.errorBg;

  Color get infoBg => isDark ? AppColors.infoBgDark : AppColors.infoBg;

  Color get warningBg => isDark ? AppColors.warningBgDark : AppColors.warningBg;

  Color get goldBg => isDark ? AppColors.warningBgDark : AppColors.goldBg;
}
