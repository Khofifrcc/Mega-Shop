import 'package:flutter/material.dart';

/// All application colors — single source of truth.
/// Never use hardcoded Color() values in widgets; always reference AppColors.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C2BD9);       // Deep purple
  static const Color primaryLight = Color(0xFF8B5CF6);  // Lighter purple
  static const Color primarySurface = Color(0xFFEDE9FE); // Very light purple

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFF5A623);        // Amber/Orange (Buy Now)
  static const Color accentDark = Color(0xFFD4891A);    // Pressed amber

  // ── Background ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF0EFFE);    // Lavender background
  static const Color surface = Color(0xFFFFFFFF);       // Card white
  static const Color surfaceDim = Color(0xFFF7F5FF);    // Slightly tinted white

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);   // Near-black
  static const Color textSecondary = Color(0xFF6B7280); // Muted grey
  static const Color textHint = Color(0xFF9CA3AF);      // Placeholder grey
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on purple
  static const Color textPrice = Color(0xFFF5A623);     // Amber for price

  // ── Badges ─────────────────────────────────────────────────────────────────
  static const Color badgeNew = Color(0xFF6C2BD9);      // Purple for NEW
  static const Color badgeSale = Color(0xFFDC2626);     // Red for SALE
  static const Color badgeText = Color(0xFFFFFFFF);     // White badge text

  // ── Story ring ─────────────────────────────────────────────────────────────
  static const Color storyRing = Color(0xFF6C2BD9);     // Purple border
  static const Color storyRingAdd = Color(0xFFEDE9FE);  // Light purple for add

  // ── Icons & Dividers ───────────────────────────────────────────────────────
  static const Color iconDefault = Color(0xFF374151);
  static const Color iconActive = Color(0xFF6C2BD9);
  static const Color iconMuted = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);

  // ── Notification badge ─────────────────────────────────────────────────────
  static const Color notifBadge = Color(0xFFF5A623);    // Amber dot on bell

  // ── Shadow ─────────────────────────────────────────────────────────────────
  static const Color shadow = Color(0x14000000);        // 8% black
  static const Color cardShadow = Color(0x1A6C2BD9);    // Purple-tinted shadow
}
