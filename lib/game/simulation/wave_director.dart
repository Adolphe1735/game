import 'dart:math' as math;

import '../../core/utils/vec.dart';
import '../../data/models/enemy_spec.dart';
import '../../data/models/game_mode.dart';
import 'sim_entities.dart';

/// A single scheduled spawn inside a wave.
class WaveSpawn {
  const WaveSpawn(this.spec, this.delay, this.x, {this.slot = 0, this.amp = 40});

  final EnemySpec spec;
  final double delay;
  final double x;
  final int slot;
  final double amp;
}

/// One wave: a queue of spawns plus an optional boss.
class WavePlan {
  const WavePlan({required this.spawns, this.boss});

  final List<WaveSpawn> spawns;
  final BossSpec? boss;

  bool get isEmpty => spawns.isEmpty && boss == null;
}

/// Procedural wave composition (features 3, 59, 64, 72, 74, 182).
class WaveDirector {
  WaveDirector({
    required this.config,
    required this.rng,
  });

  final RunConfig config;
  final Rng rng;

  static const double worldWidth = 480;

  WavePlan build(int waveIndex) {
    if (config.waveHasBoss(waveIndex)) {
      final boss = _bossFor(waveIndex);
      return WavePlan(spawns: const [], boss: boss);
    }
    final pool = _pool();
    final difficulty = config.difficulty;
    final base = 3 + waveIndex + config.level ~/ 2;
    final count = (base * difficulty.spawnRate).round().clamp(3, 26);

    final spawns = <WaveSpawn>[];
    final formation = rng.nextInt(3); // 0 = line, 1 = V, 2 = arc
    for (var i = 0; i < count; i++) {
      final spec = _roll(pool, waveIndex);
      final double x;
      switch (formation) {
        case 1:
          x = (worldWidth / 2) + (i.isEven ? -1 : 1) * (34.0 + (i / 2) * 26.0);
          break;
        case 2:
          final t = count == 1 ? 0.5 : i / (count - 1);
          x = 70 + t * (worldWidth - 140);
          break;
        default:
          x = 50 + (i * 97) % (worldWidth - 100);
      }
      spawns.add(WaveSpawn(
        spec,
        i * (0.42 / difficulty.spawnRate) + rng.range(0, 0.25),
        x.clamp(28.0, worldWidth - 28.0),
        slot: i,
        amp: 20 + rng.range(10, 50),
      ));
    }
    return WavePlan(spawns: spawns);
  }

  List<EnemySpec> _pool() {
    final pool = EnemyCatalog.poolForLevel(math.max(1, config.level)).toList();
    if (config.mode == GameMode.bossRush) {
      return [
        EnemyCatalog.byId('drone'),
        EnemyCatalog.byId('swift'),
        EnemyCatalog.byId('lancer'),
      ];
    }
    return pool;
  }

  EnemySpec _roll(List<EnemySpec> pool, int waveIndex) {
    // Later waves bias toward tougher archetypes.
    final maxTier = math.min(pool.length, 2 + waveIndex ~/ 2 + config.level ~/ 3);
    final tierPool = pool.take(math.max(1, maxTier)).toList();
    if (rng.chance(0.12) && pool.length > tierPool.length) {
      return pool[rng.nextInt(pool.length)];
    }
    return tierPool[rng.nextInt(tierPool.length)];
  }

  BossSpec _bossFor(int waveIndex) {
    switch (config.mode) {
      case GameMode.bossRush:
        return EnemyCatalog.bosses[waveIndex.clamp(0, EnemyCatalog.bosses.length - 1)];
      case GameMode.endless:
        return EnemyCatalog.bosses[(waveIndex ~/ 5) % EnemyCatalog.bosses.length];
      default:
        return EnemyCatalog.bossForLevel(config.level);
    }
  }
}
