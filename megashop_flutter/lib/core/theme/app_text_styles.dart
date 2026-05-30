import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized TextStyle definitions using Inter from Google Fonts (SF Pro equivalent).
/// All widgets should reference these instead of defining inline styles.
abstract class AppTextStyles {
  // ── App Name / Logo ────────────────────────────────────────────────────────
  static TextStyle get appLogo => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: -0.5,
      );

  // ── Section Heading ────────────────────────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  // ── Product Name ───────────────────────────────────────────────────────────
  static TextStyle get productName => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ── Brand Name ─────────────────────────────────────────────────────────────
  static TextStyle get brandName => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Price ──────────────────────────────────────────────────────────────────
  static TextStyle get price => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrice,
      );

  static TextStyle get originalPrice => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        decoration: TextDecoration.lineThrough,
      );

  // ── Buttons ────────────────────────────────────────────────────────────────
  static TextStyle get buttonOutlined => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  static TextStyle get buttonFilled => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  // ── Category Pills ─────────────────────────────────────────────────────────
  static TextStyle get categoryActive => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get categoryInactive => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Story Username ─────────────────────────────────────────────────────────
  static TextStyle get storyUsername => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── Bottom Nav Label ───────────────────────────────────────────────────────
  static TextStyle get navLabel => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );

  // ── Badge ──────────────────────────────────────────────────────────────────
  static TextStyle get badge => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.badgeText,
        letterSpacing: 0.5,
      );
}
