import 'dart:math' as math;
import 'dart:ui' show Color;

import '../../core/utils/vec.dart';
import '../../data/models/enemy_spec.dart';
import '../../data/models/game_mode.dart';
import '../../data/models/weapon.dart';
import 'sim_entities.dart';
import 'wave_director.dart';

/// Pure-Dart gameplay simulation.
///
/// Deliberately free of Flutter/Flame imports (except `dart:ui` colors) so the
/// whole rule set can be exercised by unit tests without a rendering context.
class ArenaSimulation {
  ArenaSimulation(this.config)
      : rng = Rng(config.seed),
        _worldWidth = worldWidth,
        _worldHeight = worldHeight {
    _waveDirector = WaveDirector(config: config, rng: rng);
  }

  static const double worldWidth = 480;
  static const double worldHeight = 800;

  final RunConfig config;
  final Rng rng;
  final double _worldWidth;
  final double _worldHeight;
  late final WaveDirector _waveDirector;

  final List<Bullet> playerBullets = [];
  final List<Bullet> enemyBullets = [];
  final List<EnemyUnit> enemies = [];
  final List<Pickup> pickups = [];
  final List<SimEvent> events = [];

  late PlayerState player;
  BossUnit? boss;

  RunPhase phase = RunPhase.running;
  bool paused = false;

  int score = 0;
  int coins = 0;
  int gems = 0;
  int xp = 0;
  int kills = 0;
  int bossKills = 0;
  int wavesCleared = 0;
  int powerUpsCollected = 0;
  int shotsFired = 0;
  int shotsHit = 0;
  int maxCombo = 0;
  int _nextEnemyId = 1;

  double elapsed = 0;
  double timeRemaining = 0;

  int waveIndex = 0;
  bool waveActive = false;
  double interWaveTimer = 0;
  final List<WaveSpawn> _pendingSpawns = [];
  double _spawnClock = 0;

  /// Dynamic difficulty nudge (feature 183): rises with clean play, falls when
  /// the player is losing lives.
  double dynamicThreat = 1.0;

  /// Screen shake magnitude requested by the last event batch.
  double shakeEnergy = 0;
  double hitFlash = 0;

  bool levelCleared = false;
  bool _resultEmitted = false;
  RunResult? finalResult;

  bool get isFinished => phase != RunPhase.running;
  double get survivalTime => elapsed;

  double get accuracy => shotsFired == 0 ? 0 : (shotsHit / shotsFired) * 100;

  double get waveProgress {
    final total = config.totalWaves;
    if (total >= (1 << 30)) return 0;
    return (wavesCleared / total).clamp(0.0, 1.0);
  }

  int get displayLevel => config.level;

  /// Builds the initial state. Safe to call once.
  void start() {
    player = PlayerState(
      pos: const V2(worldWidth / 2, worldHeight - 130),
      health: 100,
      lives: config.startingLives,
      ammoCapacity: config.weaponStats.ammoCapacity,
    );
    timeRemaining = config.modeSpec.durationSeconds.toDouble();
    _startWave();
  }

  void pause() => paused = true;
  void resume() => paused = false;

  /// Consumes and returns pending events exactly once (audio/particles/UI).
  List<SimEvent> drainEvents() {
    if (events.isEmpty) return const [];
    final out = List<SimEvent>.from(events);
    events.clear();
    return out;
  }

  // ---------------------------------------------------------------- main loop

  void update(double dt, SimInput input) {
    if (isFinished || paused) return;
    // Clamp large frame spikes so a backgrounded tab cannot teleport anything.
    final step = dt.clamp(0.0, 1 / 20);
    elapsed += step;

    if (config.modeSpec.durationSeconds > 0) {
      timeRemaining -= step;
      if (timeRemaining <= 0) {
        timeRemaining = 0;
        _finish(RunPhase.timeUp);
        return;
      }
    }

    _updatePlayer(step, input);
    _updateSpawning(step);
    _updateEnemies(step);
    _updateBoss(step);
    _updateBullets(step);
    _updatePickups(step);
    _resolveCollisions();

    hitFlash = math.max(0, hitFlash - step * 2.2);
    shakeEnergy = math.max(0, shakeEnergy - step * 26);
    dynamicThreat = approach(dynamicThreat, 1.0 + (score / 40000).clamp(0.0, 0.45), 0.3, step);

    _checkWaveCompletion();
  }

