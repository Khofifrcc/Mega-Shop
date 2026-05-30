import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// The single ThemeData object for MegaShop.
/// Passed to MaterialApp.theme — never build ThemeData inline.
abstract class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          primaryContainer: AppColors.primarySurface,
          onPrimaryContainer: AppColors.primary,
          secondary: AppColors.accent,
          onSecondary: AppColors.textOnPrimary,
          secondaryContainer: Color(0xFFFEF3C7),
          onSecondaryContainer: AppColors.accentDark,
          tertiary: AppColors.primaryLight,
          onTertiary: AppColors.textOnPrimary,
          error: AppColors.badgeSale,
          onError: AppColors.textOnPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          outline: AppColors.divider,
          surfaceContainerHighest: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        // Text theme derived from Inter (iOS SF Pro equivalent)
        textTheme: GoogleFonts.interTextTheme().copyWith(
          bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.inter(color: AppColors.textPrimary),
          bodySmall: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.iconDefault),
        ),
        // Bottom navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.iconMuted,
          elevation: 0,
        ),
        // Card
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Elevated Button (Buy Now)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Outlined Button (Add to Cart)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        dividerColor: AppColors.divider,
        splashColor: AppColors.primarySurface,
        highlightColor: Colors.transparent,
      );
}
