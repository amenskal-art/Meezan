import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MEEZAN visual identity: deep judicial navy + scales-of-justice gold,
/// Cairo typeface (excellent Arabic + Kurdish + Latin coverage).
class MeezanTheme {
  static const navy = Color(0xFF122B45);
  static const navyDark = Color(0xFF0C1F33);
  static const gold = Color(0xFFC9A24B);
  static const goldLight = Color(0xFFE8D19A);
  static const paper = Color(0xFFF7F5F0);
  static const ink = Color(0xFF1C2530);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        primary: navy,
        secondary: gold,
        surface: paper,
      ),
      scaffoldBackgroundColor: paper,
    );
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(bodyColor: ink),
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.cairo(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: const CardThemeData(
        elevation: 1.5,
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: navyDark,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD8D2C4)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: goldLight,
        labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