  // ------------------------------------------------------------------- player

  void _updatePlayer(double dt, SimInput input) {
    final p = player;
    if (!p.isAlive) return;

    p.invuln = math.max(0, p.invuln - dt);
    p.shieldTime = math.max(0, p.shieldTime - dt);
    p.speedBoost = math.max(0, p.speedBoost - dt);
    p.damageBoost = math.max(0, p.damageBoost - dt);
    p.rapidBoost = math.max(0, p.rapidBoost - dt);
    p.magnetTime = math.max(0, p.magnetTime - dt);
    p.recoil = approach(p.recoil, 0, 9, dt);

    final baseSpeed = 330.0;
    final speed = baseSpeed * (p.speedBoost > 0 ? 1.55 : 1.0) * config.difficulty.spawnRate.clamp(0.9, 1.15);
    final move = input.move.length > 1.0 ? input.move.normalized : input.move;
    final targetVel = move * speed;
    p.vel = p.vel.lerpTo(targetVel, 1 - math.exp(-14 * dt));
    p.pos = p.pos + p.vel * dt;
    p.thruster = approach(p.thruster, move.length, 8, dt);
    p.bank = approach(p.bank, (move.x * 0.5).clamp(-0.6, 0.6), 8, dt);

    p.pos = V2(
      p.pos.x.clamp(24.0, _worldWidth - 24.0),
      p.pos.y.clamp(90.0, _worldHeight - 40.0),
    );

    // Reload handling (feature 18).
    if (p.reloadTimer > 0) {
      p.reloadTimer -= dt;
      if (p.reloadTimer <= 0) {
        p.reloadTimer = 0;
        if (config.weaponStats.ammoCapacity > 0) {
          p.ammo = config.weaponStats.ammoCapacity;
        }
        events.add(SimEvent(SimEventType.reloadFinished, pos: p.pos));
      }
    }

    p.fireCooldown = math.max(0, p.fireCooldown - dt);
    if (input.firing) _tryFire(input.aim);

    if (input.useSpecial && p.specialReady) _fireSpecial();
  }

  void _tryFire(V2 rawAim) {
    final p = player;
    final stats = config.weaponStats;
    if (p.fireCooldown > 0 || p.isReloading) return;

    final needsAmmo = stats.ammoCapacity > 0;
    if (needsAmmo && p.ammo < math.max(1, stats.ammoPerShot)) {
      _beginReload();
      return;
    }

    final aim = rawAim.length < 0.001 ? const V2(0, -1) : rawAim.normalized;
    final spread = stats.spreadDeg * math.pi / 180;
    final pellets = stats.pellets;
    for (var i = 0; i < pellets; i++) {
      final double angle;
      if (spread >= math.pi * 1.9) {
        angle = (i / pellets) * math.pi * 2;
      } else if (pellets == 1) {
        angle = 0;
      } else {
        angle = -spread / 2 + (spread * i / (pellets - 1));
      }
      final dir = aim.rotated(angle);
      final muzzle = p.pos + dir * 18;
      playerBullets.add(Bullet(
        pos: muzzle,
        vel: dir * stats.projectileSpeed,
        damage: stats.damage * (p.damageBoost > 0 ? 1.35 : 1.0),
        radius: stats.explosionRadius > 0 ? 7 : 4.5,
        color: _weaponColor,
        life: stats.range,
        pierce: stats.pierce,
        explosionRadius: stats.explosionRadius,
        glow: stats.explosionRadius > 0 ? 1.6 : 1.0,
      ));
    }

    shotsFired += pellets;
    p.recoil = 1;
    p.fireCooldown = stats.shotInterval * (p.rapidBoost > 0 ? 0.55 : 1.0);
    if (needsAmmo) p.ammo -= stats.ammoPerShot;
    if (needsAmmo && p.ammo <= 0) _beginReload();

    events.add(SimEvent(SimEventType.shotFired, pos: p.pos, color: _weaponColor, label: _weaponSfx));
  }

  void _beginReload() {
    final p = player;
    if (p.isReloading) return;
    p.reloadTimer = p.reloadDuration;
    events.add(SimEvent(SimEventType.reloadStarted, pos: p.pos));
  }

