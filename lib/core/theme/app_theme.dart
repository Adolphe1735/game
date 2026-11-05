import 'package:flutter/material.dart';

import 'palette.dart';

/// Global dark gaming theme with neon accents.
class AppTheme {
  const AppTheme._();

  static const String displayFont = 'Orbitron';
  static const String bodyFont = 'Rajdhani';

  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: Palette.neonBlue,
      onPrimary: Palette.voidBlack,
      secondary: Palette.neonPurple,
      onSecondary: Palette.textPrimary,
      surface: Palette.surface,
      onSurface: Palette.textPrimary,
      error: Palette.danger,
      onError: Palette.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Palette.voidBlack,
      canvasColor: Palette.voidBlack,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: Palette.textPrimary,
            displayColor: Palette.textPrimary,
            fontFamily: bodyFont,
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: displayFont,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: Palette.textPrimary,
            ),
            headlineLarge: const TextStyle(
              fontFamily: displayFont,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            headlineMedium: const TextStyle(
              fontFamily: displayFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
            titleLarge: const TextStyle(
              fontFamily: displayFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            bodyMedium: const TextStyle(fontSize: 15, height: 1.35),
            labelLarge: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
      iconTheme: const IconThemeData(color: Palette.textSecondary),
      dividerColor: Palette.stroke,
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: Palette.neonBlue,
        inactiveTrackColor: Palette.surfaceAlt,
        thumbColor: Palette.neonCyan,
        overlayColor: Palette.neonBlue.withValues(alpha: 0.16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Palette.neonCyan : Palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Palette.neonPurple.withValues(alpha: 0.55)
              : Palette.surfaceAlt,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.surfaceAlt,
        contentTextStyle: TextStyle(color: Palette.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: Palette.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Palette.stroke),
        ),
        textStyle: const TextStyle(color: Palette.textPrimary, fontSize: 12),
      ),
    );
  }

  static BoxDecoration glowPanel({Color glow = Palette.neonBlue, double radius = 22}) {
    return BoxDecoration(
      gradient: Palette.panelGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glow.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(color: glow.withValues(alpha: 0.16), blurRadius: 26, spreadRadius: 1),
      ],
    );
  }
}
