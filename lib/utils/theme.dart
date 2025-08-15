// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Minimal, legible, high-contrast theme
/// - Big tap targets (≥56dp buttons)
/// - Clear typography scale
/// - Simple color system with one accent (red)
/// - WCAG-friendly contrast, accessible focus + states

class _AppColors {
  // Accent (kept red as requested)
  static const accent =
      Color(0xFFE11D48); // similar to redAccent, better contrast

  // Light neutrals
  static const lBg = Color(0xFFF8FAFC); // scaffold
  static const lSurface = Colors.white; // cards, fields
  static const lText = Color(0xFF0F172A); // primary text
  static const lTextMuted = Color(0xFF475569); // secondary text
  static const lBorder = Color(0xFFE2E8F0);

  // Dark neutrals
  static const dBg = Color(0xFF0B1220);
  static const dSurface = Color(0xFF111827);
  static const dText = Colors.white;
  static const dTextMuted = Color(0xFFCBD5E1);
  static const dBorder = Color(0xFF1F2937);

  // Feedback
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
}

/// Public: Light theme
ThemeData buildMinimalTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _AppColors.accent,
      brightness: Brightness.light,
      primary: _AppColors.accent,
      onPrimary: Colors.white,
      surface: _AppColors.lSurface,
      onSurface: _AppColors.lText,
      background: _AppColors.lBg,
      onBackground: _AppColors.lText,
      outline: _AppColors.lBorder,
      secondary: _AppColors.lTextMuted,
    ),
    scaffoldBackgroundColor: _AppColors.lBg,
  );

  return base.copyWith(
    textTheme: _textTheme(base.textTheme, isDark: false),
    appBarTheme: AppBarTheme(
      backgroundColor: _AppColors.lSurface,
      foregroundColor: _AppColors.lText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle:
          const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardTheme(
      color: _AppColors.lSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: _AppColors.lBorder,
      thickness: 1,
      space: 24,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: _AppColors.accent,
      textColor: _AppColors.lText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      horizontalTitleGap: 12,
      minLeadingWidth: 28,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _AppColors.lText,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _AppColors.lSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: _AppColors.lTextMuted),
      labelStyle: TextStyle(color: _AppColors.lTextMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _AppColors.lBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _AppColors.lBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _AppColors.accent, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(64, 56)), // ≥48dp tap
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
        shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        textStyle: const MaterialStatePropertyAll(
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(64, 56)),
        side: MaterialStatePropertyAll(BorderSide(color: _AppColors.lBorder)),
        shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        textStyle: const MaterialStatePropertyAll(
            TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ),
    ),
    iconTheme: const IconThemeData(size: 24),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: _AppColors.lTextMuted),
    ),
    switchTheme: const SwitchThemeData(
        thumbIcon: MaterialStatePropertyAll(Icon(Icons.circle))),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: _AppColors.lSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: _AppColors.accent.withOpacity(0.12),
      iconTheme: MaterialStatePropertyAll(
        IconThemeData(color: _AppColors.lText),
      ),
      labelTextStyle: MaterialStatePropertyAll(
        TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.lText),
      ),
    ),
  );
}

/// Public: Dark theme
ThemeData buildMinimalDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _AppColors.accent,
      brightness: Brightness.dark,
      primary: _AppColors.accent,
      surface: _AppColors.dSurface,
      onSurface: _AppColors.dText,
      background: _AppColors.dBg,
      onBackground: _AppColors.dText,
      outline: _AppColors.dBorder,
      secondary: _AppColors.dTextMuted,
    ),
    scaffoldBackgroundColor: _AppColors.dBg,
  );

  return base.copyWith(
    textTheme: _textTheme(base.textTheme, isDark: true),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardTheme(
      color: _AppColors.dSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: _AppColors.dBorder,
      thickness: 1,
      space: 24,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: _AppColors.accent,
      textColor: _AppColors.dText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      horizontalTitleGap: 12,
      minLeadingWidth: 28,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _AppColors.dSurface,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _AppColors.dSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: _AppColors.dTextMuted),
      labelStyle: TextStyle(color: _AppColors.dTextMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _AppColors.dBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _AppColors.dBorder),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _AppColors.accent, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(64, 56)),
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
        shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        textStyle: const MaterialStatePropertyAll(
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(64, 56)),
        side: MaterialStatePropertyAll(BorderSide(color: _AppColors.dBorder)),
        shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        textStyle: const MaterialStatePropertyAll(
            TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ),
    ),
    iconTheme: const IconThemeData(size: 24),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide(color: _AppColors.dTextMuted),
    ),
    switchTheme: const SwitchThemeData(
        thumbIcon: MaterialStatePropertyAll(Icon(Icons.circle))),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: _AppColors.dSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: _AppColors.accent.withOpacity(0.16),
      iconTheme:
          const MaterialStatePropertyAll(IconThemeData(color: Colors.white)),
      labelTextStyle: const MaterialStatePropertyAll(
        TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}

/// Shared typography tuned for readability across ages
TextTheme _textTheme(TextTheme base, {required bool isDark}) {
  final onBg = isDark ? _AppColors.dText : _AppColors.lText;
  final muted = isDark ? _AppColors.dTextMuted : _AppColors.lTextMuted;

  return base.copyWith(
    displayLarge:
        TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: onBg),
    headlineMedium:
        TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: onBg),
    titleLarge:
        TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: onBg),
    bodyLarge: TextStyle(fontSize: 18, height: 1.5, color: onBg),
    bodyMedium: TextStyle(fontSize: 16, height: 1.5, color: onBg),
    bodySmall: TextStyle(fontSize: 14, height: 1.45, color: muted),
    labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}
