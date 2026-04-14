import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFBF2E2); // Your cream background
  static const Color primaryText = Color(0xFF624232); // Your deep brown
  static const Color primaryGreen = Color(0xFF43A047);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color cardWhite = Colors.white;
  static const Color redLate = Color(0xFFEE5535);
  static const Color lightRed = Color(0xFFFFEBEE);
  static const Color greyText = Color(0xFF9E9E9E);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
    fontFamily: 'Serif', // Replace with your specific serif font if needed
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    fontFamily: 'Serif',
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.greyText,
  );
}

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryGreen,
  fontFamily: 'Inter', // Default sans-serif font
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.cardWhite,
    selectedItemColor: AppColors.primaryGreen,
    unselectedItemColor: AppColors.primaryText,
    showUnselectedLabels: true,
  ),
);
