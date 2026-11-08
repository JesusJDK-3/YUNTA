import 'package:flutter/material.dart';

abstract final class YuntaColors {
  static const canvas = Color(0xFFF4FAFF);
  static const surface = Color(0xFFFBFEFD);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const surfaceBlue = Color(0xFFE7F6FF);
  static const surfaceMint = Color(0xFFE3F5EF);
  static const surfaceMintStrong = Color(0xFFB8E9C0);
  static const ink = Color(0xFF1A5268);
  static const inkStrong = Color(0xFF001F2A);
  static const primary = Color(0xFF006971);
  static const action = Color(0xFF05A8B5);
  static const actionPressed = Color(0xFF078089);
  static const accent = Color(0xFF09C8D0);
  static const mint = Color(0xFF82DDCD);
  static const muted = Color(0xFF3D494A);
  static const outline = Color(0xFF6D797B);
  static const outlineSoft = Color(0xFFBCC9CB);
  static const danger = Color(0xFFA13D42);
  static const dangerSoft = Color(0xFFFFE8E5);
  static const success = Color(0xFF27724A);
  static const successSoft = Color(0xFFE3F4E8);
  static const registrationCanvas = Color(0xFFF1FAF5);
  static const registrationField = Color(0xFFEBF5F2);
  static const registrationSky = Color(0xFFD8F0FC);
}

abstract final class YuntaTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: YuntaColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: YuntaColors.primary,
          onPrimary: Colors.white,
          primaryContainer: YuntaColors.action,
          onPrimaryContainer: YuntaColors.inkStrong,
          secondary: YuntaColors.action,
          onSecondary: YuntaColors.inkStrong,
          secondaryContainer: YuntaColors.surfaceMint,
          onSecondaryContainer: YuntaColors.inkStrong,
          tertiary: YuntaColors.mint,
          onTertiary: YuntaColors.inkStrong,
          error: YuntaColors.danger,
          onError: Colors.white,
          surface: YuntaColors.surface,
          onSurface: YuntaColors.inkStrong,
          surfaceContainerLowest: YuntaColors.surfaceWhite,
          surfaceContainerLow: YuntaColors.canvas,
          surfaceContainer: YuntaColors.surfaceBlue,
          surfaceContainerHigh: const Color(0xFFDAF1FF),
          onSurfaceVariant: YuntaColors.muted,
          outline: YuntaColors.outline,
          outlineVariant: YuntaColors.outlineSoft,
          surfaceTint: YuntaColors.primary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: YuntaColors.canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: YuntaColors.canvas,
        foregroundColor: YuntaColors.ink,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: YuntaColors.inkStrong,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: YuntaColors.inkStrong,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          height: 1.22,
          letterSpacing: -0.45,
        ),
        headlineSmall: TextStyle(
          color: YuntaColors.inkStrong,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          color: YuntaColors.inkStrong,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          color: YuntaColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
        bodyLarge: TextStyle(color: YuntaColors.ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
          color: YuntaColors.muted,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: YuntaColors.muted,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: YuntaColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          color: YuntaColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: YuntaColors.surfaceWhite,
        hintStyle: const TextStyle(color: YuntaColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: _inputBorder(YuntaColors.outlineSoft),
        enabledBorder: _inputBorder(YuntaColors.outline),
        focusedBorder: _inputBorder(YuntaColors.primary, width: 2),
        errorBorder: _inputBorder(YuntaColors.danger, width: 1.5),
        focusedErrorBorder: _inputBorder(YuntaColors.danger, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: YuntaColors.action,
          foregroundColor: YuntaColors.inkStrong,
          disabledBackgroundColor: YuntaColors.surfaceBlue,
          disabledForegroundColor: YuntaColors.muted,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: YuntaColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: YuntaColors.primary, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: YuntaColors.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: YuntaColors.surfaceWhite,
        selectedColor: YuntaColors.primary,
        disabledColor: YuntaColors.surfaceBlue,
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(color: YuntaColors.inkStrong),
        secondaryLabelStyle: const TextStyle(color: YuntaColors.inkStrong),
        side: const BorderSide(color: YuntaColors.outlineSoft),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: YuntaColors.action,
        foregroundColor: YuntaColors.inkStrong,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: YuntaColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: YuntaColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dividerTheme: const DividerThemeData(
        color: YuntaColors.outlineSoft,
        thickness: 0.7,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: YuntaColors.primary,
        linearTrackColor: YuntaColors.surfaceBlue,
        circularTrackColor: YuntaColors.surfaceBlue,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: YuntaColors.inkStrong,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: YuntaColors.primary,
        selectionColor: YuntaColors.accent.withValues(alpha: .25),
        selectionHandleColor: YuntaColors.primary,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
