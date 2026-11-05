import 'achievement.dart';
import 'mission.dart';
import 'weapon.dart';

/// Aggregated player statistics (feature 142).
class PlayerStats {
  PlayerStats({
    this.kills = 0,
    this.bossKills = 0,
    this.runsPlayed = 0,
    this.wavesCleared = 0,
    this.powerUpsCollected = 0,
    this.maxCombo = 0,
    this.coinsEarned = 0,
    this.gemsEarned = 0,
    this.shotsFired = 0,
    this.shotsHit = 0,
    this.timePlayedSeconds = 0,
    this.levelsCompleted = 0,
    this.bestScore = 0,
    this.bestScoreRun = 0,
    this.lastAccuracy = 0,
  });

  int kills;
  int bossKills;
  int runsPlayed;
  int wavesCleared;
  int powerUpsCollected;
  int maxCombo;
  int coinsEarned;
  int gemsEarned;
  int shotsFired;
  int shotsHit;
  int timePlayedSeconds;
  int levelsCompleted;
  int bestScore;

  /// Best score achieved within a single run (used for "score 25000 in one
  /// run" style missions).
  int bestScoreRun;
  double lastAccuracy;

  double get accuracy => shotsFired == 0 ? 0 : (shotsHit / shotsFired) * 100;

  Map<String, dynamic> toJson() => {
        'kills': kills,
        'bossKills': bossKills,
        'runs': runsPlayed,
        'waves': wavesCleared,
        'powerUps': powerUpsCollected,
        'maxCombo': maxCombo,
        'coinsEarned': coinsEarned,
        'gemsEarned': gemsEarned,
        'shotsFired': shotsFired,
        'shotsHit': shotsHit,
        'timePlayed': timePlayedSeconds,
        'levelsCompleted': levelsCompleted,
        'bestScore': bestScore,
        'bestScoreRun': bestScoreRun,
        'lastAccuracy': lastAccuracy,
      };

  factory PlayerStats.fromJson(Map<String, dynamic>? json) {
    final s = PlayerStats();
    if (json == null) return s;
    int i(String k) => json[k] is num ? (json[k] as num).toInt() : 0;
    double d(String k) => json[k] is num ? (json[k] as num).toDouble() : 0;
    s
      ..kills = i('kills')
      ..bossKills = i('bossKills')
      ..runsPlayed = i('runs')
      ..wavesCleared = i('waves')
      ..powerUpsCollected = i('powerUps')
      ..maxCombo = i('maxCombo')
      ..coinsEarned = i('coinsEarned')
      ..gemsEarned = i('gemsEarned')
      ..shotsFired = i('shotsFired')
      ..shotsHit = i('shotsHit')
      ..timePlayedSeconds = i('timePlayed')
      ..levelsCompleted = i('levelsCompleted')
      ..bestScore = i('bestScore')
      ..bestScoreRun = i('bestScoreRun')
      ..lastAccuracy = d('lastAccuracy');
    return s;
  }
}

/// Everything that persists for a player (features 141–149, 185–196).
class PlayerProfile {
  PlayerProfile({
    this.name = 'PILOT',
    this.level = 1,
    this.xp = 0,
    this.coins = 500,
    this.gems = 5,
    this.selectedWeaponId = 'pulse_rifle',
    this.selectedSkin = 'Standard',
    this.lastDailyClaimDay = '',
    this.loginStreak = 0,
    PlayerStats? stats,
    Map<String, WeaponUpgrades>? weapons,
    Map<String, String>? skins,
    Map<String, int>? highScores,
    Map<String, int>? bestScoresByMode,
    Set<int>? completedLevels,
    Map<String, AchievementState>? achievements,
    MissionBoard? missions,
    List<Loadout>? loadouts,
    this.activeLoadout = 0,
    this.unlockedCharacters = const ['Vanguard'],
    this.selectedCharacter = 'Vanguard',
  })  : stats = stats ?? PlayerStats(),
        weapons = weapons ?? {'pulse_rifle': const WeaponUpgrades()},
        skins = skins ?? {'pulse_rifle': 'Standard'},
        highScores = highScores ?? <String, int>{},
        bestScoresByMode = bestScoresByMode ?? <String, int>{},
        completedLevels = completedLevels ?? <int>{},
        achievements = achievements ?? <String, AchievementState>{},
        missions = missions ?? MissionBoard(),
        loadouts = loadouts ?? [Loadout.defaultLoadout];

