import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Custom theme extension carrying Chirp's semantic colors.
/// Access via `ChirpColors.of(context)` in any widget.
class ChirpColors extends ThemeExtension<ChirpColors> {
  final Color brand;
  final Color brandLight;
  final Color brandSubtle;

  final Color rose;
  final Color roseLight;
  final Color roseSubtle;

  final Color success;
  final Color successLight;
  final Color successMedium;

  final Color warning;
  final Color warningLight;
  final Color warningMedium;
  final Color warningDark;

  final Color error;
  final Color errorLight;
  final Color errorDark;

  final Color textSecondary;
  final Color textTertiary;
  final Color surfaceSubtle;
  final Color border;
  final Color borderLight;

  final Color statsPurple;
  final Color statsTeal;
  final Color statsAmber;

  final Color breakGradientStart;
  final Color breakGradientEnd;

  const ChirpColors({
    required this.brand,
    required this.brandLight,
    required this.brandSubtle,
    required this.rose,
    required this.roseLight,
    required this.roseSubtle,
    required this.success,
    required this.successLight,
    required this.successMedium,
    required this.warning,
    required this.warningLight,
    required this.warningMedium,
    required this.warningDark,
    required this.error,
    required this.errorLight,
    required this.errorDark,
    required this.textSecondary,
    required this.textTertiary,
    required this.surfaceSubtle,
    required this.border,
    required this.borderLight,
    required this.statsPurple,
    required this.statsTeal,
    required this.statsAmber,
    required this.breakGradientStart,
    required this.breakGradientEnd,
  });

  /// Light theme colors.
  factory ChirpColors.light() => const ChirpColors(
        brand: AppColors.brand,
        brandLight: AppColors.brandLight,
        brandSubtle: AppColors.brandSubtle,
        rose: AppColors.rose,
        roseLight: AppColors.roseLight,
        roseSubtle: AppColors.roseSubtle,
        success: AppColors.success,
        successLight: AppColors.successLight,
        successMedium: AppColors.successMedium,
        warning: AppColors.warning,
        warningLight: AppColors.warningLight,
        warningMedium: AppColors.warningMedium,
        warningDark: AppColors.warningDark,
        error: AppColors.error,
        errorLight: AppColors.errorLight,
        errorDark: AppColors.errorDark,
        textSecondary: AppColors.textSecondary,
        textTertiary: AppColors.textTertiary,
        surfaceSubtle: AppColors.surfaceSubtle,
        border: AppColors.border,
        borderLight: AppColors.borderLight,
        statsPurple: AppColors.statsPurple,
        statsTeal: AppColors.statsTeal,
        statsAmber: AppColors.statsAmber,
        breakGradientStart: AppColors.breakGradientStart,
        breakGradientEnd: AppColors.breakGradientEnd,
      );

  /// Dark theme colors.
  factory ChirpColors.dark() => const ChirpColors(
        brand: AppColors.darkBrand,
        brandLight: AppColors.darkBrand,
        brandSubtle: AppColors.darkBrandSubtle,
        rose: AppColors.darkRose,
        roseLight: AppColors.darkRoseLight,
        roseSubtle: AppColors.darkRoseSubtle,
        success: AppColors.darkSuccess,
        successLight: AppColors.darkSuccessLight,
        successMedium: AppColors.darkSuccessMedium,
        warning: AppColors.darkWarning,
        warningLight: AppColors.darkWarningLight,
        warningMedium: AppColors.darkWarningMedium,
        warningDark: AppColors.darkWarningDark,
        error: AppColors.darkError,
        errorLight: AppColors.darkErrorLight,
        errorDark: AppColors.darkErrorDark,
        textSecondary: AppColors.darkTextSecondary,
        textTertiary: AppColors.darkTextTertiary,
        surfaceSubtle: AppColors.darkSurfaceSubtle,
        border: AppColors.darkBorder,
        borderLight: AppColors.darkBorderLight,
        statsPurple: AppColors.darkStatsPurple,
        statsTeal: AppColors.darkStatsTeal,
        statsAmber: AppColors.darkStatsAmber,
        breakGradientStart: AppColors.breakGradientStart,
        breakGradientEnd: AppColors.breakGradientEnd,
      );

  /// Ergonomic accessor: `ChirpColors.of(context).brand`
  static ChirpColors of(BuildContext context) {
    final ext = Theme.of(context).extension<ChirpColors>();
    assert(ext != null, 'ChirpColors not found in theme. Did you register it?');
    return ext!;
  }

  @override
  ChirpColors copyWith({
    Color? brand,
    Color? brandLight,
    Color? brandSubtle,
    Color? rose,
    Color? roseLight,
    Color? roseSubtle,
    Color? success,
    Color? successLight,
    Color? successMedium,
    Color? warning,
    Color? warningLight,
    Color? warningMedium,
    Color? warningDark,
    Color? error,
    Color? errorLight,
    Color? errorDark,
    Color? textSecondary,
    Color? textTertiary,
    Color? surfaceSubtle,
    Color? border,
    Color? borderLight,
    Color? statsPurple,
    Color? statsTeal,
    Color? statsAmber,
    Color? breakGradientStart,
    Color? breakGradientEnd,
  }) {
    return ChirpColors(
      brand: brand ?? this.brand,
      brandLight: brandLight ?? this.brandLight,
      brandSubtle: brandSubtle ?? this.brandSubtle,
      rose: rose ?? this.rose,
      roseLight: roseLight ?? this.roseLight,
      roseSubtle: roseSubtle ?? this.roseSubtle,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      successMedium: successMedium ?? this.successMedium,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      warningMedium: warningMedium ?? this.warningMedium,
      warningDark: warningDark ?? this.warningDark,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      errorDark: errorDark ?? this.errorDark,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      statsPurple: statsPurple ?? this.statsPurple,
      statsTeal: statsTeal ?? this.statsTeal,
      statsAmber: statsAmber ?? this.statsAmber,
      breakGradientStart: breakGradientStart ?? this.breakGradientStart,
      breakGradientEnd: breakGradientEnd ?? this.breakGradientEnd,
    );
  }

  @override
  ChirpColors lerp(ChirpColors? other, double t) {
    if (other == null) return this;
    return ChirpColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandLight: Color.lerp(brandLight, other.brandLight, t)!,
      brandSubtle: Color.lerp(brandSubtle, other.brandSubtle, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      roseLight: Color.lerp(roseLight, other.roseLight, t)!,
      roseSubtle: Color.lerp(roseSubtle, other.roseSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      successMedium: Color.lerp(successMedium, other.successMedium, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      warningMedium: Color.lerp(warningMedium, other.warningMedium, t)!,
      warningDark: Color.lerp(warningDark, other.warningDark, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      statsPurple: Color.lerp(statsPurple, other.statsPurple, t)!,
      statsTeal: Color.lerp(statsTeal, other.statsTeal, t)!,
      statsAmber: Color.lerp(statsAmber, other.statsAmber, t)!,
      breakGradientStart:
          Color.lerp(breakGradientStart, other.breakGradientStart, t)!,
      breakGradientEnd:
          Color.lerp(breakGradientEnd, other.breakGradientEnd, t)!,
    );
  }
}
