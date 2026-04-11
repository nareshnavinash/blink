import 'dart:ui';

/// Semantic color palette for Chirp.
/// Organized by role, not hue — use these instead of hardcoded Colors.*.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────
  static const brand = Color(0xFF9B7EC8); // soft lavender
  static const brandLight = Color(0xFFC4ACE0); // light lavender
  static const brandSubtle = Color(0xFFFAF7F5); // warm cream

  // ── Rose accent ────────────────────────────────────────────────
  static const rose = Color(0xFFE8839F); // rose-400
  static const roseLight = Color(0xFFFDDDE6); // rose-100
  static const roseSubtle = Color(0xFFFFF0F3); // rose-50

  // ── Semantic states ────────────────────────────────────────────
  static const success = Color(0xFF16A34A); // green-600
  static const successLight = Color(0xFFE8F5EC); // warm green-100
  static const successMedium = Color(0xFF15803D); // green-700

  static const warning = Color(0xFFE07A3C); // warm orange
  static const warningLight = Color(0xFFFFF5EB); // warm orange-50
  static const warningMedium = Color(0xFFFDBA74); // orange-300
  static const warningDark = Color(0xFFC2410C); // orange-700

  static const error = Color(0xFFDC2626); // red-600
  static const errorLight = Color(0xFFFDE8E8); // warm red-100
  static const errorDark = Color(0xFFB91C1C); // red-700

  // ── Neutral / text (warm stone family) ─────────────────────────
  static const textSecondary = Color(0xFF78716C); // stone-500
  static const textTertiary = Color(0xFFA8A29E); // stone-400
  static const surfaceSubtle = Color(0xFFF5F3F0); // warm-100
  static const border = Color(0xFFE7E5E0); // stone-200
  static const borderLight = Color(0xFFF5F3F0); // warm-100

  // ── Stats-specific accent colors ───────────────────────────────
  static const statsPurple = Color(0xFF9B7EC8); // soft lavender
  static const statsTeal = Color(0xFF5BA8A0); // soft teal
  static const statsAmber = Color(0xFFD4943C); // warm amber

  // ── Break screen ───────────────────────────────────────────────
  static const breakGradientStart = Color(0xFF2A1F3D); // warm twilight
  static const breakGradientEnd = Color(0xFF3D2E52); // warm plum

  // ── Dark mode overrides ────────────────────────────────────────
  static const darkBrand = Color(0xFFC4ACE0); // light lavender
  static const darkBrandSubtle = Color(0xFF2A1F3D); // warm twilight

  static const darkRose = Color(0xFFF9A8D4); // rose-300
  static const darkRoseLight = Color(0xFF4A1D30); // deep rose bg
  static const darkRoseSubtle = Color(0xFF3D1526); // deep rose subtle

  static const darkSuccess = Color(0xFF4ADE80); // green-400
  static const darkSuccessLight = Color(0xFF14532D); // green-900
  static const darkSuccessMedium = Color(0xFF22C55E); // green-500

  static const darkWarning = Color(0xFFFB923C); // orange-400
  static const darkWarningLight = Color(0xFF431407); // orange-950
  static const darkWarningMedium = Color(0xFFFDBA74); // orange-300
  static const darkWarningDark = Color(0xFFF97316); // orange-500

  static const darkError = Color(0xFFF87171); // red-400
  static const darkErrorLight = Color(0xFF450A0A); // red-950
  static const darkErrorDark = Color(0xFFEF4444); // red-500

  static const darkTextSecondary = Color(0xFFA8A29E); // stone-400
  static const darkTextTertiary = Color(0xFF78716C); // stone-500
  static const darkSurfaceSubtle = Color(0xFF292524); // stone-800
  static const darkBorder = Color(0xFF44403C); // stone-700
  static const darkBorderLight = Color(0xFF292524); // stone-800

  static const darkStatsPurple = Color(0xFFC4ACE0); // soft lavender
  static const darkStatsTeal = Color(0xFF6EC5BB); // soft teal
  static const darkStatsAmber = Color(0xFFF5C957); // soft amber
}
