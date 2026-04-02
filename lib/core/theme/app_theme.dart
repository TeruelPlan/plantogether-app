import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF1A6B9A); // Ocean Voyage

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    fontFamily: 'Inter',
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Inter',
  );
}
