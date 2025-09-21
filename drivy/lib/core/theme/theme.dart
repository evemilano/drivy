// FORCE-APPLYING THEME FIX: Correcting constructor types.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- App-specific colors ---
const Color primaryColor = Color(0xFF007AFF); // A vibrant blue
const Color secondaryColor = Color(0xFFFF9500); // A complementary orange
const Color successColor = Color(0xFF34C759); // For success states
const Color errorColor = Color(0xFFFF3B30); // For error states

const Color lightSurface = Color(0xFFFFFFFF);
const Color lightBackground = Color(0xFFF2F2F7);
const Color lightOnSurface = Color(0xFF000000);
const Color lightOnBackground = Color(0xFF000000);

const Color darkSurface = Color(0xFF1C1C1E);
const Color darkBackground = Color(0xFF000000);
const Color darkOnSurface = Color(0xFFFFFFFF);
const Color darkOnBackground = Color(0xFFFFFFFF);

// --- Light Theme ---
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: primaryColor,
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: lightSurface,
    error: errorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: lightOnSurface,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: lightBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: lightBackground,
    foregroundColor: lightOnBackground,
    elevation: 0,
    titleTextStyle: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: lightOnBackground,
    ),
  ),
  textTheme: _buildTextTheme(GoogleFonts.manropeTextTheme(), lightOnSurface),
  cardTheme: CardThemeData( // Corrected from CardTheme
    elevation: 0,
    color: lightSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  ),
  dialogTheme: DialogThemeData( // Corrected from DialogTheme
    backgroundColor: lightSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  ),
);

// --- Dark Theme ---
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: darkSurface,
    error: errorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: darkOnSurface,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: darkBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: darkBackground,
    foregroundColor: darkOnBackground,
    elevation: 0,
    titleTextStyle: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: darkOnBackground,
    ),
  ),
  textTheme: _buildTextTheme(GoogleFonts.manropeTextTheme(), darkOnSurface),
  cardTheme: CardThemeData( // Corrected from CardTheme
    elevation: 0,
    color: darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  ),
  dialogTheme: DialogThemeData( // Corrected from DialogTheme
    backgroundColor: darkSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  ),
);

// --- Helper to build TextTheme ---
TextTheme _buildTextTheme(TextTheme base, Color color) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
    displayMedium: base.displayMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
    displaySmall: base.displaySmall?.copyWith(color: color, fontWeight: FontWeight.bold),
    headlineLarge: base.headlineLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
    headlineMedium: base.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
    headlineSmall: base.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
    titleLarge: base.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
    titleSmall: base.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
    bodyLarge: base.bodyLarge?.copyWith(color: color, fontSize: 16),
    bodyMedium: base.bodyMedium?.copyWith(color: color, fontSize: 14),
    bodySmall: base.bodySmall?.copyWith(color: color, fontSize: 12),
    labelLarge: base.labelLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
    labelMedium: base.labelMedium?.copyWith(color: color),
    labelSmall: base.labelSmall?.copyWith(color: color),
  );
}
