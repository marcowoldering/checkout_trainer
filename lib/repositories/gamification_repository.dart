import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checout_trainer/models/player_rank.dart';
import 'package:checout_trainer/models/achievement.dart';
import 'package:checout_trainer/models/checkout_stats.dart';
import 'package:checout_trainer/helpers/darts_checkouts.dart';

class GamificationRepository extends ChangeNotifier {
  static const String _keyTotalPoints = 'game_total_points';
  static const String _keyDailyStreak = 'game_daily_streak';
  static const String _keyLastPracticeDate = 'game_last_practice_date';
  static const String _keyUnlockedAchievements = 'game_unlocked_achievements';

  int _totalPoints = 0;
  int _dailyStreak = 0;
  String _lastPracticeDate = '';
  Set<String> _unlockedAchievements = {};
  bool _initialized = false;

  // Pending achievements to show in UI
  final List<Achievement> _pendingAchievementNotifications = [];

  int get totalPoints => _totalPoints;
  int get dailyStreak => _dailyStreak;
  Set<String> get unlockedAchievements => Set.unmodifiable(_unlockedAchievements);
  bool get initialized => _initialized;
  PlayerRank get currentRank => PlayerRank.getRankForPoints(_totalPoints);
  double get progressToNextRank => PlayerRank.progressToNextRank(_totalPoints);
  int get pointsToNextRank => PlayerRank.pointsToNextRank(_totalPoints);

