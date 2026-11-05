/// Metrics that achievements and missions are measured against.
class Metrics {
  const Metrics._();

  static const String kills = 'kills';
  static const String bossKills = 'bossKills';
  static const String runs = 'runs';
  static const String coinsEarned = 'coinsEarned';
  static const String gemsEarned = 'gemsEarned';
  static const String waves = 'waves';
  static const String powerUps = 'powerUps';
  static const String maxCombo = 'maxCombo';
  static const String accuracy = 'accuracy';
  static const String level = 'level';
  static const String bestScore = 'bestScore';
  static const String timePlayed = 'timePlayed';
  static const String levelsCompleted = 'levelsCompleted';
  static const String weaponsOwned = 'weaponsOwned';
  static const String totalUpgrades = 'totalUpgrades';
  static const String score = 'score';
}

/// Static achievement definition (features 129, 146).
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.metric,
    required this.target,
    required this.rewardCoins,
    required this.rewardGems,
    this.glyph = '★',
  });

  final String id;
  final String title;
  final String description;
  final String metric;
  final double target;
  final int rewardCoins;
  final int rewardGems;

  /// Rendered as an icon glyph in the achievement card.
  final String glyph;
}

/// Mutable per-achievement progress record.
class AchievementState {
  AchievementState({this.progress = 0, this.unlocked = false, this.claimed = false});

  double progress;
  bool unlocked;
  bool claimed;

  Map<String, dynamic> toJson() => {
        'p': progress,
        'u': unlocked,
        'c': claimed,
      };

  factory AchievementState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AchievementState();
    final p = json['p'];
    return AchievementState(
      progress: p is num ? p.toDouble() : 0,
      unlocked: json['u'] == true,
      claimed: json['c'] == true,
    );
  }
}

class AchievementCatalog {
  const AchievementCatalog._();

  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_blood',
      title: 'FIRST BLOOD',
      description: 'Destroy your first enemy.',
      metric: Metrics.kills,
      target: 1,
      rewardCoins: 50,
      rewardGems: 0,
      glyph: '✦',
    ),
    AchievementDef(
      id: 'centurion',
      title: 'CENTURION',
      description: 'Destroy 100 enemies.',
      metric: Metrics.kills,
      target: 100,
      rewardCoins: 200,
      rewardGems: 1,
      glyph: '✷',
    ),
    AchievementDef(
      id: 'exterminator',
      title: 'EXTERMINATOR',
      description: 'Destroy 1,000 enemies.',
      metric: Metrics.kills,
      target: 1000,
      rewardCoins: 800,
      rewardGems: 5,
      glyph: '✹',
    ),
    AchievementDef(
      id: 'boss_slayer',
      title: 'BOSS SLAYER',
      description: 'Defeat your first boss.',
      metric: Metrics.bossKills,
      target: 1,
      rewardCoins: 300,
      rewardGems: 3,
      glyph: '☠',
    ),
    AchievementDef(
      id: 'boss_hunter',
      title: 'BOSS HUNTER',
      description: 'Defeat 10 bosses.',
      metric: Metrics.bossKills,
      target: 10,
      rewardCoins: 1200,
      rewardGems: 10,
      glyph: '⚔',
    ),
    AchievementDef(
      id: 'combo_master',
      title: 'COMBO MASTER',
      description: 'Reach a 25x combo.',
      metric: Metrics.maxCombo,
      target: 25,
      rewardCoins: 400,
      rewardGems: 2,
      glyph: '⚡',
    ),
    AchievementDef(
      id: 'sharpshooter',
      title: 'SHARPSHOOTER',
      description: 'Finish a run with 70% accuracy.',
      metric: Metrics.accuracy,
      target: 70,
      rewardCoins: 500,
      rewardGems: 2,
      glyph: '◎',
    ),
    AchievementDef(
      id: 'collector',
      title: 'COLLECTOR',
      description: 'Collect 25 power-ups.',
      metric: Metrics.powerUps,
      target: 25,
      rewardCoins: 350,
      rewardGems: 1,
      glyph: '⬢',
    ),
    AchievementDef(
      id: 'wave_breaker',
      title: 'WAVE BREAKER',
      description: 'Clear 50 waves.',
      metric: Metrics.waves,
      target: 50,
      rewardCoins: 600,
      rewardGems: 3,
      glyph: '≋',
    ),
    AchievementDef(
      id: 'veteran',
      title: 'VETERAN',
      description: 'Reach account level 10.',
      metric: Metrics.level,
      target: 10,
      rewardCoins: 700,
      rewardGems: 4,
      glyph: '❖',
    ),
    AchievementDef(
      id: 'high_roller',
      title: 'HIGH ROLLER',
      description: 'Score 20,000 in a single run.',
      metric: Metrics.bestScore,
      target: 20000,
      rewardCoins: 900,
      rewardGems: 5,
      glyph: '◆',
    ),
    AchievementDef(
      id: 'armorer',
      title: 'ARMORER',
      description: 'Own 5 different weapons.',
      metric: Metrics.weaponsOwned,
      target: 5,
      rewardCoins: 650,
      rewardGems: 3,
      glyph: '⌖',
    ),
    AchievementDef(
      id: 'campaign_clear',
      title: 'VOID BREAKER',
      description: 'Complete all 10 campaign sectors.',
      metric: Metrics.levelsCompleted,
      target: 10,
      rewardCoins: 2500,
      rewardGems: 20,
      glyph: '✵',
    ),
    AchievementDef(
      id: 'marathon',
      title: 'MARATHON',
      description: 'Play for 30 minutes total.',
      metric: Metrics.timePlayed,
      target: 1800,
      rewardCoins: 400,
      rewardGems: 2,
      glyph: '⏱',
    ),
    AchievementDef(
      id: 'upgrader',
      title: 'FULLY LOADED',
      description: 'Purchase 10 weapon upgrades.',
      metric: Metrics.totalUpgrades,
      target: 10,
      rewardCoins: 800,
      rewardGems: 4,
      glyph: '⬆',
    ),
    AchievementDef(
      id: 'treasure',
      title: 'TREASURE HUNTER',
      description: 'Earn 5,000 coins in total.',
      metric: Metrics.coinsEarned,
      target: 5000,
      rewardCoins: 1000,
      rewardGems: 5,
      glyph: '⛁',
    ),
  ];

  static AchievementDef byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}
