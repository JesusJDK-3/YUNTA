import 'package:flutter/material.dart';

abstract final class YuntaColors {
  static const ink = Color(0xFF245062);
  static const inkStrong = Color(0xFF193D4B);
  static const yellow = Color(0xFFF3D76F);
  static const yellowPressed = Color(0xFFEBCB5C);
  static const yellowPale = Color(0xFFFFF3C5);
  static const canvas = Color(0xFFFFFFFF);
  static const outline = Color(0xFFB8C9CE);
  static const muted = Color(0xFF526B73);
  static const danger = Color(0xFFA13D42);
}

abstract final class YuntaTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: YuntaColors.ink,
      brightness: Brightness.light,
      primary: YuntaColors.ink,
      onPrimary: Colors.white,
      secondary: YuntaColors.yellow,
      onSecondary: YuntaColors.inkStrong,
      surface: YuntaColors.canvas,
      onSurface: YuntaColors.inkStrong,
      outline: YuntaColors.outline,
      error: YuntaColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: YuntaColors.canvas,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: YuntaColors.inkStrong,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          height: 1.08,
        ),
        headlineSmall: TextStyle(
          color: YuntaColors.inkStrong,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: YuntaColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: YuntaColors.ink, fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(
          color: YuntaColors.muted,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: YuntaColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: YuntaColors.outline, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: YuntaColors.outline, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: YuntaColors.ink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: YuntaColors.danger, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: YuntaColors.yellow,
          foregroundColor: YuntaColors.inkStrong,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YuntaColors.ink,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: YuntaColors.ink, width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
