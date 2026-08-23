import 'package:flutter/material.dart';

import 'color_palette.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: ColorPalette.canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: ColorPalette.teal),
    appBarTheme: const AppBarTheme(
      backgroundColor: ColorPalette.ink,
      foregroundColor: Colors.white,
    ),
  );
}