  /// Manual reload request from the HUD.
  void requestReload() {
    if (config.weaponStats.ammoCapacity <= 0) return;
    if (player.ammo >= config.weaponStats.ammoCapacity) return;
    _beginReload();
  }

  void _fireSpecial() {
    final p = player;
    p.specialCharge = 0;
    p.specialReady;
    p.invuln = math.max(p.invuln, 0.9);
    shakeEnergy = 30;
    events.add(SimEvent(SimEventType.specialUsed, pos: p.pos, color: const Color(0xFF9D6BFF)));
    // Radial damage burst.
    for (final e in enemies) {
      _damageEnemy(e, 120, showHit: false);
    }
    if (boss != null) _damageBoss(boss!, 180);
    enemyBullets.clear();
    p.ammo = config.weaponStats.ammoCapacity;
    p.reloadTimer = 0;
  }

  Color get _weaponColor {
    final spec = WeaponCatalog.byId(config.weaponId);
    return spec.color;
  }

  String get _weaponSfx => WeaponCatalog.byId(config.weaponId).sfx;

  // ----------------------------------------------------------------- spawning

  void _startWave() {
    final plan = _waveDirector.build(waveIndex);
    waveActive = true;
    _spawnClock = 0;
    _pendingSpawns
      ..clear()
      ..addAll(plan.spawns);
    if (plan.boss != null) _spawnBoss(plan.boss!);
    if (plan.spawns.isNotEmpty) {
      events.add(SimEvent(SimEventType.bossSpawned, label: 'WAVE ${waveIndex + 1}'));
    }
  }

  void _updateSpawning(double dt) {
    if (!waveActive) {
      if (interWaveTimer > 0) {
        interWaveTimer -= dt;
        if (interWaveTimer <= 0) {
          interWaveTimer = 0;
          waveIndex++;
          _startWave();
        }
      }
      return;
    }

    _spawnClock += dt;
    for (var i = _pendingSpawns.length - 1; i >= 0; i--) {
      final spawn = _pendingSpawns[i];
      if (_spawnClock < spawn.delay) continue;
      _pendingSpawns.removeAt(i);
      _spawnEnemy(spawn);
    }
  }

  void _spawnEnemy(WaveSpawn spawn) {
    final spec = spawn.spec;
    final hp = spec.hp * config.difficulty.enemyHealth * config.levelScale * dynamicThreat;
    final unit = EnemyUnit(
      id: _nextEnemyId++,
      spec: spec,
      pos: V2(spawn.x, -40 - rng.range(0, 60)),
      hp: hp,
      maxHp: hp,
      laneX: spawn.x,
      phaseOffset: rng.range(0, math.pi * 2),
      amp: spawn.amp,
      targetY: 130 + (spawn.slot % 4) * 55,
    )..slot = spawn.slot;
    unit.spawnT = 0;
    enemies.add(unit);
  }

  void _spawnBoss(BossSpec spec) {
    final hp = spec.hp * config.difficulty.enemyHealth * config.levelScale;
    final unit = BossUnit(
      spec: spec,
      pos: V2(_worldWidth / 2, -90),
      hp: hp,
    )..maxHp = hp;
    boss = unit;
    eventBusAdd(SimEvent(SimEventType.bossSpawned, pos: unit.pos, color: spec.color, label: spec.name));
  }

  void eventBusAdd(SimEvent event) => events.add(event);

  /// Boss summon helper used by swarm phases.
  void spawnAdds(int count) {
    final spec = EnemyCatalog.byId('drone');
    for (var i = 0; i < count; i++) {
      final x = boss?.pos.x ?? _worldWidth / 2;
      _spawnEnemy(WaveSpawn(
        spec,
        0,
        (x + (i - (count - 1) / 2) * 46).clamp(30.0, _worldWidth - 30),
        slot: i,
        amp: 30,
      ));
    }
  }

  // ------------------------------------------------------------------ enemies

