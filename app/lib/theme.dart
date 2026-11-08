import 'package:flutter/material.dart';

/// Paleta de Yunta: fondo blanco, tinta azul y acción amarilla.
ThemeData yuntaTheme() {
  const ink = Color(0xFF245062);
  const action = Color(0xFF1B5C76);
  const yellow = Color(0xFFF3D76F);
  const brick = Color(0xFFA13D42);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: action,
      primary: action,
      onPrimary: Colors.white,
      secondary: yellow,
      surface: Colors.white,
      error: brick,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink, fontSizeFactor: 1),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    ),
  );
}