  String name;
  int level;
  int xp;
  int coins;
  int gems;
  String selectedWeaponId;
  String selectedSkin;
  String lastDailyClaimDay;
  int loginStreak;
  PlayerStats stats;
  Map<String, WeaponUpgrades> weapons;
  Map<String, String> skins;
  Map<String, int> highScores;
  Map<String, int> bestScoresByMode;
  Set<int> completedLevels;
  Map<String, AchievementState> achievements;
  MissionBoard missions;
  List<Loadout> loadouts;
  int activeLoadout;
  List<String> unlockedCharacters;
  String selectedCharacter;

  /// XP required to advance from [level] to the next level.
  static int xpForLevel(int level) => 120 + (level - 1) * 90;

  int get xpToNext => xpForLevel(level);
  double get levelProgress => (xp / xpToNext).clamp(0.0, 1.0);

  WeaponUpgrades upgradesFor(String weaponId) => weapons[weaponId] ?? const WeaponUpgrades();

  bool ownsWeapon(String weaponId) => weapons.containsKey(weaponId);

  int get totalUpgrades => weapons.values.fold(0, (sum, u) => sum + u.totalLevels);

  int get weaponsOwned => weapons.length;

  int get campaignProgress => completedLevels.length;

  int get rank => 1 + level * 2 + stats.bossKills * 3 + stats.kills ~/ 50;

  /// Grants XP and returns the number of levels gained (feature 126–127).
  int addXp(int amount) {
    if (amount <= 0) return 0;
    xp += amount;
    var gained = 0;
    while (xp >= xpForLevel(level) && level < 99) {
      xp -= xpForLevel(level);
      level++;
      gained++;
    }
    return gained;
  }

  /// Snapshot of every metric used by achievements and missions.
  Map<String, double> metricSnapshot() => {
        Metrics.kills: stats.kills.toDouble(),
        Metrics.bossKills: stats.bossKills.toDouble(),
        Metrics.runs: stats.runsPlayed.toDouble(),
        Metrics.waves: stats.wavesCleared.toDouble(),
        Metrics.powerUps: stats.powerUpsCollected.toDouble(),
        Metrics.maxCombo: stats.maxCombo.toDouble(),
        Metrics.accuracy: stats.accuracy,
        Metrics.coinsEarned: stats.coinsEarned.toDouble(),
        Metrics.gemsEarned: stats.gemsEarned.toDouble(),
        Metrics.level: level.toDouble(),
        Metrics.bestScore: stats.bestScore.toDouble(),
        Metrics.timePlayed: stats.timePlayedSeconds.toDouble(),
        Metrics.levelsCompleted: stats.levelsCompleted.toDouble(),
        Metrics.weaponsOwned: weaponsOwned.toDouble(),
        Metrics.totalUpgrades: totalUpgrades.toDouble(),
        Metrics.score: stats.bestScoreRun.toDouble(),
      };

  int highScoreFor(String key) => highScores[key] ?? 0;

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level,
        'xp': xp,
        'coins': coins,
        'gems': gems,
        'weapon': selectedWeaponId,
        'skin': selectedSkin,
        'dailyClaim': lastDailyClaimDay,
        'streak': loginStreak,
        'stats': stats.toJson(),
        'weapons': weapons.map((k, v) => MapEntry(k, v.toJson())),
        'skins': skins,
        'highScores': highScores,
        'modeScores': bestScoresByMode,
        'completedLevels': completedLevels.toList(),
        'achievements': achievements.map((k, v) => MapEntry(k, v.toJson())),
        'missions': missions.toJson(),
        'loadouts': loadouts.map((l) => l.toJson()).toList(),
        'activeLoadout': activeLoadout,
        'characters': unlockedCharacters,
        'character': selectedCharacter,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final p = PlayerProfile();
    int i(String k, int fallback) => json[k] is num ? (json[k] as num).toInt() : fallback;
    String s(String k, String fallback) => json[k] is String ? json[k] as String : fallback;