  void _updateEnemies(double dt) {
    final p = player;
    for (final e in enemies) {
      if (e.dead) continue;
      e.age += dt;
      e.spawnT = math.min(1, e.spawnT + dt * 2.4);
      e.hitFlash = math.max(0, e.hitFlash - dt * 4);

      final spec = e.spec;
      final speed = spec.speed * config.difficulty.spawnRate.clamp(0.85, 1.3);
      var v = V2.zero;
      switch (spec.move) {
        case MovePattern.straight:
          v = V2(0, speed);
          break;
        case MovePattern.sine:
          v = V2(math.cos(e.age * 2.1 + e.phaseOffset) * e.amp, speed);
          break;
        case MovePattern.zigzag:
          v = V2(math.sin(e.age * 4.4 + e.phaseOffset) * e.amp * 1.8, speed);
          break;
        case MovePattern.dive:
          final dir = (p.pos - e.pos).normalized;
          v = dir * (speed * 1.35);
          break;
        case MovePattern.orbit:
          final toPlayer = (p.pos - e.pos).normalized;
          final tangent = toPlayer.perpendicular;
          v = tangent * speed + toPlayer * (speed * 0.12);
          break;
        case MovePattern.drift:
          v = V2(math.sin(e.age * 0.8) * speed * 0.6, speed * 0.55);
          break;
        case MovePattern.strafe:
        case MovePattern.formation:
          final targetY = e.targetY;
          final descend = e.pos.y < targetY ? speed : 0.0;
          final sway = math.sin(e.age * 1.4 + e.phaseOffset) * speed * 0.9;
          v = V2(sway, descend);
          break;
      }

      e.vel = v;
      e.pos = e.pos + v * dt;

      if (spec.move == MovePattern.zigzag || spec.move == MovePattern.sine) {
        if (e.pos.x < 26 && e.vel.x < 0) e.pos = V2(26, e.pos.y);
        if (e.pos.x > _worldWidth - 26 && e.vel.x > 0) {
          e.pos = V2(_worldWidth - 26, e.pos.y);
        }
      } else if (spec.move == MovePattern.strafe || spec.move == MovePattern.formation) {
        e.pos = V2(e.pos.x.clamp(30.0, _worldWidth - 30.0), e.pos.y);
      }

      // Shooters fire aimed bolts once they are on screen.
      if (spec.fireInterval > 0 && e.pos.y > 0 && e.pos.y < _worldHeight * 0.8) {
        e.fireTimer -= dt;
        if (e.fireTimer <= 0) {
          e.fireTimer = spec.fireInterval / config.difficulty.spawnRate.clamp(0.9, 1.4);
          _enemyShoot(e);
        }
      }

      // Escaped enemies: no penalty beyond wasted opportunity.
      if (e.pos.y > _worldHeight + 60) {
        e.dead = true;
      }
    }
    enemies.removeWhere((e) => e.dead);
  }

  void _enemyShoot(EnemyUnit e) {
    final dir = (player.pos - e.pos).normalized;
    enemyBullets.add(Bullet(
      pos: e.pos + dir * (e.spec.radius * 0.8),
      vel: dir * e.spec.bulletSpeed,
      damage: e.spec.bulletDamage * config.difficulty.enemyDamage,
      radius: 5,
      color: e.spec.color,
      life: 5,
      hostile: true,
    ));
    events.add(SimEvent(SimEventType.enemyHit, pos: e.pos, color: e.spec.color));
  }

  // --------------------------------------------------------------------- boss

