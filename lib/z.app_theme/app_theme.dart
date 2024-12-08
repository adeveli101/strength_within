import 'package:flutter/material.dart';

class AppTheme {
  // Temel Renk Paleti
  static const Color primaryRed = Color(0xFFFF0000);
  static const Color secondaryRed = Color(0xFFD3110E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF2C2C2C);
  static const Color warningColor = Color(0xFFEA0707);
  static const Color textColorSecondary = Color(0xFF757575);
  static const Color disabledColor = Color(0xFFBDBDBD);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFD200);
  static const Color errorRed = Color(0xFF801010);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentPurple = Color(0xFF9C27B0);

  // Metrik Değerler
  static const metrics = {
    'opacity': {
      'primary': 0.8,
      'secondary': 0.6,
      'shadow': 0.3,
      'card': 0.2,
    },
    'radius': {
      'small': 8.0,
      'medium': 12.0,
      'large': 20.0,
    },
    'padding': {
      'small': 8.0,
      'medium': 16.0,
      'large': 24.0,
    },
    'difficulty': {
      'padding': 8.0,
      'margin': 2.0,
      'starAngle': 0.1,
      'starBaseSize': 18.0,
      'starIncrement': 0.5,
      'baseOpacity': 0.6,
      'opacityIncrement': 0.07,
    }
  };

  // Getter metodları
  static double get paddingSmall => metrics['padding']!['small']!;
  static double get paddingMedium => metrics['padding']!['medium']!;
  static double get paddingLarge => metrics['padding']!['large']!;

  static double get borderRadiusSmall => metrics['radius']!['small']!;
  static double get borderRadiusMedium => metrics['radius']!['medium']!;
  static double get borderRadiusLarge => metrics['radius']!['large']!;

  // Opacity değerleri için getter'lar
  static double get primaryOpacity => metrics['opacity']!['primary']!;
  static double get secondaryOpacity => metrics['opacity']!['secondary']!;
  static double get shadowOpacity => metrics['opacity']!['shadow']!;
  static double get cardOpacity => metrics['opacity']!['card']!;

  // Difficulty değerleri için getter'lar
  static double get difficultyStarAngle => metrics['difficulty']!['starAngle']!;
  static double get difficultyStarBaseSize => metrics['difficulty']!['starBaseSize']!;
  static double get difficultyStarIncrement => metrics['difficulty']!['starIncrement']!;
  static double get difficultyBaseOpacity => metrics['difficulty']!['baseOpacity']!;
  static double get difficultyOpacityIncrement => metrics['difficulty']!['opacityIncrement']!;
  static const difficultyIndicatorStyle = {
    'padding': EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    'margin': EdgeInsets.symmetric(horizontal: 2),
    'angle': 0.1,
    'inactiveColor': Colors.white24,
  };

  // Gölge Renkleri
  static final shadowColor = Colors.black.withOpacity(metrics['opacity']!['shadow']!);
  static final cardShadowColor = primaryRed.withOpacity(metrics['opacity']!['card']!);

  // Gradyanlar
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, secondaryRed],
  );

  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardBackground, surfaceColor.withOpacity(metrics['opacity']!['primary']!)],
  );

  // Metin Stilleri
  static get _baseTextStyle => TextStyle(color: Colors.white);

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
  static const TextStyle bodyLarge = TextStyle(fontSize: 18, color: Colors.white);
  static const TextStyle bodyMedium = TextStyle(fontSize: 16, color: Colors.white70);
  static const TextStyle bodySmall = TextStyle(fontSize: 14, color: Colors.white70);

  // Kart Stilleri
  static BoxDecoration cardDecoration = BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(metrics['radius']!['large']!),
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

  // Zorluk Seviyeleri için Renkler
  static const Map<int, Color> difficultyColors = {
    1: Color(0xFF0D47A1),
    2: Color(0xFF4A148C),
    3: Color(0xFFE65100),
    4: Color(0xFFB71C1C),
    5: Color(0xFF590000),
    0: Color(0xFF212121),
  };

  static const Map<int, Color> difficultyBaseColors = {
    1: Color(0xFF00FFFF),
    2: Color(0xFFFF00FF),
    3: Color(0xFFFF8000),
    4: Color(0xFFFF2D2D),
    5: Color(0x86FF0000),
  };

  // Hedef bölge renkleri
  static const Map<int, Color> targetColors = {
    1: Color(0xFF00BFA5),
    2: Color(0xFF7C4DFF),
    3: Color(0xFFFF6D00),
    4: Color(0xFFD50000),
    5: Color(0xFF2962FF),
    0: primaryRed,
  };

  // Helper metodlar
  static LinearGradient getPartGradient({
    required int difficulty,
    required Color secondaryColor,
  }) {
    final primaryColor = difficultyColors[difficulty] ?? difficultyColors[0]!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        primaryColor.withOpacity(metrics['opacity']!['primary']!),
        secondaryColor.withOpacity(metrics['opacity']!['secondary']!),
      ],
    );
  }

  static Color getDifficultyColor(int difficulty) =>
      difficultyColors[difficulty] ?? Colors.grey[900]!;

  static Color getGlowingColor(int difficulty, int index) {
    final baseColor = difficultyBaseColors[difficulty] ?? const Color(0xFFCFD8DC);
    return baseColor.withOpacity(metrics['difficulty']!['baseOpacity']! +
        (index * metrics['difficulty']!['opacityIncrement']!));
  }

  static Color getTargetColor(int bodyPartId) =>
      targetColors[bodyPartId % 6] ?? primaryRed;

  // Ana Theme
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
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
        borderRadius: BorderRadius.circular(metrics['radius']!['large']!),
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


  // EdgeInsets factory metodları
  static EdgeInsets getPadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left ?? horizontal ?? all ?? paddingSmall,
      top: top ?? vertical ?? all ?? paddingSmall,
      right: right ?? horizontal ?? all ?? paddingSmall,
      bottom: bottom ?? vertical ?? all ?? paddingSmall,
    );
  }

  static BorderRadius getBorderRadius({
    double? all,
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft ?? all ?? borderRadiusSmall),
      topRight: Radius.circular(topRight ?? all ?? borderRadiusSmall),
      bottomLeft: Radius.circular(bottomLeft ?? all ?? borderRadiusSmall),
      bottomRight: Radius.circular(bottomRight ?? all ?? borderRadiusSmall),
    );
  }

  static BoxDecoration decoration({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,  // List yerine List<BoxShadow>
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? radius(all: borderRadiusSmall),
      boxShadow: shadows,
      gradient: gradient,
    );
  }

  static LinearGradient createGradient({
    required List<Color> colors,  // List yerine List<Color>
    List<double>? stops,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      stops: stops,
      colors: colors,
    );
  }

  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: paddingMedium,
      vertical: paddingSmall,
    ),
  );

  static const elevations = {
    'card': 4.0,
    'button': 2.0,
    'dialog': 8.0,
    'drawer': 16.0,
  };

  static const spacing = {
    'xxs': 4.0,
    'xs': 8.0,
    'sm': 12.0,
    'md': 16.0,
    'lg': 24.0,
    'xl': 32.0,
    'xxl': 48.0,
  };

