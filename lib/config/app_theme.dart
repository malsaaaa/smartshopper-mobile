import 'package:flutter/material.dart';

/// AppTheme defines the design system for SmartShopper
/// Colors, typography, spacing, and other styling constants
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============== SPACING ==============
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ============== BORDER RADIUS ==============
  static const double borderRadiusInput = 8.0;
  static const double borderRadiusCard = 12.0;

  // ============== COLORS - PRIMARY ==============
  static const Color primary = Color(0xFF00D084);     // Bright Emerald
  static const Color primaryLight = Color(0xFFD4F5EA); // Light mint
  static const Color primaryDark = Color(0xFF00A862);  // Deep emerald

  // ============== COLORS - SECONDARY ==============
  static const Color secondary = Color(0xFFFF6B35);    // Warm Orange
  static const Color secondaryLight = Color(0xFFFFEEDF);
  static const Color secondaryDark = Color(0xFFE85D04);

  // ============== COLORS - ACCENT ==============
  static const Color accentOrange = Color(0xFFFF6B35); // Warm Orange
  static const Color accentOrangeLight = Color(0xFFFFE8DD);
  static const Color accentYellow = Color(0xFFFFD60A); // Golden Yellow
  static const Color accentBlue = Color(0xFF4D7DFF);   // Modern Blue

  // ============== COLORS - STATUS ==============
  static const Color success = Color(0xFF00D084);
  static const Color warning = Color(0xFFFF6B35);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF4D7DFF); // Modern blue

  // ============== COLORS - NEUTRAL ==============
  // Neutral backgrounds with a subtle green hue
  static const Color surface = Color(0xFFF7FFFA);
  static const Color background = Color(0xFFF2FFF7); // page background with gentle green hue
  static const Color surfaceVariant = Color(0xFFEFF8F0);

  static const Color textPrimary = Color(0xFF1A2E1F);  // Dark navy-black
  static const Color textSecondary = Color(0xFF6B7280); // Modern grey
  static const Color textTertiary = Color(0xFFD1D5DB);
  static const Color divider = Color(0xFFE5E7EB);       // Modern light grey divider

  // ============== COLORS - SPECIAL ==============
  static const Color bestPrice = Color(0xFF00D084);
  static const Color bestPriceLight = Color(0xFFD4F5EA);
  static const Color salePrice = Color(0xFFFF6B35);     // Warm orange for sales

  // ============== LIGHT THEME ==============
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing12,
        ),
        hintStyle: const TextStyle(color: textTertiary),
      ),
    );
  }

  // ============== DARK THEME ==============

  // Dark theme surface colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkDivider = Color(0xFF3A3A3A);
  static const Color darkInputFill = Color(0xFF2C2C2C);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: darkDivider,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFAAAAAA)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFAAAAAA)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusInput),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing12,
          vertical: spacing12,
        ),
        hintStyle: const TextStyle(color: Color(0xFF666666)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primary,  // green in dark mode too
        unselectedItemColor: Color(0xFF666666),
      ),
    );
  }
}

// ============== TYPOGRAPHY UTILITIES ==============

/// AppTypography provides reusable text styles for consistent typography
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppTheme.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppTheme.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppTheme.textTertiary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppTheme.textSecondary,
  );
}

// ============== SPACING UTILITIES ==============

/// AppSpacing provides standardized spacing values for consistent layout
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Shortcuts for SizedBox
  static const xsBox = SizedBox(width: xs, height: xs);
  static const smBox = SizedBox(width: sm, height: sm);
  static const mdBox = SizedBox(width: md, height: md);
  static const lgBox = SizedBox(width: lg, height: lg);
  static const xlBox = SizedBox(width: xl, height: xl);
  static const xxlBox = SizedBox(width: xxl, height: xxl);

  // Horizontal shortcuts
  static const xsHBox = SizedBox(width: xs);
  static const smHBox = SizedBox(width: sm);
  static const mdHBox = SizedBox(width: md);
  static const lgHBox = SizedBox(width: lg);
  static const xlHBox = SizedBox(width: xl);
  static const xxlHBox = SizedBox(width: xxl);

  // Vertical shortcuts
  static const xsVBox = SizedBox(height: xs);
  static const smVBox = SizedBox(height: sm);
  static const mdVBox = SizedBox(height: md);
  static const lgVBox = SizedBox(height: lg);
  static const xlVBox = SizedBox(height: xl);
  static const xxlVBox = SizedBox(height: xxl);
}

// ============== BORDER RADIUS UTILITIES ==============

/// AppRadius provides standardized border radius values for consistent shapes
class AppRadius {
  // Private constructor to prevent instantiation
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0;

  // BorderRadius shortcuts
  static final xsRadius = BorderRadius.circular(xs);
  static final smRadius = BorderRadius.circular(sm);
  static final mdRadius = BorderRadius.circular(md);
  static final lgRadius = BorderRadius.circular(lg);
  static final xlRadius = BorderRadius.circular(xl);
  static final fullRadius = BorderRadius.circular(full);

  // Circular shortcuts
  static const xsCircle = BorderRadius.all(Radius.circular(xs));
  static const smCircle = BorderRadius.all(Radius.circular(sm));
  static const mdCircle = BorderRadius.all(Radius.circular(md));
  static const lgCircle = BorderRadius.all(Radius.circular(lg));
  static const xlCircle = BorderRadius.all(Radius.circular(xl));
  static const fullCircle = BorderRadius.all(Radius.circular(full));
}
