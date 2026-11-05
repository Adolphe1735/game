import 'dart:math' as math;

/// Minimal immutable 2D vector used by the pure-Dart game simulation.
///
/// Kept independent of Flutter/Flame so gameplay logic can be unit tested
/// without a rendering context.
class V2 {
  const V2(this.x, this.y);

  final double x;
  final double y;

  static const V2 zero = V2(0, 0);

  V2 operator +(V2 o) => V2(x + o.x, y + o.y);
  V2 operator -(V2 o) => V2(x - o.x, y - o.y);
  V2 operator *(double s) => V2(x * s, y * s);
  V2 operator /(double s) => V2(x / s, y / s);
  V2 operator -() => V2(-x, -y);

  double get length => math.sqrt(x * x + y * y);
  double get lengthSquared => x * x + y * y;
  double get angle => math.atan2(y, x);

  V2 get normalized {
    final len = length;
    if (len < 1e-9) return zero;
    return V2(x / len, y / len);
  }

  V2 get perpendicular => V2(-y, x);

  V2 rotated(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return V2(x * c - y * s, x * s + y * c);
  }

  V2 withLength(double newLength) => normalized * newLength;

  double distanceTo(V2 other) => (this - other).length;
  double distanceSquaredTo(V2 other) => (this - other).lengthSquared;

  V2 copyWith({double? x, double? y}) => V2(x ?? this.x, y ?? this.y);

  V2 lerpTo(V2 target, double t) => V2(x + (target.x - x) * t, y + (target.y - y) * t);

  @override
  String toString() => 'V2(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';

  @override
  bool operator ==(Object other) =>
      other is V2 && (other.x - x).abs() < 1e-9 && (other.y - y).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(x.round(), y.round());
}

/// Axis-aligned rectangle in world space.
class Rect2 {
  const Rect2(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  V2 get center => V2(left + width / 2, top + height / 2);

  bool contains(V2 p) => p.x >= left && p.x <= right && p.y >= top && p.y <= bottom;

  bool overlapsCircle(V2 c, double radius) {
    final closestX = c.x.clamp(left, right);
    final closestY = c.y.clamp(top, bottom);
    final dx = c.x - closestX;
    final dy = c.y - closestY;
    return dx * dx + dy * dy <= radius * radius;
  }
}

double clampDouble(double value, double min, double max) =>
    value < min ? min : (value > max ? max : value);

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Deterministic pseudo random generator (xorshift32) so waves can be replayed
/// from a seed — used by the daily challenge and gameplay tests.
class Rng {
  Rng(int seed) : _state = seed == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;

  int _state;

  int get seed => _state;

  int nextInt(int max) {
    if (max <= 0) return 0;
    return nextDouble().floor() % max == 0 ? nextDouble() * max ~/ 1 : (nextDouble() * max).floor();
  }

  double nextDouble() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return (_state % 1000000) / 1000000.0;
  }

  double range(double min, double max) => min + nextDouble() * (max - min);

  int rangeInt(int min, int max) => min + (nextDouble() * (max - min + 1)).floor();

  bool chance(double probability) => nextDouble() < probability;

  T pick<T>(List<T> items) => items[nextDouble() * items.length ~/ 1];

  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextDouble() * (i + 1) ~/ 1;
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }
}

/// Frame-rate independent exponential smoothing helper.
double approach(double current, double target, double rate, double dt) {
  final delta = target - current;
  if (delta.abs() < 0.0001) return target;
  return current + delta * (1 - math.exp(-rate * dt));
}

/// Stable hash used for save-data checksums.
int stableHash(String input) {
  var hash = 0x811C9DC5;
  for (var i = 0; i < input.length; i++) {
    hash ^= input.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
