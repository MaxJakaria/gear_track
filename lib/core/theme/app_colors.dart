import 'package:flutter/material.dart';

/// Centralized theme-adaptive color & high-contrast gradient palette
class AppColors {
  /// High-Contrast Primary Gradient for Light Theme (Electric Indigo to Royal Blue)
  static const List<Color> primaryGradientLight = [
    Color(0xFF6366F1), // Electric Indigo / Violet
    Color(0xFF2563EB), // Vivid Royal Blue
  ];

  /// High-Contrast Primary Gradient for Dark Theme (Bright Lavender Indigo to Azure Blue)
  static const List<Color> primaryGradientDark = [
    Color(0xFF818CF8), // Bright Lavender Indigo
    Color(0xFF3B82F6), // Bright Azure Blue
  ];

  /// Primary Button Color for Light Theme
  static const Color primaryButtonLight = Color(0xFF4F46E5);

  /// Primary Button Color for Dark Theme
  static const Color primaryButtonDark = Color(0xFF6366F1);

  /// Default text/icon color on primary buttons
  static const Color buttonForeground = Colors.white;

  /// Dynamic Theme-Aware High-Contrast Primary LinearGradient
  static LinearGradient primaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark ? primaryGradientDark : primaryGradientLight,
    );
  }

  /// Dynamic Theme-Aware Primary Button Color
  static Color primaryButton(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryButtonDark
        : primaryButtonLight;
  }
}