// Sabit padding ve radius değerleri
  static const paddingValues = {
    'tiny': 4.0,      // En küçük boşluk
    'xSmall': 6.0,    // Çok küçük boşluk
    'small': 8.0,     // Küçük boşluk
    'medium': 12.0,   // Orta boşluk
    'large': 20.0,    // Büyük boşluk
    'xLarge': 24.0,   // Çok büyük boşluk
    'huge': 32.0,     // Dev boşluk
    'giant': 48.0,    // En büyük boşluk
  };

  static const radiusValues = {
    'tiny': 2.0,      // En küçük yuvarlaklık
    'xSmall': 4.0,    // Çok küçük yuvarlaklık
    'small': 6.0,     // Küçük yuvarlaklık
    'medium': 8.0,    // Orta yuvarlaklık
    'large': 12.0,    // Büyük yuvarlaklık
    'xLarge': 16.0,   // Çok büyük yuvarlaklık
    'huge': 24.0,     // Dev yuvarlaklık
    'circular': 999.0, // Tam yuvarlak
  };

// BorderRadius factory'leri
  static BorderRadius radius({
    double? all,
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft ?? all ?? borderRadiusSmall),
      topRight: Radius.circular(topRight ?? all ?? borderRadiusSmall),
      bottomLeft: Radius.circular(bottomLeft ?? all ?? borderRadiusSmall),
      bottomRight: Radius.circular(bottomRight ?? all ?? borderRadiusSmall),
    );
  }

  static const difficultyStarPadding = EdgeInsets.symmetric(
      horizontal: 8.0,
      vertical: 4.0
  );

  static const difficultyStarMargin = EdgeInsets.symmetric(
      horizontal: 2.0
  );

  static const difficultyIndicatorDecoration = BoxDecoration(
    color: Colors.black45,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  static const difficultyStarInactiveColor = Colors.white24;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 450;
  static const double tabletBreakpoint = 800;
  static const double desktopBreakpoint = 1920;


  static List<Widget> buildDifficultyStars(int difficulty) {
    return List.generate(
      5,
          (index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingSmall / 2),
        child: Transform.rotate(
          angle: difficultyStarAngle,
          child: Icon(
            Icons.star_sharp,
            color: getDifficultyStarColorWithIndex(difficulty, index),
            size: calculateDifficultyStarSize(index),
          ),
        ),
      ),
    );
  }

  static Color getDifficultyStarColorWithIndex(int difficulty, int index) {
    return index < difficulty
        ? getGlowingColor(difficulty, index)
        : difficultyStarInactiveColor;
  }

  static double calculateDifficultyStarSize(int index) {
    return difficultyStarBaseSize + (index * difficultyStarIncrement);
  }

  double _calculateStarSize(int index) {
    return AppTheme.difficultyStarBaseSize +
        (index * AppTheme.difficultyStarIncrement);
  }

}