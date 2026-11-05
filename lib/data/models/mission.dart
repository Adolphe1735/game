import 'achievement.dart';

/// A single mission/challenge definition (features 130–132).
class MissionDef {
  const MissionDef({
    required this.id,
    required this.title,
    required this.metric,
    required this.target,
    required this.rewardCoins,
    required this.rewardXp,
  });

  final String id;
  final String title;
  final String metric;
  final double target;
  final int rewardCoins;
  final int rewardXp;
}

/// Progress record for one active mission. Progress is measured relative to a
/// baseline metric snapshot taken when the mission set was generated, so it is
/// stable across save/load.
class MissionState {
  MissionState({
    required this.def,
    required this.baseline,
    this.claimed = false,
  });

  final MissionDef def;
  final double baseline;
  bool claimed;

  double progress(double currentMetric) {
    final delta = currentMetric - baseline;
    if (delta <= 0) return 0;
    return delta > def.target ? def.target : delta;
  }

  bool complete(double currentMetric) => progress(currentMetric) >= def.target;

  Map<String, dynamic> toJson() => {
        'id': def.id,
        'base': baseline,
        'claimed': claimed,
      };
}

/// The rolling set of daily missions and weekly challenges.
class MissionBoard {
  MissionBoard({
    this.dayKey = '',
    this.weekKey = '',
    List<MissionState>? daily,
    List<MissionState>? weekly,
  })  : daily = daily ?? <MissionState>[],
        weekly = weekly ?? <MissionState>[];

  String dayKey;
  String weekKey;
  List<MissionState> daily;
  List<MissionState> weekly;

  Map<String, dynamic> toJson() => {
        'day': dayKey,
        'week': weekKey,
        'daily': daily.map((m) => m.toJson()).toList(),
        'weekly': weekly.map((m) => m.toJson()).toList(),
      };

  factory MissionBoard.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MissionBoard();
    List<MissionState> read(Object? raw) {
      if (raw is! List) return <MissionState>[];
      final out = <MissionState>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = map['id'];
        if (id is! String) continue;
        final def = _defById(id);
        if (def == null) continue;
        final base = map['base'];
        out.add(MissionState(
          def: def,
          baseline: base is num ? base.toDouble() : 0,
          claimed: map['claimed'] == true,
        ));
      }
      return out;
    }

    return MissionBoard(
      dayKey: json['day'] as String? ?? '',
      weekKey: json['week'] as String? ?? '',
      daily: read(json['daily']),
      weekly: read(json['weekly']),
    );
  }

  static MissionDef? _defById(String id) {
    for (final d in MissionCatalog.dailyPool) {
      if (d.id == id) return d;
    }
    for (final d in MissionCatalog.weeklyPool) {
      if (d.id == id) return d;
    }
    return null;
  }
}

class MissionCatalog {
  const MissionCatalog._();

  static const List<MissionDef> dailyPool = [
    MissionDef(
      id: 'd_kill_20',
      title: 'Destroy 20 enemies',
      metric: Metrics.kills,
      target: 20,
      rewardCoins: 120,
      rewardXp: 60,
    ),
    MissionDef(
      id: 'd_kill_40',
      title: 'Destroy 40 enemies',
      metric: Metrics.kills,
      target: 40,
      rewardCoins: 220,
      rewardXp: 110,
    ),
    MissionDef(
      id: 'd_wave_5',
      title: 'Clear 5 waves',
      metric: Metrics.waves,
      target: 5,
      rewardCoins: 150,
      rewardXp: 70,
    ),
    MissionDef(
      id: 'd_powerup_3',
      title: 'Collect 3 power-ups',
      metric: Metrics.powerUps,
      target: 3,
      rewardCoins: 100,
      rewardXp: 50,
    ),
    MissionDef(
      id: 'd_runs_2',
      title: 'Finish 2 runs',
      metric: Metrics.runs,
      target: 2,
      rewardCoins: 90,
      rewardXp: 40,
    ),
    MissionDef(
      id: 'd_coins_300',
      title: 'Earn 300 coins',
      metric: Metrics.coinsEarned,
      target: 300,
      rewardCoins: 140,
      rewardXp: 60,
    ),
    MissionDef(
      id: 'd_combo_10',
      title: 'Reach a 10x combo',
      metric: Metrics.maxCombo,
      target: 10,
      rewardCoins: 130,
      rewardXp: 55,
    ),
    MissionDef(
      id: 'd_score_4000',
      title: 'Score 4,000 in one run',
      metric: Metrics.score,
      target: 4000,
      rewardCoins: 160,
      rewardXp: 80,
    ),
    MissionDef(
      id: 'd_accuracy_60',
      title: 'End a run at 60% accuracy',
      metric: Metrics.accuracy,
      target: 60,
      rewardCoins: 150,
      rewardXp: 70,
    ),
    MissionDef(
      id: 'd_boss_1',
      title: 'Defeat a boss',
      metric: Metrics.bossKills,
      target: 1,
      rewardCoins: 250,
      rewardXp: 120,
    ),
  ];

  static const List<MissionDef> weeklyPool = [
    MissionDef(
      id: 'w_kill_250',
      title: 'Destroy 250 enemies this week',
      metric: Metrics.kills,
      target: 250,
      rewardCoins: 900,
      rewardXp: 400,
    ),
    MissionDef(
      id: 'w_wave_30',
      title: 'Clear 30 waves this week',
      metric: Metrics.waves,
      target: 30,
      rewardCoins: 800,
      rewardXp: 350,
    ),
    MissionDef(
      id: 'w_boss_3',
      title: 'Defeat 3 bosses this week',
      metric: Metrics.bossKills,
      target: 3,
      rewardCoins: 1000,
      rewardXp: 450,
    ),
    MissionDef(
      id: 'w_score_25000',
      title: 'Score 25,000 in a single run',
      metric: Metrics.score,
      target: 25000,
      rewardCoins: 1100,
      rewardXp: 500,
    ),
    MissionDef(
      id: 'w_time_900',
      title: 'Play for 15 minutes this week',
      metric: Metrics.timePlayed,
      target: 900,
      rewardCoins: 700,
      rewardXp: 300,
    ),
    MissionDef(
      id: 'w_powerup_15',
      title: 'Collect 15 power-ups this week',
      metric: Metrics.powerUps,
      target: 15,
      rewardCoins: 750,
      rewardXp: 320,
    ),
  ];
}
