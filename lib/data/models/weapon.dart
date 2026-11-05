import 'dart:ui' show Color;

import '../../core/theme/palette.dart';

enum WeaponRarity { common, rare, epic, legendary }

extension WeaponRarityX on WeaponRarity {
  String get label => switch (this) {
        WeaponRarity.common => 'COMMON',
        WeaponRarity.rare => 'RARE',
        WeaponRarity.epic => 'EPIC',
        WeaponRarity.legendary => 'LEGENDARY',
      };

  Color get color => Palette.rarityColors[index];
}

/// Immutable description of a weapon archetype.
class WeaponSpec {
  const WeaponSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.damage,
    required this.fireRate,
    required this.range,
    required this.projectileSpeed,
    required this.pellets,
    required this.ammoPerShot,
    required this.color,
    required this.sfx,
    required this.unlockLevel,
    required this.coinCost,
    this.spreadDeg = 0,
    this.pierce = 0,
    this.explosionRadius = 0,
    this.skins = const ['Standard'],
    this.ability = WeaponAbility.none,
  });

  final String id;
  final String name;
  final String description;
  final WeaponRarity rarity;

  /// Base damage per projectile before upgrades.
  final double damage;

  /// Shots per second before upgrades.
  final double fireRate;

  /// Projectile lifetime in seconds before upgrades.
  final double range;

  final double projectileSpeed;
  final int pellets;
  final int ammoPerShot;

  /// Total angular spread in degrees.
  final double spreadDeg;

  final int pierce;
  final double explosionRadius;
  final Color color;
  final String sfx;
  final int unlockLevel;
  final int coinCost;
  final List<String> skins;
  final WeaponAbility ability;

  int get ammoCapacity => switch (id) {
        'pulse_rifle' => 0, // unlimited
        'rapid_fire' => 80,
        'spread_shot' => 40,
        'plasma_cannon' => 30,
        'laser_lance' => 60,
        'railgun' => 12,
        'twin_ripper' => 100,
        'nova_burst' => 24,
        _ => 50,
      };

  bool get usesAmmo => ammoCapacity > 0;
}

enum WeaponAbility { none, penetrate, explode, overload, heavyShot }

/// The player's purchased upgrade levels for one weapon (features 46–49).
class WeaponUpgrades {
  const WeaponUpgrades({
    this.damageLevel = 0,
    this.fireRateLevel = 0,
    this.rangeLevel = 0,
    this.accuracyLevel = 0,
  });

  final int damageLevel;
  final int fireRateLevel;
  final int rangeLevel;
  final int accuracyLevel;

  static const int maxLevel = 5;

  WeaponUpgrades copyWith({
    int? damageLevel,
    int? fireRateLevel,
    int? rangeLevel,
    int? accuracyLevel,
  }) {
    return WeaponUpgrades(
      damageLevel: damageLevel ?? this.damageLevel,
      fireRateLevel: fireRateLevel ?? this.fireRateLevel,
      rangeLevel: rangeLevel ?? this.rangeLevel,
      accuracyLevel: accuracyLevel ?? this.accuracyLevel,
    );
  }

  int levelOf(UpgradeKind kind) => switch (kind) {
        UpgradeKind.damage => damageLevel,
        UpgradeKind.fireRate => fireRateLevel,
        UpgradeKind.range => rangeLevel,
        UpgradeKind.accuracy => accuracyLevel,
      };

  WeaponUpgrades withLevel(UpgradeKind kind, int level) => switch (kind) {
        UpgradeKind.damage => copyWith(damageLevel: level),
        UpgradeKind.fireRate => copyWith(fireRateLevel: level),
        UpgradeKind.range => copyWith(rangeLevel: level),
        UpgradeKind.accuracy => copyWith(accuracyLevel: level),
      };

  int get totalLevels => damageLevel + fireRateLevel + rangeLevel + accuracyLevel;

  Map<String, dynamic> toJson() => {
        'dmg': damageLevel,
        'rate': fireRateLevel,
        'rng': rangeLevel,
        'acc': accuracyLevel,
      };

  factory WeaponUpgrades.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeaponUpgrades();
    int read(String key) {
      final raw = json[key];
      if (raw is int) return raw.clamp(0, maxLevel);
      if (raw is num) return raw.toInt().clamp(0, maxLevel);
      return 0;
    }

    return WeaponUpgrades(
      damageLevel: read('dmg'),
      fireRateLevel: read('rate'),
      rangeLevel: read('rng'),
      accuracyLevel: read('acc'),
    );
  }
}

