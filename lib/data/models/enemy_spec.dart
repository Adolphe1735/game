import 'dart:ui' show Color;

import '../../core/theme/palette.dart';
import '../../core/utils/vec.dart';
import 'weapon.dart' show WeaponRarity;

enum EnemyClass { basic, fast, armored, flying, shooter, defender, elite, miniBoss, boss }

enum MovePattern { straight, sine, zigzag, dive, orbit, drift, strafe, formation }

/// Enemy archetype from the enemy database (features 51–56, 61, 75).
class EnemySpec {
  const EnemySpec({
    required this.id,
    required this.name,
    required this.klass,
    required this.hp,
    required this.speed,
    required this.radius,
    required this.score,
    required this.coins,
    required this.xp,
    required this.color,
    required this.move,
    required this.shape,
    required this.description,
    this.fireInterval = 0,
    this.bulletSpeed = 210,
    this.bulletDamage = 8,
    this.armor = 0,
    this.gemChance = 0,
    this.powerUpChance = 0.10,
  });

  final String id;
  final String name;
  final EnemyClass klass;
  final double hp;
  final double speed;
  final double radius;
  final int score;
  final int coins;
  final int xp;
  final Color color;
  final MovePattern move;

  /// Drawing variant index consumed by the renderer.
  final int shape;

  final String description;
  final double fireInterval;
  final double bulletSpeed;
  final double bulletDamage;

  /// 0..1 damage reduction.
  final double armor;

  final double gemChance;
  final double powerUpChance;

  bool get isBoss => klass == EnemyClass.boss;
  bool get isElite => klass == EnemyClass.elite || klass == EnemyClass.miniBoss;
}

/// A boss phase — each phase changes attack cadence and patterns (features 69–70).
class BossPhase {
  const BossPhase({
    required this.name,
    required this.hpFraction,
    required this.fireInterval,
    required this.bulletSpeed,
    required this.pattern,
    required this.addsCount,
  });

  final String name;

  /// Fraction of max HP at which this phase starts.
  final double hpFraction;
  final double fireInterval;
  final double bulletSpeed;
  final BossPattern pattern;
  final int addsCount;
}

enum BossPattern { radialBurst, aimedSalvo, spiral, sweepingLaser, swarmRecall }

class BossSpec {
  const BossSpec({
    required this.id,
    required this.name,
    required this.hp,
    required this.radius,
    required this.score,
    required this.coins,
    required this.gems,
    required this.color,
    required this.phases,
    required this.description,
  });

  final String id;
  final String name;
  final double hp;
  final double radius;
  final int score;
  final int coins;
  final int gems;
  final Color color;
  final List<BossPhase> phases;
  final String description;
}

/// Enemy database (feature 75).
class EnemyCatalog {
  const EnemyCatalog._();

  static const List<EnemySpec> all = [
    EnemySpec(
      id: 'drone',
      name: 'Void Drone',
      klass: EnemyClass.basic,
      hp: 24,
      speed: 78,
      radius: 15,
      score: 100,
      coins: 4,
      xp: 6,
      color: Palette.neonBlue,
      move: MovePattern.straight,
      shape: 0,
      description: 'Standard front-line attacker. Fragile but relentless.',
    ),
    EnemySpec(
      id: 'swift',
      name: 'Swift Wraith',
      klass: EnemyClass.fast,
      hp: 16,
      speed: 168,
      radius: 12,
      score: 140,
      coins: 5,
      xp: 8,
      color: Palette.neonGreen,
      move: MovePattern.zigzag,
      shape: 1,
      description: 'Sprints down the lane weaving side to side.',
    ),
    EnemySpec(
      id: 'bulwark',
      name: 'Bulwark',
      klass: EnemyClass.armored,
      hp: 78,
      speed: 46,
      radius: 21,
      score: 260,
      coins: 12,
      xp: 15,
      color: Palette.orange,
      move: MovePattern.straight,
      shape: 2,
      armor: 0.35,
      description: 'Heavy plating absorbs 35% of incoming damage.',
    ),
    EnemySpec(
      id: 'skimmer',
      name: 'Skimmer',
      klass: EnemyClass.flying,
      hp: 30,
      speed: 96,
      radius: 14,
      score: 180,
      coins: 7,
      xp: 10,
      color: Palette.neonCyan,
      move: MovePattern.sine,
      shape: 3,
      description: 'Glides in smooth sine waves, hard to lead.',
    ),
    EnemySpec(
      id: 'lancer',
      name: 'Lancer',
      klass: EnemyClass.shooter,
      hp: 42,
      speed: 54,
      radius: 16,
      score: 220,
      coins: 9,
      xp: 12,
      color: Palette.neonMagenta,
      move: MovePattern.strafe,
      shape: 4,
      fireInterval: 1.9,
      bulletSpeed: 230,
      bulletDamage: 9,
      description: 'Keeps distance and fires aimed plasma bolts.',
    ),
    EnemySpec(
      id: 'sentinel',
      name: 'Sentinel',
      klass: EnemyClass.defender,
      hp: 66,
      speed: 34,
      radius: 19,
      score: 300,
      coins: 14,
      xp: 18,
      color: Palette.neonPurple,
      move: MovePattern.orbit,
      shape: 5,
      fireInterval: 2.6,
      bulletSpeed: 190,
      bulletDamage: 11,
      armor: 0.15,
      description: 'Orbits the player and shields nearby drones.',
    ),
    EnemySpec(
      id: 'kamikaze',
      name: 'Ravager',
      klass: EnemyClass.fast,
      hp: 26,
      speed: 72,
      radius: 15,
      score: 200,
      coins: 8,
      xp: 11,
      color: Palette.danger,
      move: MovePattern.dive,
      shape: 6,
      description: 'Locks on and accelerates straight at your ship.',
    ),
    EnemySpec(
      id: 'elite_reaver',
      name: 'Elite Reaver',
      klass: EnemyClass.elite,
      hp: 150,
      speed: 62,
      radius: 24,
      score: 620,
      coins: 30,
      xp: 45,
      color: Palette.gold,
      move: MovePattern.sine,
      shape: 7,
      fireInterval: 1.5,
      bulletSpeed: 250,
      bulletDamage: 12,
      armor: 0.2,
      gemChance: 0.35,
      powerUpChance: 0.4,
      description: 'Veteran hunter. Drops gems and power cores.',
    ),
    EnemySpec(
      id: 'mini_boss_titan',
      name: 'Titan Core',
      klass: EnemyClass.miniBoss,
      hp: 520,
      speed: 40,
      radius: 34,
      score: 1800,
      coins: 80,
      xp: 120,
      color: Palette.orange,
      move: MovePattern.strafe,
      shape: 8,
      fireInterval: 1.15,
      bulletSpeed: 245,
      bulletDamage: 14,
      armor: 0.25,
      gemChance: 1,
      powerUpChance: 1,
      description: 'Mini-boss. Rotating cannons and heavy armour.',
    ),
  ];

