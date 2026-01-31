import 'package:flutter/material.dart';

class AppColors {
  // Primary backgrounds
  static const Color deepBlack = Color(0xFF0D0D0D);
  static const Color richBlack = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF2A2A2A);
  static const Color gunmetal = Color(0xFF3A3A3A);

  // Accent colors
  static const Color crimsonRed = Color(0xFFDC2626);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color amberGold = Color(0xFFF59E0B);

  // Text colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color mutedGrey = Color(0xFF6B7280);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [richBlack, deepBlack],
  );

  static const LinearGradient crimsonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), crimsonRed],
  );

  static const LinearGradient timerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [amberGold, crimsonRed],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepBlack,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.crimsonRed,
        secondary: AppColors.amberGold,
        tertiary: AppColors.emeraldGreen,
        surface: AppColors.richBlack,
        onSurface: AppColors.pureWhite,
        onPrimary: AppColors.pureWhite,
        onSecondary: AppColors.deepBlack,
        outline: AppColors.gunmetal,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.pureWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.pureWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.pureWhite,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.pureWhite,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
        ),
        iconTheme: IconThemeData(color: AppColors.pureWhite),
      ),
      cardTheme: CardThemeData(
        color: AppColors.richBlack,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gunmetal, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.charcoal,
          foregroundColor: AppColors.pureWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amberGold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoal,
        hintStyle: const TextStyle(color: AppColors.mutedGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gunmetal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gunmetal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amberGold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.charcoal,
        labelStyle: const TextStyle(color: AppColors.pureWhite),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.gunmetal),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.richBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.gunmetal),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.pureWhite,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.pureWhite,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.gunmetal,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.pureWhite,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amberGold,
        linearTrackColor: AppColors.charcoal,
      ),
    );
  }
}

class AppDecorations {
  static BoxDecoration get gradientBackground => const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      );

  static BoxDecoration get gradientBackgroundWithGlow => BoxDecoration(
        gradient: AppColors.backgroundGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.crimsonRed.withOpacity(0.1),
            blurRadius: 100,
            spreadRadius: 50,
            offset: const Offset(0, 200),
          ),
        ],
      );

  static BoxDecoration get glassCard => BoxDecoration(
        color: AppColors.richBlack.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.amberGold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.amberGold.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      );

  static BoxDecoration get keyboardContainer => const BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      );

  static BoxDecoration get scoreDisplay => BoxDecoration(
        color: AppColors.richBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amberGold.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.amberGold.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      );
}