enum UpgradeKind { damage, fireRate, range, accuracy }

extension UpgradeKindX on UpgradeKind {
  String get label => switch (this) {
        UpgradeKind.damage => 'DAMAGE',
        UpgradeKind.fireRate => 'FIRE RATE',
        UpgradeKind.range => 'RANGE',
        UpgradeKind.accuracy => 'ACCURACY',
      };

  String get effect => switch (this) {
        UpgradeKind.damage => '+15% damage / level',
        UpgradeKind.fireRate => '+10% fire rate / level',
        UpgradeKind.range => '+15% projectile range / level',
        UpgradeKind.accuracy => '-12% spread / level',
      };

  int costFor(int nextLevel) => 60 + nextLevel * 55;
}

/// Effective combat values after upgrades are applied.
class WeaponStats {
  const WeaponStats({
    required this.damage,
    required this.fireRate,
    required this.range,
    required this.spreadDeg,
    required this.projectileSpeed,
    required this.pellets,
    required this.pierce,
    required this.explosionRadius,
    required this.ammoCapacity,
    required this.ammoPerShot,
  });

  final double damage;
  final double fireRate;
  final double range;
  final double spreadDeg;
  final double projectileSpeed;
  final int pellets;
  final int pierce;
  final double explosionRadius;
  final int ammoCapacity;
  final int ammoPerShot;

  double get shotInterval => 1 / fireRate.clamp(0.5, 40);
}

/// Applies upgrade multipliers to a weapon spec (features 46–49).
WeaponStats resolveWeaponStats(WeaponSpec spec, WeaponUpgrades upgrades) {
  final dmg = spec.damage * (1 + 0.15 * upgrades.damageLevel);
  final rate = spec.fireRate * (1 + 0.10 * upgrades.fireRateLevel);
  final range = spec.range * (1 + 0.15 * upgrades.rangeLevel);
  final spread = spec.spreadDeg * (1 - 0.12 * upgrades.accuracyLevel);
  return WeaponStats(
    damage: dmg,
    fireRate: rate,
    range: range,
    spreadDeg: spread < 0 ? 0 : spread,
    projectileSpeed: spec.projectileSpeed,
    pellets: spec.pellets,
    pierce: spec.pierce,
    explosionRadius: spec.explosionRadius,
    ammoCapacity: spec.ammoCapacity,
    ammoPerShot: spec.ammoPerShot,
  );
}

/// The weapon database (features 26–45).
class WeaponCatalog {
  const WeaponCatalog._();