  static EnemySpec byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => all.first);

  /// Enemy pool available at a given player level / wave, sorted by difficulty.
  static List<EnemySpec> poolForLevel(int level) {
    final pool = <EnemySpec>[byId('drone')];
    if (level >= 2) pool.add(byId('swift'));
    if (level >= 3) pool.add(byId('skimmer'));
    if (level >= 4) pool.add(byId('bulwark'));
    if (level >= 5) pool.add(byId('lancer'));
    if (level >= 6) pool.add(byId('kamikaze'));
    if (level >= 7) pool.add(byId('sentinel'));
    if (level >= 8) pool.add(byId('elite_reaver'));
    return pool;
  }

  static const List<BossSpec> bosses = [
    BossSpec(
      id: 'boss_overseer',
      name: 'The Overseer',
      hp: 1400,
      radius: 52,
      score: 4200,
      coins: 220,
      gems: 6,
      color: Palette.neonMagenta,
      description: 'First void warden. Fires wide radial barrages.',
      phases: [
        BossPhase(
          name: 'CALIBRATION',
          hpFraction: 1.0,
          fireInterval: 2.0,
          bulletSpeed: 210,
          pattern: BossPattern.radialBurst,
          addsCount: 0,
        ),
        BossPhase(
          name: 'OVERCLOCK',
          hpFraction: 0.62,
          fireInterval: 1.35,
          bulletSpeed: 245,
          pattern: BossPattern.aimedSalvo,
          addsCount: 2,
        ),
        BossPhase(
          name: 'MELTDOWN',
          hpFraction: 0.3,
          fireInterval: 0.9,
          bulletSpeed: 275,
          pattern: BossPattern.spiral,
          addsCount: 3,
        ),
      ],
    ),
    BossSpec(
      id: 'boss_nexus',
      name: 'Nexus Prime',
      hp: 2600,
      radius: 58,
      score: 8200,
      coins: 420,
      gems: 12,
      color: Palette.neonPurple,
      description: 'Core intelligence. Sweeping lasers and endless swarms.',
      phases: [
        BossPhase(
          name: 'SCAN',
          hpFraction: 1.0,
          fireInterval: 1.8,
          bulletSpeed: 235,
          pattern: BossPattern.aimedSalvo,
          addsCount: 1,
        ),
        BossPhase(
          name: 'PRISM SWEEP',
          hpFraction: 0.66,
          fireInterval: 1.2,
          bulletSpeed: 265,
          pattern: BossPattern.sweepingLaser,
          addsCount: 2,
        ),
        BossPhase(
          name: 'SWARM RECALL',
          hpFraction: 0.33,
          fireInterval: 0.8,
          bulletSpeed: 290,
          pattern: BossPattern.swarmRecall,
          addsCount: 4,
        ),
      ],
    ),
    BossSpec(
      id: 'boss_voidking',
      name: 'Void Sovereign',
      hp: 4200,
      radius: 64,
      score: 16000,
      coins: 800,
      gems: 25,
      color: Palette.danger,
      description: 'Final sovereign of the void. Every pattern at once.',
      phases: [
        BossPhase(
          name: 'ASCENT',
          hpFraction: 1.0,
          fireInterval: 1.6,
          bulletSpeed: 250,
          pattern: BossPattern.spiral,
          addsCount: 2,
        ),
        BossPhase(
          name: 'DOMINION',
          hpFraction: 0.72,
          fireInterval: 1.1,
          bulletSpeed: 280,
          pattern: BossPattern.radialBurst,
          addsCount: 3,
        ),
        BossPhase(
          name: 'EXTINCTION',
          hpFraction: 0.45,
          fireInterval: 0.75,
          bulletSpeed: 300,
          pattern: BossPattern.sweepingLaser,
          addsCount: 3,
        ),
        BossPhase(
          name: 'SINGULARITY',
          hpFraction: 0.2,
          fireInterval: 0.55,
          bulletSpeed: 330,
          pattern: BossPattern.aimedSalvo,
          addsCount: 4,
        ),
      ],
    ),
  ];

  static BossSpec bossForLevel(int level) {
    if (level >= 10) return bosses[2];
    if (level >= 6) return bosses[1];
    return bosses[0];
  }
}

