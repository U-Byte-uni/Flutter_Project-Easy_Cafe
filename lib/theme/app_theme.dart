import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Background: #0C0F14
  // Primary Orange/Brown: #D17842
  // Card/Surface: #141921
  
  static const Color backgroundColor = Color(0xFF0C0F14);
  static const Color primaryColor = Color(0xFFD17842);
  static const Color cardColor = Color(0xFF141921);
  static const Color secondaryTextColor = Color(0xFF52555A);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    cardColor: cardColor,
    
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      surface: cardColor,
      background: backgroundColor,
      secondary: secondaryTextColor,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF141921),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: secondaryTextColor),
    ),
  );
}
