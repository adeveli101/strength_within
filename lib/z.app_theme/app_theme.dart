// lib/z.app_theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Ana Renkler
  static const Color primaryRed = Color(0xFFE53935);
  static const Color secondaryRed = Color(0xFFEF5350);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF2C2C2C);
  static const Color warningColor = Color(0xFFEA0707);
  static const Color textColorSecondary = Color(0xFF757575);
  static const Color disabledColor = Color(0xFFBDBDBD);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFD200);
  static const Color errorRed = Color(0xFF801010);



  // İkincil Renkler
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentGreen = Color(0xFF4CAF50);

  // Gölge Renkleri
  static final shadowColor = Colors.black.withOpacity(0.3);
  static final cardShadowColor = primaryRed.withOpacity(0.2);

  // Gradyanlar
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, secondaryRed],
  );

  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      cardBackground,
      surfaceColor.withOpacity(0.8),
    ],
  );

  // Metin Stilleri
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    color: Colors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  // Kart Stilleri
  static BoxDecoration cardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: cardShadowColor,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Progress Bar Stilleri
  static const progressBarHeight = 4.0;
  static final progressBarBackground = Colors.white.withOpacity(0.2);
  static const progressBarColor = Colors.white;

  // Animasyon Süreleri
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Border Radius Değerleri
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;

  // Padding Değerleri
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Ana Theme
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryRed,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: primaryRed),
    ),
    cardTheme: CardTheme(
      color: cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryRed,
      unselectedItemColor: Colors.grey,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryRed,
      linearTrackColor: Colors.white24,
    ),
    colorScheme: ColorScheme.dark(
      primary: primaryRed,
      secondary: secondaryRed,
      surface: surfaceColor,
      error: Colors.red.shade800,
    ),
    textTheme: const TextTheme(
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
    ),
  );

  // Zorluk Seviyeleri için Renkler ve Metinler
  static Color getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Başlangıç';
      case 2:
        return 'Orta Başlangıç';
      case 3:
        return 'Orta';
      case 4:
        return 'Orta İleri';
      case 5:
        return 'İleri';
      default:
        return 'Belirsiz';
    }
  }

  // Responsive Breakpoints
  static const double mobileBreakpoint = 450;
  static const double tabletBreakpoint = 800;
  static const double desktopBreakpoint = 1920;
}
