import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      bodyLarge: const TextStyle(fontSize: 20),
      bodyMedium: const TextStyle(fontSize: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      bodyLarge: const TextStyle(fontSize: 20),
      bodyMedium: const TextStyle(fontSize: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
    ),
  );
}
