import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaraTheme {
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color softPurple = Color(0xFF9575CD);
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color cardBackground = Color(0xFF1A1A1A);
  static const Color accentCyan = Color(0xFF00E5FF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepPurple,
        brightness: Brightness.dark,
        primary: deepPurple,
        secondary: accentCyan,
        surface: cardBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