  void _updateBoss(double dt) {
    final b = boss;
    if (b == null || b.dead) return;
    b.age += dt;
    b.hitFlash = math.max(0, b.hitFlash - dt * 4);

    if (b.entry > 0) {
      b.entry -= dt;
      b.pos = b.pos.lerpTo(V2(_worldWidth / 2, 130), 1 - math.exp(-4 * dt));
      return;
    }

    // Phase transitions.
    final fraction = b.hpFraction;
    var target = 0;
    for (var i = 0; i < b.spec.phases.length; i++) {
      if (fraction <= b.spec.phases[i].hpFraction) target = i;
    }
    if (target > b.phaseIndex) {
      b.phaseIndex = target;
      b.fireTimer = 0.5;
      shakeEnergy = 22;
      events.add(SimEvent(SimEventType.bossPhase, pos: b.pos, color: b.spec.color, label: b.phase.name));
      if (b.phase.addsCount > 0) spawnAdds(b.phase.addsCount);
    }

    // Slow patrol along the top of the arena.
    final targetX = _worldWidth / 2 + math.sin(b.age * 0.6) * (_worldWidth / 2 - 110);
    b.pos = V2(approach(b.pos.x, targetX, 1.8, dt), approach(b.pos.y, 140 + math.sin(b.age * 0.9) * 16, 1.2, dt));

    final phase = b.phase;
    b.fireTimer -= dt;
    if (b.fireTimer > 0) return;
    b.fireTimer = phase.fireInterval / config.difficulty.spawnRate.clamp(0.85, 1.35);

    final color = b.spec.color;
    switch (phase.pattern) {
      case BossPattern.radialBurst:
        const count = 14;
        for (var i = 0; i < count; i++) {
          final a = (i / count) * math.pi * 2 + b.age * 0.4;
          _bossBolt(b.pos, V2(math.cos(a), math.sin(a)) * phase.bulletSpeed, phase.bulletSpeed, color);
        }
        break;
      case BossPattern.aimedSalvo:
        final base = (player.pos - b.pos).normalized;
        for (var i = -2; i <= 2; i++) {
          _bossBolt(b.pos, base.rotated(i * 0.13) * phase.bulletSpeed, phase.bulletSpeed, color);
        }
        break;
      case BossPattern.spiral:
        b.spiralAngle += 0.42;
        for (var arm = 0; arm < 3; arm++) {
          final a = b.spiralAngle + arm * math.pi * 2 / 3;
          _bossBolt(b.pos, V2(math.cos(a), math.sin(a)) * phase.bulletSpeed, phase.bulletSpeed, color);
        }
        break;
      case BossPattern.sweepingLaser:
        b.sweepAngle += 0.55;
        final sweep = math.sin(b.sweepAngle) * 0.9;
        for (var i = 0; i < 4; i++) {
          final a = math.pi / 2 + sweep + (i - 1.5) * 0.16;
          _bossBolt(b.pos, V2(math.cos(a), math.sin(a)) * phase.bulletSpeed, phase.bulletSpeed, color);
        }
        break;
      case BossPattern.swarmRecall:
        spawnedRecall(b);
        _bossBolt(b.pos, (player.pos - b.pos).normalized * phase.bulletSpeed, phase.bulletSpeed, color);
        break;
    }
    events.add(SimEvent(SimEventType.bossHit, pos: b.pos, color: color, value: 0));
  }

  void spawnedRecall(BossUnit b) {
    if (enemies.length < 22 && rng.chance(0.6)) spawnAdds(2);
  }

  void _bossBolt(V2 origin, V2 vel, double speed, Color color) {
    enemyBullets.add(Bullet(
      pos: origin,
      vel: vel,
      damage: 12 * config.difficulty.enemyDamage,
      radius: 7,
      color: color,
      life: 6,
      hostile: true,
      glow: 1.4,
    ));
  }

  // ------------------------------------------------------------------ bullets

  void _updateBullets(double dt) {
    for (final b in playerBullets) {
      if (b.dead) continue;
      b.age += dt;
      b.life -= dt;
      b.pos = b.pos + b.vel * dt;
      if (b.life <= 0 || b.pos.y < -40 || b.pos.x < -40 || b.pos.x > _worldWidth + 40 || b.pos.y > _worldHeight + 40) {
        b.dead = true;
      }
    }
    for (final b in enemyBullets) {
      if (b.dead) continue;
      b.age += dt;
      b.life -= dt;
      b.pos = b.pos + b.vel * dt;
      if (b.life <= 0 || b.pos.y < -40 || b.pos.x < -40 || b.pos.x > _worldWidth + 40 || b.pos.y > _worldHeight + 40) {
        b.dead = true;
      }
    }
    playerBullets.removeWhere((b) => b.dead);
    enemyBullets.removeWhere((b) => b.dead);
  }

  // ------------------------------------------------------------------ pickups

