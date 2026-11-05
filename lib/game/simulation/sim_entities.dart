import 'dart:math' as math;
import 'dart:ui' show Color;

import '../../core/utils/vec.dart';
import '../../data/models/enemy_spec.dart';
import '../../data/models/game_mode.dart';
import '../../data/models/weapon.dart';

/// Mutable ship state used by [ArenaSimulation].
class PlayerState {
  PlayerState({
    required this.pos,
    required this.health,
    required this.lives,
    required this.ammoCapacity,
  })  : maxHealth = health,
        ammo = ammoCapacity;

  V2 pos;
  final double maxHealth;
  double health;
  int lives;

  /// Movement velocity actually applied last frame (used for banking visuals).
  V2 vel = V2.zero;

  double radius = 15;

  /// Radial shield bubble timer (feature 14).
  double shieldTime = 0;

  /// Temporary buffs.
  double speedBoost = 0;
  double damageBoost = 0;
  double rapidBoost = 0;
  double magnetTime = 0;

  /// Invulnerability window after taking a hit or respawning.
  double invuln = 0;

  double fireCooldown = 0;
  double reloadTimer = 0;
  double reloadDuration = 1.35;

  int ammo;
  final int ammoCapacity;

  /// Combo tracking (feature 19).
  int combo = 0;
  double comboTimer = 0;

  /// Screen-clearing special attack meter (feature 16).
  double specialCharge = 0;

  /// Visual recoil / banking inputs.
  double recoil = 0;
  double bank = 0;
  double thruster = 0;

  bool get isAlive => health > 0;
  bool get isReloading => reloadTimer > 0;
  bool get hasShield => shieldTime > 0;
  double get healthFraction => (health / maxHealth).clamp(0.0, 1.0);
  double get specialFraction => (specialCharge / 100).clamp(0.0, 1.0);
  bool get specialReady => specialCharge >= 100;
}

/// Projectile (player or hostile).
class Bullet {
  Bullet({
    required this.pos,
    required this.vel,
    required this.damage,
    required this.radius,
    required this.color,
    required this.life,
    this.hostile = false,
    this.pierce = 0,
    this.explosionRadius = 0,
    this.glow = 1,
  }) : start = pos;

  V2 pos;
  final V2 start;
  V2 vel;
  final double damage;
  final double radius;
  final Color color;

  /// Remaining lifetime in seconds.
  double life;
  final bool hostile;
  final int pierce;
  final double explosionRadius;
  final double glow;

  double age = 0;
  int hits = 0;
  bool dead = false;

  double get travelled => (pos - start).length;
}

/// A live enemy instance.
class EnemyUnit {
  EnemyUnit({
    required this.id,
    required this.spec,
    required this.pos,
    required this.hp,
    required this.maxHp,
    required this.laneX,
    required this.phaseOffset,
    this.amp = 40,
    this.targetY = 160,
  });

  final int id;
  final EnemySpec spec;
  V2 pos;
  double hp;
  final double maxHp;

  /// Horizontal home position for weave patterns.
  final double laneX;
  final double phaseOffset;
  final double amp;

  /// Depth where strafe/orbit enemies settle.
  final double targetY;

  V2 vel = V2.zero;
  double age = 0;
  double fireTimer = 0;
  double hitFlash = 0;
  double spawnT = 0;

  /// Formation index used by the renderer for offset rings.
  int slot = 0;

  bool dead = false;

  double get hpFraction => (hp / maxHp).clamp(0.0, 1.0);
  bool get isBoss => spec.isBoss;
}

/// Boss instance with scripted phases (features 5, 69–70).
class BossUnit {
  BossUnit({required this.spec, required this.pos, required this.hp});

  final BossSpec spec;
  V2 pos;
  double hp;
  double maxHp = 0;
  double age = 0;
  double fireTimer = 1.2;
  double hitFlash = 0;
  double entry = 1.4;
  double sweepAngle = 0;
  double spiralAngle = 0;
  int phaseIndex = 0;
  int addsTimer = 0;
  bool dead = false;

  double get hpFraction => (hp / maxHp).clamp(0.0, 1.0);
  BossPhase get phase => spec.phases[phaseIndex.clamp(0, spec.phases.length - 1)];
}

enum PickupKind { coin, gem, powerUp }

