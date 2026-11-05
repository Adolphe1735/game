import 'dart:ui' show Color;

import '../../core/theme/palette.dart';

/// Game modes (features 20–23, 180).
enum GameMode { campaign, endless, timeAttack, bossRush, daily }

class GameModeSpec {
  const GameModeSpec({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    this.levelCount = 0,
    this.durationSeconds = 0,
    this.hasBosses = true,
    this.endless = false,
  });

  final GameMode mode;
  final String title;
  final String subtitle;
  final Color accent;

  /// Number of authored levels; 0 means "not level based".
  final int levelCount;

  /// Run duration in seconds; 0 means unlimited.
  final int durationSeconds;

  final bool hasBosses;
  final bool endless;

  bool get isLevelBased => levelCount > 0;
}

class GameModeCatalog {
  const GameModeCatalog._();

  static const List<GameModeSpec> all = [
    GameModeSpec(
      mode: GameMode.campaign,
      title: 'CAMPAIGN',
      subtitle: '10 handcrafted sectors. Boss every 5th sector.',
      accent: Palette.neonBlue,
      icon: 0,
      levelCount: 10,
    ),
    GameModeSpec(
      mode: GameMode.endless,
      title: 'ENDLESS',
      subtitle: 'Procedural waves that never stop escalating.',
      accent: Palette.neonPurple,
      icon: 1,
      endless: true,
    ),
    GameModeSpec(
      mode: GameMode.timeAttack,
      title: 'TIME ATTACK',
      subtitle: '90 seconds. Maximum score. No mercy.',
      accent: Palette.gold,
      icon: 2,
      durationSeconds: 90,
      hasBosses: true,
    ),
    GameModeSpec(
      mode: GameMode.bossRush,
      title: 'BOSS RUSH',
      subtitle: 'Back-to-back bosses with power drops between.',
      accent: Palette.danger,
      icon: 3,
      levelCount: 3,
    ),
    GameModeSpec(
      mode: GameMode.daily,
      title: 'DAILY CHALLENGE',
      subtitle: 'One seeded run per day. Fair for everyone.',
      accent: Palette.neonGreen,
      icon: 4,
      levelCount: 5,
    ),
  ];

  static GameModeSpec of(GameMode mode) => all.firstWhere((m) => m.mode == mode);

  static String keyOf(GameMode mode) => mode.name;
}