  void _updatePickups(double dt) {
    final p = player;
    for (final pickup in pickups) {
      pickup.age += dt;
      pickup.life -= dt;
      final toPlayer = p.pos - pickup.pos;
      final magnet = p.magnetTime > 0 || toPlayer.length < 110;
      if (magnet && toPlayer.length < 260 && p.isAlive) {
        pickup.vel = toPlayer.normalized * 340;
      } else {
        pickup.vel = V2(pickup.vel.x * 0.96, math.min(pickup.vel.y + 30 * dt, 70));
      }
      pickup.pos = pickup.pos + pickup.vel * dt;
      pickup.pos = V2(pickup.pos.x.clamp(16.0, _worldWidth - 16.0), pickup.pos.y);

      if (toPlayer.length < 24 && p.isAlive) {
        _collect(pickup);
        pickup.dead = true;
      } else if (pickup.life <= 0 || pickup.pos.y > _worldHeight + 40) {
        pickup.dead = true;
      }
    }
    pickups.removeWhere((pk) => pk.dead);
  }

  void _collect(Pickup pickup) {
    final p = player;
    switch (pickup.kind) {
      case PickupKind.coin:
        coins += pickup.value;
        score += pickup.value * 2;
        events.add(SimEvent(SimEventType.coinCollected, pos: pickup.pos, value: pickup.value));
        break;
      case PickupKind.gem:
        gems += pickup.value;
        score += pickup.value * 25;
        events.add(SimEvent(SimEventType.gemCollected, pos: pickup.pos, value: pickup.value));
        break;
      case PickupKind.powerUp:
        final kind = pickup.powerUp ?? PowerUpKind.heal;
        powerUpsCollected++;
        p.specialCharge = math.min(100, p.specialCharge + 8);
        switch (kind) {
          case PowerUpKind.shield:
            p.shieldTime = 12;
            break;
          case PowerUpKind.heal:
            p.health = math.min(p.maxHealth, p.health + 30);
            break;
          case PowerUpKind.speed:
            p.speedBoost = 7;
            break;
          case PowerUpKind.damageBoost:
            p.damageBoost = 9;
            break;
          case PowerUpKind.rapidBoost:
            p.rapidBoost = 7;
            break;
          case PowerUpKind.ammo:
            p.ammo = config.weaponStats.ammoCapacity;
            p.reloadTimer = 0;
            break;
          case PowerUpKind.bomb:
            for (final e in enemies) {
              _damageEnemy(e, 75, showHit: false);
            }
            if (boss != null) _damageBoss(boss!, 90);
            enemyBullets.clear();
            shakeEnergy = 18;
            break;
          case PowerUpKind.coinMagnet:
            p.magnetTime = 10;
            break;
          case PowerUpKind.extraLife:
            p.lives += 1;
            break;
        }
        events.add(SimEvent(
          SimEventType.powerUpCollected,
          pos: pickup.pos,
          color: kind.color,
          label: kind.label,
        ));
        break;
    }
  }

  // --------------------------------------------------------------- collisions

  void _resolveCollisions() {
    final p = player;

    // Player bullets vs enemies.
    for (final bullet in playerBullets) {
      if (bullet.dead) continue;
      for (final enemy in enemies) {
        if (enemy.dead) continue;
        if (bullet.pos.distanceSquaredTo(enemy.pos) <= math.pow(enemy.spec.radius + bullet.radius, 2)) {
          bullet.hits++;
          shotsHit++;
          _damageEnemy(enemy, bullet.damage);
          if (bullet.explosionRadius > 0) {
            _explode(bullet.pos, bullet.explosionRadius, bullet.damage * 0.6, color: bullet.color);
          }
          if (bullet.hits > bullet.pierce) bullet.dead = true;
          break;
        }
      }
      if (bullet.dead) continue;
      final b = boss;
      if (b != null && !b.dead && b.entry <= 0) {
        if (bullet.pos.distanceSquaredTo(b.pos) <= math.pow(b.spec.radius + bullet.radius, 2)) {
          bullet.hits++;
          shotsHit++;
          _damageBoss(b, bullet.damage);
          if (bullet.explosionRadius > 0) {
            _explode(bullet.pos, bullet.explosionRadius, bullet.damage * 0.5, color: bullet.color);
          }
          if (bullet.hits > bullet.pierce) bullet.dead = true;
        }
      }
    }

    if (!p.isAlive) return;

    // Enemy bullets vs player.
    for (final bullet in enemyBullets) {
      if (bullet.dead) continue;
      if (bullet.pos.distanceSquaredTo(p.pos) <= math.pow(p.radius + bullet.radius, 2)) {
        bullet.dead = true;
        _damagePlayer(bullet.damage);
      }
    }

    // Contact damage from body collisions.
    for (final enemy in enemies) {
      if (enemy.dead) continue;
      if (enemy.pos.distanceSquaredTo(p.pos) <= math.pow(enemy.spec.radius + p.radius, 2)) {
        _damageEnemy(enemy, enemy.spec.hp * 0.45, showHit: false);
        _damagePlayer(enemy.spec.klass == EnemyClass.fast ? 16 : 11);
      }
    }
  }