/// Collectible dropped by destroyed enemies (features 13–15, 137–138).
class Pickup {
  Pickup({
    required this.kind,
    required this.pos,
    required this.value,
    this.powerUp,
    this.color,
  });

  final PickupKind kind;
  final int value;
  final PowerUpKind? powerUp;
  final Color? color;
  V2 pos;
  V2 vel = const V2(0, 40);
  double age = 0;
  double life = 11;
  bool dead = false;
}

enum SimEventType {
  shotFired,
  reloadStarted,
  reloadFinished,
  enemyHit,
  enemyKilled,
  eliteKilled,
  bossSpawned,
  bossHit,
  bossPhase,
  bossDefeated,
  playerHit,
  shieldAbsorb,
  playerDied,
  lifeLost,
  respawn,
  coinCollected,
  gemCollected,
  powerUpCollected,
  specialUsed,
  explosion,
  waveCleared,
  levelCleared,
  runFailed,
  timeUp,
  comboMilestone,
}

/// One-shot gameplay signal consumed by audio/particles/UI.
class SimEvent {
  const SimEvent(this.type, {this.pos = V2.zero, this.color, this.value = 0, this.label});

  final SimEventType type;
  final V2 pos;
  final Color? color;
  final int value;
  final String? label;
}

enum RunPhase { running, levelCleared, failed, timeUp }

/// Snapshot of a finished run handed to the progression layer.
class RunResult {
  const RunResult({
    required this.mode,
    required this.level,
    required this.score,
    required this.coins,
    required this.gems,
    required this.xp,
    required this.kills,
    required this.bossKills,
    required this.wavesCleared,
    required this.powerUps,
    required this.maxCombo,
    required this.accuracy,
    required this.durationSeconds,
    required this.levelCleared,
    required this.defeated,
    required this.timeUp,
  });

  final GameMode mode;
  final int level;
  final int score;
  final int coins;
  final int gems;
  final int xp;
  final int kills;
  final int bossKills;
  final int wavesCleared;
  final int powerUps;
  final int maxCombo;

  /// Percentage 0–100.
  final double accuracy;

  final double durationSeconds;
  final bool levelCleared;
  final bool defeated;
  final bool timeUp;

  bool get isVictory => levelCleared && !defeated;
}

/// Frame input produced by touch, mouse or keyboard.
class SimInput {
  const SimInput({
    this.move = V2.zero,
    this.aim = const V2(0, -1),
    this.firing = false,
    this.useSpecial = false,
  });

  /// Normalised movement direction.
  final V2 move;

  /// Normalised firing direction.
  final V2 aim;

  final bool firing;
  final bool useSpecial;
}

/// Everything the simulation needs to build one run.
class RunConfig {
  const RunConfig({
    required this.mode,
    required this.difficulty,
    required this.seed,
    required this.level,
    required this.weaponId,
    required this.weaponStats,
    required this.ability,
    this.weaponSkin = 'Standard',
  });

  final GameMode mode;
  final Difficulty difficulty;
  final int seed;
  final int level;
  final String weaponId;
  final WeaponStats weaponStats;
  final WeaponAbility ability;
  final String weaponSkin;

  GameModeSpec get modeSpec => GameModeCatalog.of(mode);

  bool get isBossRush => mode == GameMode.bossRush;

  /// Level scaling factor for enemy stats.
  double get levelScale => 1 + (level - 1) * 0.16;

  int get startingLives => difficulty.startingLives;

  int get totalWaves {
    switch (mode) {
      case GameMode.bossRush:
        return 3;
      case GameMode.endless:
        return 1 << 30;
      case GameMode.timeAttack:
        return 1 << 30;
      default:
        return 3 + (level % 3); // 4, 5 or 6 waves per sector
    }
  }

  bool waveHasBoss(int waveIndex) {
    switch (mode) {
      case GameMode.bossRush:
        return true;
      case GameMode.campaign:
      case GameMode.daily:
        return level % 5 == 0 && waveIndex == totalWaves - 1;
      case GameMode.endless:
        return waveIndex > 0 && waveIndex % 5 == 4;
      case GameMode.timeAttack:
        return waveIndex > 0 && waveIndex % 4 == 3;
    }
  }
}

double angleTo(V2 from, V2 to) => math.atan2(to.y - from.y, to.x - from.x);