  List<Achievement> popPendingAchievements() {
    final achievements = List<Achievement>.from(_pendingAchievementNotifications);
    _pendingAchievementNotifications.clear();
    return achievements;
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _totalPoints = prefs.getInt(_keyTotalPoints) ?? 0;
      _dailyStreak = prefs.getInt(_keyDailyStreak) ?? 0;
      _lastPracticeDate = prefs.getString(_keyLastPracticeDate) ?? '';

      final achievementsJson = prefs.getString(_keyUnlockedAchievements);
      if (achievementsJson != null) {
        _unlockedAchievements = Set<String>.from(jsonDecode(achievementsJson));
      }

      // Check daily streak validity
      _checkDailyStreak();

      _initialized = true;
      notifyListeners();
    } catch (e) {
      _initialized = true;
    }
  }

  void _checkDailyStreak() {
    if (_lastPracticeDate.isEmpty) return;

    final today = DateTime.now();
    final parts = _lastPracticeDate.split('-');
    if (parts.length != 3) return;

    final lastDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final difference = today.difference(lastDate).inDays;
    if (difference > 1) {
      // More than 1 day gap, reset streak
      _dailyStreak = 0;
    }
  }

  int calculatePoints({
    required int score,
    required int remainingTimeMs,
    required int maxTimeMs,
  }) {
    const basePoints = 10;

    // Time bonus: 0-10 extra points based on remaining time
    final timeBonus = (basePoints * (remainingTimeMs / maxTimeMs)).round();

    // Difficulty multiplier: 1.0x to 2.0x based on score
    final difficultyMultiplier = 1.0 + (score - 40) / 130;
    final clampedMultiplier = difficultyMultiplier.clamp(1.0, 2.0);

    return ((basePoints + timeBonus) * clampedMultiplier).round();
  }

  Future<int> awardPoints({
    required int score,
    required int remainingTimeMs,
    required int maxTimeMs,
  }) async {
    final points = calculatePoints(
      score: score,
      remainingTimeMs: remainingTimeMs,
      maxTimeMs: maxTimeMs,
    );

    final oldRank = currentRank;
    _totalPoints += points;
    final newRank = currentRank;

    // Update daily streak
    final today = _todayKey;
    if (_lastPracticeDate != today) {
      if (_lastPracticeDate.isNotEmpty) {
        final parts = _lastPracticeDate.split('-');
        if (parts.length == 3) {
          final lastDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          final todayDate = DateTime.now();
          final difference = todayDate.difference(lastDate).inDays;
          if (difference == 1) {
            _dailyStreak++;
          } else if (difference > 1) {
            _dailyStreak = 1;
          }
        }
      } else {
        _dailyStreak = 1;
      }
      _lastPracticeDate = today;
    }

    notifyListeners();
    await _saveAll();

    // Check for rank up notification (handled separately in UI)
    if (newRank.index > oldRank.index) {
      // Could trigger rank up celebration
    }

    return points;
  }

  Future<void> checkAchievements({
    required int totalCorrect,
    required int totalPracticed,
    required int currentStreak,
    required int timeMs,
    required int score,
    required Map<int, CheckoutStats> checkoutHistory,
  }) async {
    final newlyUnlocked = <String>[];

    // First Blood - Complete 1 checkout
    if (totalCorrect >= 1 && !_unlockedAchievements.contains('first_checkout')) {
      newlyUnlocked.add('first_checkout');
    }

    // On Fire - 10 correct in a row
    if (currentStreak >= 10 && !_unlockedAchievements.contains('streak_10')) {
      newlyUnlocked.add('streak_10');
    }

    // Unstoppable - 25 correct in a row
    if (currentStreak >= 25 && !_unlockedAchievements.contains('streak_25')) {
      newlyUnlocked.add('streak_25');
    }

    // Weekly Warrior - 7 consecutive days
    if (_dailyStreak >= 7 && !_unlockedAchievements.contains('daily_7')) {
      newlyUnlocked.add('daily_7');
    }

    // Monthly Master - 30 consecutive days
    if (_dailyStreak >= 30 && !_unlockedAchievements.contains('daily_30')) {
      newlyUnlocked.add('daily_30');
    }

    // Sharp Shooter - 90% accuracy (min 50 attempts)
    if (totalPracticed >= 50) {
      final accuracy = totalCorrect / totalPracticed;
      if (accuracy >= 0.9 && !_unlockedAchievements.contains('accuracy_90')) {
        newlyUnlocked.add('accuracy_90');
      }
    }

    // Big Fish - Master 170 checkout (80%+ on 10+ attempts)
    final stats170 = checkoutHistory[170];
    if (stats170 != null &&
        stats170.attempts >= 10 &&
        stats170.successRate >= 0.8 &&
        !_unlockedAchievements.contains('master_170')) {
      newlyUnlocked.add('master_170');
    }

    // Speed Demon - Answer in under 3 seconds
    if (timeMs < 3000 && !_unlockedAchievements.contains('speed_demon')) {
      newlyUnlocked.add('speed_demon');
    }

    // Century - 100 total correct
    if (totalCorrect >= 100 && !_unlockedAchievements.contains('century')) {
      newlyUnlocked.add('century');
    }

    // Half Millennium - 500 total correct
    if (totalCorrect >= 500 && !_unlockedAchievements.contains('half_millennium')) {
      newlyUnlocked.add('half_millennium');
    }

    // Completionist - Practice every checkout at least once
    final allScores = DartCheckouts.checkouts.keys.toSet();
    final practicedScores = checkoutHistory.keys.toSet();
    if (practicedScores.containsAll(allScores) && !_unlockedAchievements.contains('all_checkouts')) {
      newlyUnlocked.add('all_checkouts');
    }

    // Night Owl - Practice after midnight
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 5 && !_unlockedAchievements.contains('night_owl')) {
      newlyUnlocked.add('night_owl');
    }

    if (newlyUnlocked.isNotEmpty) {
      _unlockedAchievements.addAll(newlyUnlocked);

      // Queue achievements for UI notification
      for (final id in newlyUnlocked) {
        final achievement = Achievement.getById(id);
        if (achievement != null) {
          _pendingAchievementNotifications.add(achievement);
        }
      }

      notifyListeners();
      await _saveAll();
    }
  }

  bool hasAchievement(String id) => _unlockedAchievements.contains(id);

  Future<void> _saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotalPoints, _totalPoints);
      await prefs.setInt(_keyDailyStreak, _dailyStreak);
      await prefs.setString(_keyLastPracticeDate, _lastPracticeDate);
      await prefs.setString(_keyUnlockedAchievements, jsonEncode(_unlockedAchievements.toList()));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> resetProgress() async {
    _totalPoints = 0;
    _dailyStreak = 0;
    _lastPracticeDate = '';
    _unlockedAchievements = {};
    notifyListeners();
    await _saveAll();
  }
}