/// Power-up kinds (features 13–16, 137–138).
enum PowerUpKind { shield, heal, speed, damageBoost, ammo, bomb, coinMagnet, extraLife, rapidBoost }

extension PowerUpKindX on PowerUpKind {
  String get label => switch (this) {
        PowerUpKind.shield => 'SHIELD',
        PowerUpKind.heal => 'REPAIR',
        PowerUpKind.speed => 'OVERDRIVE',
        PowerUpKind.damageBoost => 'DAMAGE +',
        PowerUpKind.ammo => 'AMMO',
        PowerUpKind.bomb => 'BOMB',
        PowerUpKind.coinMagnet => 'MAGNET',
        PowerUpKind.extraLife => '1UP',
        PowerUpKind.rapidBoost => 'RAPID',
      };

  Color get color => switch (this) {
        PowerUpKind.shield => Palette.neonCyan,
        PowerUpKind.heal => Palette.neonGreen,
        PowerUpKind.speed => Palette.gold,
        PowerUpKind.damageBoost => Palette.danger,
        PowerUpKind.ammo => Palette.neonBlue,
        PowerUpKind.bomb => Palette.orange,
        PowerUpKind.coinMagnet => Palette.neonMagenta,
        PowerUpKind.extraLife => Palette.gold,
        PowerUpKind.rapidBoost => Palette.neonPurple,
      };

  Duration get duration => switch (this) {
        PowerUpKind.speed => const Duration(seconds: 7),
        PowerUpKind.damageBoost => const Duration(seconds: 9),
        PowerUpKind.rapidBoost => const Duration(seconds: 7),
        PowerUpKind.coinMagnet => const Duration(seconds: 10),
        PowerUpKind.shield => const Duration(seconds: 12),
        _ => Duration.zero,
      };
}

/// Score multipliers per game mode difficulty knob.
class Difficulty {
  const Difficulty({
    required this.id,
    required this.label,
    required this.enemyHealth,
    required this.enemyDamage,
    required this.spawnRate,
    required this.scoreMultiplier,
    required this.startingLives,
  });

  final String id;
  final String label;
  final double enemyHealth;
  final double enemyDamage;
  final double spawnRate;
  final double scoreMultiplier;
  final int startingLives;

  static const List<Difficulty> all = [
    Difficulty(
      id: 'cadet',
      label: 'CADET',
      enemyHealth: 0.8,
      enemyDamage: 0.7,
      spawnRate: 0.85,
      scoreMultiplier: 0.9,
      startingLives: 5,
    ),
    Difficulty(
      id: 'pilot',
      label: 'PILOT',
      enemyHealth: 1.0,
      enemyDamage: 1.0,
      spawnRate: 1.0,
      scoreMultiplier: 1.0,
      startingLives: 3,
    ),
    Difficulty(
      id: 'ace',
      label: 'ACE',
      enemyHealth: 1.35,
      enemyDamage: 1.25,
      spawnRate: 1.2,
      scoreMultiplier: 1.35,
      startingLives: 2,
    ),
    Difficulty(
      id: 'legend',
      label: 'LEGEND',
      enemyHealth: 1.8,
      enemyDamage: 1.5,
      spawnRate: 1.4,
      scoreMultiplier: 1.8,
      startingLives: 1,
    ),
  ];

  static Difficulty byId(String id) =>
      all.firstWhere((d) => d.id == id, orElse: () => all[1]);
}

/// Weapon rarity of the reward crate drawn after a run.
class RewardCrate {
  const RewardCrate({required this.coins, required this.gems, required this.xp, required this.rarity});

  final int coins;
  final int gems;
  final int xp;
  final WeaponRarity rarity;
}