  void _explode(V2 center, double radius, double damage, {Color? color}) {
    for (final e in enemies) {
      if (e.dead) continue;
      if (e.pos.distanceSquaredTo(center) <= math.pow(radius + e.spec.radius, 2)) {
        _damageEnemy(e, damage, showHit: false);
      }
    }
    events.add(SimEvent(SimEventType.explosion, pos: center, color: color));
  }

  // ------------------------------------------------------------------ damage

  void _damageEnemy(EnemyUnit enemy, double amount, {bool showHit = true}) {
    if (enemy.dead) return;
    final effective = amount * (1 - enemy.spec.armor);
    enemy.hp -= effective;
    enemy.hitFlash = 1;
    if (showHit) {
      events.add(SimEvent(SimEventType.enemyHit, pos: enemy.pos, color: enemy.spec.color));
    }
    if (enemy.hp <= 0) _killEnemy(enemy);
  }

  void _killEnemy(EnemyUnit enemy) {
    if (enemy.dead) return;
    enemy.dead = true;
    kills++;
    final p = player;

    p.combo += 1;
    p.comboTimer = 3.0;
    maxCombo = math.max(maxCombo, p.combo);
    p.specialCharge = math.min(100, p.specialCharge + (enemy.spec.isElite ? 16 : 6));

    final comboMultiplier = 1 + (p.combo.clamp(0, 40) * 0.05);
    final gained = (enemy.spec.score * config.difficulty.scoreMultiplier * comboMultiplier).round();
    score += gained;

    _dropLoot(enemy);
    shakeEnergy = math.max(shakeEnergy, enemy.spec.isElite ? 14 : 5);
    events.add(SimEvent(
      SimEventType.enemyKilled,
      pos: enemy.pos,
      color: enemy.spec.color,
      value: gained,
      label: enemy.spec.name,
    ));
    if (enemy.spec.isElite) {
      events.add(SimEvent(SimEventType.eliteKilled, pos: enemy.pos, color: enemy.spec.color, label: enemy.spec.name));
    }
    if (p.combo > 0 && p.combo % 10 == 0) {
      events.add(SimEvent(SimEventType.comboMilestone, pos: enemy.pos, value: p.combo));
    }
  }

  void _dropLoot(EnemyUnit enemy) {
    final spec = enemy.spec;
    final coinCount = math.max(1, (spec.coins / 4).round());
    for (var i = 0; i < math.min(4, coinCount); i++) {
      pickups.add(Pickup(
        kind: PickupKind.coin,
        pos: enemy.pos + V2(rng.range(-14, 14), rng.range(-10, 10)),
        value: math.max(2, spec.coins ~/ coinCount),
      ));
    }
    if (rng.chance(spec.gemChance)) {
      pickups.add(Pickup(
        kind: PickupKind.gem,
        pos: enemy.pos + V2(rng.range(-10, 10), 6),
        value: spec.isElite ? 2 : 1,
      ));
    }
    if (rng.chance(spec.powerUpChance)) {
      final kind = rng.pick(PowerUpKind.values);
      pickups.add(Pickup(
        kind: PickupKind.powerUp,
        pos: enemy.pos,
        value: 1,
        powerUp: kind,
        color: kind.color,
      ));
    }
  }

