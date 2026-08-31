import 'package:flutter/material.dart';

/// Centralized, high-contrast, state-of-the-art Luxury Design Palette for GearTrack
class AppColors {
  // --- PRIMARY BRAND ACCENTS (Deep -> Light -> Deep Gradient) ---
  /// Light Theme: Deep Indigo -> Luminous Highlight -> Deep Royal Cobalt
  static const List<Color> primaryGradientLight = [
    Color(0xFF3730A3), // Deep Indigo (Deep)
    Color(0xFF6366F1), // Electric Indigo (Light)
    Color(0xFF1E40AF), // Deep Royal Blue (Deep)
  ];

  /// Dark Theme: Deep Indigo -> Bright Luminous Indigo -> Deep Royal Blue
  static const List<Color> primaryGradientDark = [
    Color(0xFF4338CA), // Deep Indigo (Deep)
    Color(0xFF818CF8), // Bright Indigo (Light)
    Color(0xFF1D4ED8), // Deep Royal Blue (Deep)
  ];

  /// Primary button / interactive tint in light mode
  static const Color primaryButtonLight = Color(0xFF4F46E5);

  /// Primary button / interactive tint in dark mode
  static const Color primaryButtonDark = Color(0xFF6366F1);

  /// Button foreground text/icon color
  static const Color buttonForeground = Colors.white;

  // --- LUXURY NEUTRAL SURFACES ---
  /// Light Theme Background (Crisp, modern Slate-50)
  static const Color backgroundLight = Color(0xFFF8FAFC);

  /// Light Theme Card / Sheet Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Light Theme Secondary / Filter container
  static const Color surfaceContainerLight = Color(0xFFF1F5F9);

  /// Light Theme Hairline Border
  static const Color borderLight = Color(0xFFE2E8F0);

  /// Dark Theme Background (Deep Obsidian Space-950)
  static const Color backgroundDark = Color(0xFF090D16);

  /// Dark Theme Card Surface (Elevated Midnight Slate)
  static const Color surfaceDark = Color(0xFF111827);

  /// Dark Theme Secondary Container
  static const Color surfaceContainerDark = Color(0xFF1E293B);

  /// Dark Theme Hairline Border
  static const Color borderDark = Color(0xFF334155);

  // --- SEMANTIC FUNCTIONAL ACCENTS ---
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Rose-500
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9); // Sky-500

  // --- DYNAMIC THEME-AWARE HELPERS ---
  static LinearGradient primaryGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark ? primaryGradientDark : primaryGradientLight,
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static Color primaryButton(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryButtonDark
        : primaryButtonLight;
  }
}
