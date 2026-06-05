import 'package:flutter/material.dart';
import 'app_colors.dart';

extension ColoredContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get text => isDark ? AppColors.darkText : AppColors.lightText;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
}
