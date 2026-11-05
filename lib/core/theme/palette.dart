import 'package:flutter/material.dart';

/// Central neon palette used by both the Flutter UI and the Flame canvas.
class Palette {
  const Palette._();

  // Backgrounds
  static const Color voidBlack = Color(0xFF04050E);
  static const Color deepSpace = Color(0xFF080B1A);
  static const Color surface = Color(0xFF0E1430);
  static const Color surfaceAlt = Color(0xFF141B3C);
  static const Color stroke = Color(0xFF26305C);

  // Neon accents
  static const Color neonBlue = Color(0xFF35E1FF);
  static const Color neonCyan = Color(0xFF6BF2FF);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonMagenta = Color(0xFFFF3CAC);
  static const Color neonGreen = Color(0xFF39FFB0);
  static const Color gold = Color(0xFFFFD166);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color orange = Color(0xFFFF8A3D);

  // Text
  static const Color textPrimary = Color(0xFFF2F6FF);
  static const Color textSecondary = Color(0xFFB7C2E8);
  static const Color textMuted = Color(0xFF7C88B8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonBlue, neonPurple],
  );

  static const LinearGradient magentaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonMagenta, neonPurple],
  );

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF101837), Color(0xFF0A0E22)],
  );

  static const LinearGradient backdropGradient = RadialGradient(
    center: Alignment(0, -0.35),
    radius: 1.35,
    colors: [Color(0xFF151E45), voidBlack],
  );

  /// Colour-blind friendly remap (deuteranopia-safe) for gameplay markers.
  static Color accessibility(Color source, bool colorBlindSafe) {
    if (!colorBlindSafe) return source;
    if (source == neonGreen || source == neonBlue) return const Color(0xFF4DA3FF);
    if (source == danger) return const Color(0xFFFF9E42);
    if (source == gold) return const Color(0xFFFFF08A);
    return source;
  }

  static List<Color> rarityColors = const [
    Color(0xFF9AA5C9), // common
    Color(0xFF35E1FF), // rare
    Color(0xFFA855F7), // epic
    Color(0xFFFFD166), // legendary
  ];
}
