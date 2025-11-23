import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Modern Focus - Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Soft off-white with hint of blue
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF667EEA), // Modern Vibrant Purple
      secondary: Color(0xFF764BA2), // Deep Purple accent
      surface: Colors.white,
      background: Color(0xFFF5F7FA),
      onBackground: Color(0xFF1A202C),
      onSurface: Color(0xFF1A202C),
      tertiary: Color(0xFF4FACFE), // Bright blue for accents
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF8F9FA),
      foregroundColor: const Color(0xFF2C3E50),
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.libreBaskerville(
        color: const Color(0xFF2C3E50),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF667EEA),
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.libreBaskerville(
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.libreBaskerville(
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.libreBaskerville(
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.lato(
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.lato(
        color: const Color(0xFF2C3E50),
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.lato(
        color: const Color(0xFF2C3E50),
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.lato(
        color: const Color(0xFF455A64),
        fontSize: 14,
      ),
    ),
  );

  // Modern Focus - Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F1E), // Deep blue-black
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B9DFF), // Soft lavender blue
      secondary: Color(0xFFB794F6), // Soft purple
      surface: Color(0xFF1A1A2E),
      background: Color(0xFF0F0F1E),
      onBackground: Color(0xFFE5E7EB),
      onSurface: Color(0xFFE5E7EB),
      tertiary: Color(0xFF66D9EF),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF121212),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.libreBaskerville(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      color: const Color(0xFF1E1E1E),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF90CAF9),
        foregroundColor: const Color(0xFF121212),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF8B9DFF),
      foregroundColor: const Color(0xFF0F0F1E),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.libreBaskerville(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.libreBaskerville(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.libreBaskerville(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.lato(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.lato(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.lato(
        color: const Color(0xFFE0E0E0),
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.lato(
        color: const Color(0xFFB0BEC5),
        fontSize: 14,
      ),
    ),
  );
}