    p.name = s('name', p.name);
    p.level = i('level', 1).clamp(1, 99);
    p.xp = i('xp', 0).clamp(0, 100000000);
    p.coins = i('coins', 0).clamp(0, 100000000);
    p.gems = i('gems', 0).clamp(0, 100000000);
    p.selectedWeaponId = s('weapon', 'pulse_rifle');
    p.selectedSkin = s('skin', 'Standard');
    p.lastDailyClaimDay = s('dailyClaim', '');
    p.loginStreak = i('streak', 0);
    p.stats = PlayerStats.fromJson(json['stats'] as Map<String, dynamic>?);
    p.activeLoadout = i('activeLoadout', 0);
    p.selectedCharacter = s('character', 'Vanguard');

    final weaponsRaw = json['weapons'];
    if (weaponsRaw is Map) {
      final map = <String, WeaponUpgrades>{};
      weaponsRaw.forEach((key, value) {
        if (key is String) {
          map[key] = WeaponUpgrades.fromJson(value is Map ? Map<String, dynamic>.from(value) : null);
        }
      });
      if (map.isNotEmpty) p.weapons = map;
    }

    final skinsRaw = json['skins'];
    if (skinsRaw is Map) {
      final map = <String, String>{};
      skinsRaw.forEach((key, value) {
        if (key is String && value is String) map[key] = value;
      });
      if (map.isNotEmpty) p.skins = map;
    }

    Map<String, int> intMap(Object? raw) {
      final map = <String, int>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          if (key is String && value is num) map[key] = value.toInt();
        });
      }
      return map;
    }

    p.highScores = intMap(json['highScores']);
    p.bestScoresByMode = intMap(json['modeScores']);

    final levelsRaw = json['completedLevels'];
    if (levelsRaw is List) {
      p.completedLevels = levelsRaw.whereType<num>().map((e) => e.toInt()).toSet();
    }

    final achRaw = json['achievements'];
    if (achRaw is Map) {
      final map = <String, AchievementState>{};
      achRaw.forEach((key, value) {
        if (key is String && value is Map) {
          map[key] = AchievementState.fromJson(Map<String, dynamic>.from(value));
        }
      });
      p.achievements = map;
    }

    p.missions = MissionBoard.fromJson(json['missions'] as Map<String, dynamic>?);

    final loadoutsRaw = json['loadouts'];
    if (loadoutsRaw is List) {
      final list = <Loadout>[];
      for (final item in loadoutsRaw) {
        if (item is Map) list.add(Loadout.fromJson(Map<String, dynamic>.from(item)));
      }
      if (list.isNotEmpty) p.loadouts = list;
    }

    final chars = json['characters'];
    if (chars is List) {
      final list = chars.whereType<String>().toList();
      if (list.isNotEmpty) p.unlockedCharacters = list;
    }

    if (p.activeLoadout >= p.loadouts.length) p.activeLoadout = 0;
    if (!p.weapons.containsKey('pulse_rifle')) {
      p.weapons['pulse_rifle'] = const WeaponUpgrades();
    }
    if (!p.weapons.containsKey(p.selectedWeaponId)) {
      p.selectedWeaponId = 'pulse_rifle';
    }
    return p;
  }
}

/// A single leaderboard entry (features 140, 178).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.score,
    required this.mode,
    required this.level,
    required this.at,
    this.isPlayer = false,
  });

  final String name;
  final int score;
  final String mode;
  final int level;
  final DateTime at;
  final bool isPlayer;

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'mode': mode,
        'level': level,
        'at': at.millisecondsSinceEpoch,
        'player': isPlayer,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        name: json['name'] as String? ?? 'PILOT',
        score: (json['score'] as num?)?.toInt() ?? 0,
        mode: json['mode'] as String? ?? 'campaign',
        level: (json['level'] as num?)?.toInt() ?? 1,
        at: DateTime.fromMillisecondsSinceEpoch((json['at'] as num?)?.toInt() ?? 0),
        isPlayer: json['player'] == true,
      );
}
