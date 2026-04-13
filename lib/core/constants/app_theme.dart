import 'package:flutter/material.dart';

/// App-wide color palette
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF7C6FFF);
  static const primaryLight = Color(0xFF9D93FF);
  static const primaryDark = Color(0xFF5A4FCC);
  static const secondary = Color(0xFF5BF5C5);
  static const accent = Color(0xFFFF6B9D);

  // Semantic
  static const success = Color(0xFF52FF8E);
  static const successDark = Color(0xFF2ECC71);
  static const warning = Color(0xFFFFB547);
  static const error = Color(0xFFFF5252);
  static const info = Color(0xFF5BF5C5);

  // Dark backgrounds
  static const bgDark = Color(0xFF0B0C16);
  static const bgDark2 = Color(0xFF12132A);
  static const bgDark3 = Color(0xFF1A1B35);
  static const bgDark4 = Color(0xFF252540);

  // Light backgrounds
  static const bgLight = Color(0xFFF5F5FF);
  static const bgLight2 = Color(0xFFFFFFFF);
  static const bgLight3 = Color(0xFFEEEEFF);

  // Text - Dark theme
  static const textPrimaryDark = Color(0xFFE8E8F4);
  static const textSecondaryDark = Color(0xFF888899);
  static const textTertiaryDark = Color(0xFF555566);

  // Text - Light theme
  static const textPrimaryLight = Color(0xFF0B0C16);
  static const textSecondaryLight = Color(0xFF444455);
  static const textTertiaryLight = Color(0xFF888899);

  // Chart colors
  static const chartPurple = Color(0xFF7C6FFF);
  static const chartCyan = Color(0xFF5BF5C5);
  static const chartPink = Color(0xFFFF6B9D);
  static const chartGold = Color(0xFFFFB547);
  static const chartGreen = Color(0xFF52FF8E);
  static const chartRed = Color(0xFFFF5252);
  static const chartBlue = Color(0xFF4FC3F7);

  // Category colors
  static const catBanking = Color(0xFF4FC3F7);
  static const catFood = Color(0xFFFF6B9D);
  static const catShopping = Color(0xFFFFB547);
  static const catTransport = Color(0xFF5BF5C5);
  static const catWork = Color(0xFF7C6FFF);
  static const catOtp = Color(0xFFFF9800);
  static const catPromo = Color(0xFF9C27B0);
  static const catSystem = Color(0xFF607D8B);
  static const catUnknown = Color(0xFF888899);
}

/// Typography styles
class AppTypography {
  AppTypography._();

  static const fontFamily = 'Sora';
  static const monoFamily = 'DMmono';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static const h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static const h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.2,
  );

  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const monoBold = TextStyle(
    fontFamily: monoFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}

/// Complete theme definitions
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.bgDark2,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: AppColors.bgDark,
          onSurface: AppColors.textPrimaryDark,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,
        fontFamily: AppTypography.fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        ),
        cardTheme: CardThemeData(
          color: AppColors.bgDark2,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.bgDark4, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTypography.h4,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.body2.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.bgDark4,
          thickness: 1,
          space: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgDark2,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiaryDark,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.bgDark3,
          contentTextStyle: AppTypography.body2.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgDark3,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.bgDark4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.bgDark4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          labelStyle: AppTypography.body2.copyWith(
            color: AppColors.textSecondaryDark,
          ),
          hintStyle: AppTypography.body2.copyWith(
            color: AppColors.textTertiaryDark,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.display.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          headlineLarge: AppTypography.h1.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          headlineMedium: AppTypography.h2.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          headlineSmall: AppTypography.h3.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          titleLarge: AppTypography.h4.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          bodyLarge: AppTypography.body1.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          bodyMedium: AppTypography.body2.copyWith(
            color: AppColors.textPrimaryDark,
          ),
          bodySmall: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryDark,
          ),
          labelSmall: AppTypography.label.copyWith(
            color: AppColors.textTertiaryDark,
          ),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.bgLight2,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: AppColors.bgDark,
          onSurface: AppColors.textPrimaryLight,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
        fontFamily: AppTypography.fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        ),
        cardTheme: CardThemeData(
          color: AppColors.bgLight2,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE0E0F0), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTypography.h4,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.display.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          headlineLarge: AppTypography.h1.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          headlineMedium: AppTypography.h2.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          headlineSmall: AppTypography.h3.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          titleLarge: AppTypography.h4.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          bodyLarge: AppTypography.body1.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          bodyMedium: AppTypography.body2.copyWith(
            color: AppColors.textPrimaryLight,
          ),
          bodySmall: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryLight,
          ),
          labelSmall: AppTypography.label.copyWith(
            color: AppColors.textTertiaryLight,
          ),
        ),
      );
}