  void _damageBoss(BossUnit b, double amount) {
    if (b.dead) return;
    b.hp -= amount;
    b.hitFlash = 1;
    if (b.hp <= 0) {
      b.dead = true;
      bossKills++;
      score += (b.spec.score * config.difficulty.scoreMultiplier).round();
      coins += b.spec.coins;
      gems += b.spec.gems;
      shakeEnergy = 40;
      events.add(SimEvent(SimEventType.bossDefeated, pos: b.pos, color: b.spec.color, label: b.spec.name));
      for (var i = 0; i < 6; i++) {
        pickups.add(Pickup(
          kind: PickupKind.powerUp,
          pos: b.pos + V2(rng.range(-50, 50), rng.range(-30, 30)),
          value: 1,
          powerUp: rng.pick(PowerUpKind.values),
        ));
      }
      boss = null;
    }
  }

  void _damagePlayer(double amount) {
    final p = player;
    if (!p.isAlive || p.invuln > 0) return;
    if (p.shieldTime > 0) {
      p.shieldTime = math.max(0, p.shieldTime - 1.2);
      p.invuln = 0.25;
      events.add(SimEvent(SimEventType.shieldAbsorb, pos: p.pos));
      return;
    }

    p.health -= amount;
    hitFlash = 1;
    shakeEnergy = 12;
    p.invuln = 0.7;
    p.combo = 0;
    events.add(SimEvent(SimEventType.playerHit, pos: p.pos, value: amount.round()));

    if (p.health > 0) return;

    p.health = 0;
    p.lives -= 1;
    events.add(SimEvent(SimEventType.lifeLost, pos: p.pos));
    if (p.lives > 0) {
      p.health = p.maxHealth;
      p.invuln = 2.6;
      p.pos = V2(_worldWidth / 2, _worldHeight - 130);
      p.reloadTimer = 0;
      p.ammo = config.weaponStats.ammoCapacity;
      enemyBullets.clear();
      dynamicThreat = math.max(0.8, dynamicThreat - 0.08);
      events.add(SimEvent(SimEventType.respawn, pos: p.pos));
    } else {
      phase = RunPhase.failed;
      events.add(SimEvent(SimEventType.playerDied, pos: p.pos));
      _emitResult();
    }
  }

  // -------------------------------------------------------------- wave / level

  void _checkWaveCompletion() {
    if (!waveActive || isFinished) return;
    if (_pendingSpawns.isNotEmpty) return;
    if (enemies.isNotEmpty) return;
    if (boss != null) return;
    if (player.comboTimer > 0) player.comboTimer = math.max(0, player.comboTimer - 0.016);

    waveActive = false;
    wavesCleared++;
    interWaveTimer = 2.2;
    events.add(SimEvent(SimEventType.waveCleared, value: waveIndex + 1));

    // Pace the score so very long endless runs do not overflow the HUD.
    if (wavesCleared >= config.totalWaves) {
      levelCleared = true;
      _finish(RunPhase.levelCleared);
    }
  }

  void _finish(RunPhase result) {
    if (isFinished && phase == result) return;
    phase = result;
    _emitResult();
    if (result == RunPhase.levelCleared) {
      events.add(SimEvent(SimEventType.levelCleared, value: waveIndex + 1));
    } else if (result == RunPhase.timeUp) {
      events.add(SimEvent(SimEventType.timeUp));
    } else {
      events.add(SimEvent(SimEventType.runFailed));
    }
  }

  void _emitResult() {
    if (_resultEmitted) return;
    _resultEmitted = true;
    final p = player;
    final xpEarned = (score / 6).round() + kills * 3 + bossKills * 70;
    finalResult = RunResult(
      mode: config.mode,
      level: config.level,
      score: score,
      coins: coins,
      gems: gems,
      xp: xpEarned,
      kills: kills,
      bossKills: bossKills,
      wavesCleared: wavesCleared,
      powerUps: powerUpsCollected,
      maxCombo: maxCombo,
      accuracy: accuracy,
      durationSeconds: elapsed,
      levelCleared: levelCleared,
      defeated: phase == RunPhase.failed,
      timeUp: phase == RunPhase.timeUp,
    );
  }

  /// Ends the run early (used by the pause menu "abandon run" action).
  void abandon() {
    if (isFinished) return;
    phase = RunPhase.failed;
    _emitResult();
  }

  /// Ticks the combo timer independently of wave completion.
  void tickCombo(double dt) {
    final p = player;
    if (p.comboTimer > 0) {
      p.comboTimer -= dt;
      if (p.comboTimer <= 0) {
        p.comboTimer = 0;
        p.combo = 0;
      }
    }
  }
}
