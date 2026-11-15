import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Stark Group Official Design Guideline Palette
  static const Color starkNavy = Color(0xFF002D62);
  static const Color starkNavyDark = Color(0xFF00224A);
  static const Color starkBlue = Color(0xFF0052CC);
  static const Color starkBlueDark = Color(0xFF0747A6);
  static const Color starkBlueLight = Color(0xFFDEEBFF);

  // Surface & Canvas
  static const Color canvas = Color(0xFFF4F6F9);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF8F9FA);

  // Typography Colors
  static const Color ink = Color(0xFF172B4D);
  static const Color mutedInk = Color(0xFF5E6C84);
  static const Color subtleInk = Color(0xFF7A869A);

  // Borders
  static const Color border = Color(0xFFDFE1E6);
  static const Color borderFocus = Color(0xFF0052CC);

  // Status Badges (as shown in the guideline mockup)
  static const Color statusConnectedBg = Color(0xFFE3FCEF);
  static const Color statusConnectedText = Color(0xFF006644);

  static const Color statusDisconnectedBg = Color(0xFFFFEBE6);
  static const Color statusDisconnectedText = Color(0xFFDE350B);

  static const Color statusDisabledBg = Color(0xFFF4F5F7);
  static const Color statusDisabledText = Color(0xFF5E6C84);

  // Legacy aliases for backward compatibility if referenced
  static const Color navy = starkNavy;
  static const Color teal = starkBlue;
  static const Color tealDark = starkBlueDark;
  static const Color tealLight = starkBlueLight;
  static const Color statusActive = statusConnectedText;
  static const Color statusActiveBg = statusConnectedBg;
  static const Color statusMaintenance = statusDisconnectedText;
  static const Color statusMaintenanceBg = statusDisconnectedBg;
  static const Color statusInactive = statusDisabledText;
  static const Color statusInactiveBg = statusDisabledBg;

  // Box Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A091E42),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x06091E42),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x18091E42),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: starkBlue,
      primary: starkBlue,
      onPrimary: Colors.white,
      secondary: starkNavy,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Inter',
      fontFamilyFallback: const [
        'Inter',
        '-apple-system',
        'BlinkMacSystemFont',
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'sans-serif',
      ],
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: ink,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: ink,
          fontSize: 14,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: mutedInk,
          fontSize: 13,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: subtleInk,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          color: mutedInk,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: ink, size: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: mutedInk, fontSize: 13),
        hintStyle: const TextStyle(color: subtleInk, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderFocus, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDE350B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDE350B), width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: starkBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: starkBlue,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: starkNavy,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
