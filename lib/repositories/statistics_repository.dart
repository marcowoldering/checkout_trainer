import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checout_trainer/models/checkout_stats.dart';
import 'package:checout_trainer/models/daily_stats.dart';

class StatisticsRepository extends ChangeNotifier {
  static const String _keyTotalPracticed = 'stats_total_practiced';
  static const String _keyTotalCorrect = 'stats_total_correct';
  static const String _keyTotalTimeMs = 'stats_total_time_ms';
  static const String _keyCurrentStreak = 'stats_current_streak';
  static const String _keyBestStreak = 'stats_best_streak';
  static const String _keyCheckoutHistory = 'stats_checkout_history';
  static const String _keyDailyHistory = 'stats_daily_history';

  int _totalPracticed = 0;
  int _totalCorrect = 0;
  int _totalTimeMs = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  Map<int, CheckoutStats> _checkoutHistory = {};
  Map<String, DailyStats> _dailyHistory = {};
  bool _initialized = false;

  int get totalPracticed => _totalPracticed;
  int get totalCorrect => _totalCorrect;
  int get totalTimeMs => _totalTimeMs;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  Map<int, CheckoutStats> get checkoutHistory => Map.unmodifiable(_checkoutHistory);
  Map<String, DailyStats> get dailyHistory => Map.unmodifiable(_dailyHistory);
  bool get initialized => _initialized;

  double get accuracy => _totalPracticed > 0 ? _totalCorrect / _totalPracticed : 0.0;
  double get averageTimeMs => _totalPracticed > 0 ? _totalTimeMs / _totalPracticed : 0.0;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _totalPracticed = prefs.getInt(_keyTotalPracticed) ?? 0;
      _totalCorrect = prefs.getInt(_keyTotalCorrect) ?? 0;
      _totalTimeMs = prefs.getInt(_keyTotalTimeMs) ?? 0;
      _currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
      _bestStreak = prefs.getInt(_keyBestStreak) ?? 0;

      final checkoutJson = prefs.getString(_keyCheckoutHistory);
      if (checkoutJson != null) {
        final decoded = jsonDecode(checkoutJson) as Map<String, dynamic>;
        _checkoutHistory = decoded.map((key, value) => MapEntry(
          int.parse(key),
          CheckoutStats.fromJson(value as Map<String, dynamic>),
        ));
      }

      final dailyJson = prefs.getString(_keyDailyHistory);
      if (dailyJson != null) {
        final decoded = jsonDecode(dailyJson) as Map<String, dynamic>;
        _dailyHistory = decoded.map((key, value) => MapEntry(
          key,
          DailyStats.fromJson(value as Map<String, dynamic>),
        ));
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      _initialized = true;
    }
  }

  Future<void> recordAttempt({
    required int score,
    required bool correct,
    required int timeMs,
    int pointsEarned = 0,
  }) async {
    _totalPracticed++;
    _totalTimeMs += timeMs;

    if (correct) {
      _totalCorrect++;
      _currentStreak++;
      if (_currentStreak > _bestStreak) {
        _bestStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    // Update checkout-specific stats
    if (!_checkoutHistory.containsKey(score)) {
      _checkoutHistory[score] = CheckoutStats(score: score);
    }
    _checkoutHistory[score]!.attempts++;
    _checkoutHistory[score]!.totalTimeMs += timeMs;
    if (correct) {
      _checkoutHistory[score]!.successes++;
    }

    // Update daily stats
    final today = _todayKey;
    if (!_dailyHistory.containsKey(today)) {
      _dailyHistory[today] = DailyStats(date: today);
    }
    _dailyHistory[today]!.practiced++;
    _dailyHistory[today]!.totalTimeMs += timeMs;
    _dailyHistory[today]!.pointsEarned += pointsEarned;
    if (correct) {
      _dailyHistory[today]!.correct++;
    }

    notifyListeners();
    await _saveAll();
  }

  List<MapEntry<int, CheckoutStats>> getMostMissed({int limit = 5}) {
    final sorted = _checkoutHistory.entries
        .where((e) => e.value.attempts >= 3)
        .toList()
      ..sort((a, b) => a.value.successRate.compareTo(b.value.successRate));
    return sorted.take(limit).toList();
  }

  List<DailyStats> getRecentDays({int days = 7}) {
    final result = <DailyStats>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result.add(_dailyHistory[key] ?? DailyStats(date: key));
    }

    return result;
  }

  CheckoutStats? getCheckoutStats(int score) => _checkoutHistory[score];

  double getCheckoutWeight(int score) {
    final stats = _checkoutHistory[score];
    if (stats == null || stats.attempts < 3) return 1.0;

    // Lower success rate = higher weight (appears more often)
    if (stats.successRate < 0.5) return 2.0;
    if (stats.successRate < 0.8) return 1.5;
    return 1.0;
  }

  Set<int> getPracticedCheckouts() => _checkoutHistory.keys.toSet();

  Future<void> _saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotalPracticed, _totalPracticed);
      await prefs.setInt(_keyTotalCorrect, _totalCorrect);
      await prefs.setInt(_keyTotalTimeMs, _totalTimeMs);
      await prefs.setInt(_keyCurrentStreak, _currentStreak);
      await prefs.setInt(_keyBestStreak, _bestStreak);

      final checkoutJson = jsonEncode(_checkoutHistory.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ));
      await prefs.setString(_keyCheckoutHistory, checkoutJson);

      final dailyJson = jsonEncode(_dailyHistory.map(
        (key, value) => MapEntry(key, value.toJson()),
      ));
      await prefs.setString(_keyDailyHistory, dailyJson);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> resetStats() async {
    _totalPracticed = 0;
    _totalCorrect = 0;
    _totalTimeMs = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _checkoutHistory = {};
    _dailyHistory = {};
    notifyListeners();
    await _saveAll();
  }
}
