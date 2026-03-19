import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF4F46E5); // Indigo-600
  static const _secondaryColor = Color(0xFF10B981); // Emerald-500

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    fontFamily: 'Inter',
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Inter',
  );
}
