import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Calm Minimal palette aligned with the design spec
  static const Color primaryColor = Color(0xFF0F6B5C); // Teal
  static const Color secondaryColor = Color(0xFFD8B36A); // Soft gold
  static const Color backgroundColor = Color(0xFFF9F7F2); // Cream white
  static const Color surfaceColor = Colors.white;
  static const Color darkBackgroundColor = Color(0xFF0E1414); // Blue-black
  static const Color darkSurfaceColor = Color(0xFF1A2022);
  static const Color dividerColor = Color(0xFFE8E4DB);
  static const Color sepiaBackgroundColor = Color(0xFFF6EEDB);
  static const Color sepiaSurfaceColor = Color(0xFFFFF7E8);
  static const Color sepiaTextColor = Color(0xFF3A2D20);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSurface: Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF101314),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF101314),
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF101314),
        ),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        bodyMedium: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
        labelMedium: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurfaceColor,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme:
          DividerThemeData(color: Colors.white.withValues(alpha: 0.08)),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(fontSize: 16),
        bodyMedium: GoogleFonts.poppins(fontSize: 15),
        labelMedium: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Colors.white70),
        ),
      ),
    );
  }

  static ThemeData get sepiaTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: sepiaBackgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: sepiaSurfaceColor,
        onPrimary: Colors.white,
        onSurface: sepiaTextColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: sepiaBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.poppins(
          color: sepiaTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: sepiaSurfaceColor,
        surfaceTintColor: sepiaSurfaceColor,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE6DBC6),
        thickness: 1,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: sepiaTextColor,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: sepiaTextColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: sepiaTextColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 15,
          color: sepiaTextColor,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          color: sepiaTextColor.withValues(alpha: 0.7),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: sepiaSurfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
