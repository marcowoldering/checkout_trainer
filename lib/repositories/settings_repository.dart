import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository extends ChangeNotifier {
  static const String _keyTimerDuration = 'settings_timer_duration';
  static const String _keyMinScore = 'settings_min_score';
  static const String _keyMaxScore = 'settings_max_score';
  static const String _keyDartCountFilter = 'settings_dart_count_filter';
  static const String _keyHapticEnabled = 'settings_haptic_enabled';
  static const String _keyStrictMode = 'settings_strict_mode';

  int _timerDuration = 30;
  int _minScore = 2;
  int _maxScore = 170;
  String _dartCountFilter = 'all';
  bool _hapticEnabled = true;
  bool _strictMode = false;
  bool _initialized = false;

  int get timerDuration => _timerDuration;
  int get minScore => _minScore;
  int get maxScore => _maxScore;
  String get dartCountFilter => _dartCountFilter;
  bool get hapticEnabled => _hapticEnabled;
  bool get strictMode => _strictMode;
  bool get initialized => _initialized;

  Duration get timerDurationValue => Duration(seconds: _timerDuration);

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _timerDuration = prefs.getInt(_keyTimerDuration) ?? 30;
      _minScore = prefs.getInt(_keyMinScore) ?? 2;
      _maxScore = prefs.getInt(_keyMaxScore) ?? 170;
      _dartCountFilter = prefs.getString(_keyDartCountFilter) ?? 'all';
      _hapticEnabled = prefs.getBool(_keyHapticEnabled) ?? true;
      _strictMode = prefs.getBool(_keyStrictMode) ?? false;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      // Use defaults on error
      _initialized = true;
    }
  }

  Future<void> setTimerDuration(int seconds) async {
    if (![15, 30, 45, 60].contains(seconds)) return;
    _timerDuration = seconds;
    notifyListeners();
    await _save(_keyTimerDuration, seconds);
  }

  Future<void> setScoreRange(int min, int max) async {
    _minScore = min.clamp(2, 170);
    _maxScore = max.clamp(2, 170);
    if (_minScore > _maxScore) {
      _minScore = _maxScore;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinScore, _minScore);
    await prefs.setInt(_keyMaxScore, _maxScore);
  }

  Future<void> setDartCountFilter(String filter) async {
    if (!['all', '2-dart', '3-dart'].contains(filter)) return;
    _dartCountFilter = filter;
    notifyListeners();
    await _save(_keyDartCountFilter, filter);
  }

  Future<void> setHapticEnabled(bool enabled) async {
    _hapticEnabled = enabled;
    notifyListeners();
    await _save(_keyHapticEnabled, enabled);
  }

  Future<void> setStrictMode(bool enabled) async {
    _strictMode = enabled;
    notifyListeners();
    await _save(_keyStrictMode, enabled);
  }

  Future<void> _save(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      }
    } catch (e) {
      // Silently fail
    }
  }
}
