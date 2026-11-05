import '../../core/l10n/strings.dart';
import 'enemy_spec.dart';

/// All player-facing options (features 158–175). Values are clamped on load so
/// corrupted save data can never break the UI.
class GameSettings {
  GameSettings({
    this.musicVolume = 0.55,
    this.sfxVolume = 0.85,
    this.screenShake = 1.0,
    this.reducedEffects = false,
    this.colorBlindSafe = false,
    this.buttonScale = 1.0,
    this.sensitivity = 1.0,
    this.language = 'en',
    this.difficultyId = 'pilot',
    this.leftHanded = false,
    this.showHints = true,
    this.pauseOnBlur = true,
    this.autoFire = true,
    this.performanceMode = false,
    this.fullscreen = false,
  });

  double musicVolume;
  double sfxVolume;

  /// 0 = off, 1 = normal, 1.6 = strong (feature 169).
  double screenShake;
  bool reducedEffects;
  bool colorBlindSafe;
  double buttonScale;
  double sensitivity;
  String language;
  String difficultyId;
  bool leftHanded;
  bool showHints;
  bool pauseOnBlur;
  bool autoFire;
  bool performanceMode;
  bool fullscreen;

  Difficulty get difficulty => Difficulty.byId(difficultyId);
  AppStrings get strings => AppStrings.of(language);

  /// Effective screen shake multiplier after accessibility settings.
  double get shakeFactor => reducedEffects ? 0.0 : screenShake;

  /// Particle budget multiplier for performance mode (feature 189/190).
  double get particleScale => reducedEffects ? 0.25 : (performanceMode ? 0.5 : 1.0);

  GameSettings copy() => GameSettings(
        musicVolume: musicVolume,
        sfxVolume: sfxVolume,
        screenShake: screenShake,
        reducedEffects: reducedEffects,
        colorBlindSafe: colorBlindSafe,
        buttonScale: buttonScale,
        sensitivity: sensitivity,
        language: language,
        difficultyId: difficultyId,
        leftHanded: leftHanded,
        showHints: showHints,
        pauseOnBlur: pauseOnBlur,
        autoFire: autoFire,
        performanceMode: performanceMode,
        fullscreen: fullscreen,
      );

  Map<String, dynamic> toJson() => {
        'music': musicVolume,
        'sfx': sfxVolume,
        'shake': screenShake,
        'reduced': reducedEffects,
        'colorBlind': colorBlindSafe,
        'buttonScale': buttonScale,
        'sensitivity': sensitivity,
        'language': language,
        'difficulty': difficultyId,
        'leftHanded': leftHanded,
        'hints': showHints,
        'pauseOnBlur': pauseOnBlur,
        'autoFire': autoFire,
        'perf': performanceMode,
        'fullscreen': fullscreen,
      };

  factory GameSettings.fromJson(Map<String, dynamic>? json) {
    final s = GameSettings();
    if (json == null) return s;
    double num_(String key, double fallback) {
      final raw = json[key];
      if (raw is num) return raw.toDouble();
      return fallback;
    }

    bool flag(String key, bool fallback) => json[key] is bool ? json[key] as bool : fallback;
    final lang = json['language'];
    final diff = json['difficulty'];

    s.musicVolume = num_('music', s.musicVolume).clamp(0.0, 1.0);
    s.sfxVolume = num_('sfx', s.sfxVolume).clamp(0.0, 1.0);
    s.screenShake = num_('shake', s.screenShake).clamp(0.0, 2.0);
    s.buttonScale = num_('buttonScale', s.buttonScale).clamp(0.8, 1.4);
    s.sensitivity = num_('sensitivity', s.sensitivity).clamp(0.4, 2.0);
    s.reducedEffects = flag('reduced', s.reducedEffects);
    s.colorBlindSafe = flag('colorBlind', s.colorBlindSafe);
    s.leftHanded = flag('leftHanded', s.leftHanded);
    s.showHints = flag('hints', s.showHints);
    s.pauseOnBlur = flag('pauseOnBlur', s.pauseOnBlur);
    s.autoFire = flag('autoFire', s.autoFire);
    s.performanceMode = flag('perf', s.performanceMode);
    s.fullscreen = flag('fullscreen', s.fullscreen);
    if (lang is String && AppStrings.languageNames.containsKey(lang)) s.language = lang;
    if (diff is String && Difficulty.all.any((d) => d.id == diff)) s.difficultyId = diff;
    return s;
  }
}
