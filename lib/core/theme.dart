import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF101010);
  static const Color accent = Color(0xFFE0E0E0);

  static ThemeData get zenMode {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: background,
      colorScheme: ColorScheme.dark(
        background: background,
        surface: background,
        primary: accent,
        onBackground: accent,
        onSurface: accent,
      ),
      textTheme: GoogleFonts.playfairDisplayTextTheme().apply(
        bodyColor: accent,
        displayColor: accent,
      ),
      useMaterial3: true,
    );
  }
}