  static const List<WeaponSpec> all = [
    WeaponSpec(
      id: 'pulse_rifle',
      name: 'Pulse Rifle',
      description: 'Reliable infinite-ammo blaster. Balanced starter weapon.',
      rarity: WeaponRarity.common,
      damage: 10,
      fireRate: 5.2,
      range: 1.6,
      projectileSpeed: 620,
      pellets: 1,
      ammoPerShot: 0,
      color: Palette.neonBlue,
      sfx: 'shoot',
      unlockLevel: 1,
      coinCost: 0,
      skins: ['Standard', 'Ion Blue', 'Void Grey'],
    ),
    WeaponSpec(
      id: 'rapid_fire',
      name: 'Rapid Repeater',
      description: 'Extreme rate of fire. Burns through ammo fast.',
      rarity: WeaponRarity.common,
      damage: 5.5,
      fireRate: 11,
      range: 1.25,
      projectileSpeed: 720,
      pellets: 1,
      ammoPerShot: 1,
      spreadDeg: 7,
      color: Palette.neonGreen,
      sfx: 'rapid',
      unlockLevel: 2,
      coinCost: 250,
      skins: ['Standard', 'Toxic', 'Circuit'],
    ),
    WeaponSpec(
      id: 'spread_shot',
      name: 'Scatter Array',
      description: 'Five-pellet fan. Devastating at close range.',
      rarity: WeaponRarity.rare,
      damage: 7,
      fireRate: 2.6,
      range: 0.95,
      projectileSpeed: 540,
      pellets: 5,
      ammoPerShot: 1,
      spreadDeg: 42,
      color: Palette.gold,
      sfx: 'spread',
      unlockLevel: 4,
      coinCost: 600,
      skins: ['Standard', 'Solar Flare'],
    ),
    WeaponSpec(
      id: 'laser_lance',
      name: 'Laser Lance',
      description: 'Piercing beam bolts that punch through entire columns.',
      rarity: WeaponRarity.rare,
      damage: 14,
      fireRate: 3.4,
      range: 2.2,
      projectileSpeed: 900,
      pellets: 1,
      ammoPerShot: 1,
      pierce: 2,
      color: Palette.neonCyan,
      sfx: 'laser',
      unlockLevel: 6,
      coinCost: 900,
      ability: WeaponAbility.penetrate,
      skins: ['Standard', 'Prism', 'Azure'],
    ),
    WeaponSpec(
      id: 'plasma_cannon',
      name: 'Plasma Cannon',
      description: 'Slow orbs that detonate in a burning area burst.',
      rarity: WeaponRarity.epic,
      damage: 26,
      fireRate: 1.9,
      range: 1.8,
      projectileSpeed: 460,
      pellets: 1,
      ammoPerShot: 1,
      explosionRadius: 52,
      color: Palette.neonMagenta,
      sfx: 'plasma',
      unlockLevel: 9,
      coinCost: 1500,
      ability: WeaponAbility.explode,
      skins: ['Standard', 'Magma', 'Nebula'],
    ),
    WeaponSpec(
      id: 'twin_ripper',
      name: 'Twin Ripper',
      description: 'Twin-linked streams with slight convergence.',
      rarity: WeaponRarity.epic,
      damage: 9,
      fireRate: 6.5,
      range: 1.5,
      projectileSpeed: 700,
      pellets: 2,
      ammoPerShot: 1,
      spreadDeg: 6,
      color: Palette.neonPurple,
      sfx: 'shoot',
      unlockLevel: 12,
      coinCost: 2200,
      skins: ['Standard', 'Ultraviolet'],
    ),
    WeaponSpec(
      id: 'railgun',
      name: 'Void Railgun',
      description: 'Charged slug with huge damage and full penetration.',
      rarity: WeaponRarity.legendary,
      damage: 64,
      fireRate: 1.1,
      range: 2.6,
      projectileSpeed: 1400,
      pellets: 1,
      ammoPerShot: 2,
      pierce: 6,
      color: Palette.danger,
      sfx: 'railgun',
      unlockLevel: 16,
      coinCost: 3800,
      ability: WeaponAbility.heavyShot,
      skins: ['Standard', 'Crimson', 'Obsidian', 'Golden'],
    ),
    WeaponSpec(
      id: 'nova_burst',
      name: 'Nova Burst',
      description: 'Radial shock ring. Clears swarms around the ship.',
      rarity: WeaponRarity.legendary,
      damage: 18,
      fireRate: 2.2,
      range: 0.7,
      projectileSpeed: 380,
      pellets: 8,
      ammoPerShot: 2,
      spreadDeg: 360,
      color: Palette.gold,
      sfx: 'warp',
      unlockLevel: 20,
      coinCost: 5200,
      ability: WeaponAbility.overload,
      skins: ['Standard', 'Supernova'],
    ),
  ];

  static WeaponSpec byId(String id) =>
      all.firstWhere((w) => w.id == id, orElse: () => all.first);

  static List<WeaponSpec> get sorted => [...all]..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));
}

/// A saved loadout slot (feature 50).
class Loadout {
  const Loadout({
    required this.name,
    required this.weaponId,
    this.upgrades = const WeaponUpgrades(),
    this.skin = 'Standard',
  });

  final String name;
  final String weaponId;
  final WeaponUpgrades upgrades;
  final String skin;

  Loadout copyWith({String? name, String? weaponId, WeaponUpgrades? upgrades, String? skin}) {
    return Loadout(
      name: name ?? this.name,
      weaponId: weaponId ?? this.weaponId,
      upgrades: upgrades ?? this.upgrades,
      skin: skin ?? this.skin,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'weapon': weaponId,
        'upgrades': upgrades.toJson(),
        'skin': skin,
      };

  factory Loadout.fromJson(Map<String, dynamic> json) {
    return Loadout(
      name: (json['name'] as String?) ?? 'Loadout',
      weaponId: (json['weapon'] as String?) ?? 'pulse_rifle',
      upgrades: WeaponUpgrades.fromJson(json['upgrades'] as Map<String, dynamic>?),
      skin: (json['skin'] as String?) ?? 'Standard',
    );
  }

  static const Loadout defaultLoadout =
      Loadout(name: 'Alpha', weaponId: 'pulse_rifle');
}
