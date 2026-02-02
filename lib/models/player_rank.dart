import 'package:flutter/material.dart';

class PlayerRank {
  final int index;
  final String name;
  final int minPoints;
  final IconData icon;
  final Color color;

  const PlayerRank({
    required this.index,
    required this.name,
    required this.minPoints,
    required this.icon,
    required this.color,
  });

  static const List<PlayerRank> ranks = [
    PlayerRank(
      index: 0,
      name: 'Pub Player',
      minPoints: 0,
      icon: Icons.local_bar,
      color: Color(0xFF6B7280), // Grey
    ),
    PlayerRank(
      index: 1,
      name: 'Club Player',
      minPoints: 500,
      icon: Icons.sports_bar,
      color: Color(0xFF10B981), // Emerald
    ),
    PlayerRank(
      index: 2,
      name: 'County',
      minPoints: 2000,
      icon: Icons.emoji_events,
      color: Color(0xFF3B82F6), // Blue
    ),
    PlayerRank(
      index: 3,
      name: 'Pro',
      minPoints: 5000,
      icon: Icons.military_tech,
      color: Color(0xFF8B5CF6), // Purple
    ),
    PlayerRank(
      index: 4,
      name: 'World Champion',
      minPoints: 15000,
      icon: Icons.workspace_premium,
      color: Color(0xFFF59E0B), // Gold
    ),
  ];

  static PlayerRank getRankForPoints(int points) {
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (points >= ranks[i].minPoints) {
        return ranks[i];
      }
    }
    return ranks[0];
  }

  static PlayerRank? getNextRank(int currentIndex) {
    if (currentIndex < ranks.length - 1) {
      return ranks[currentIndex + 1];
    }
    return null;
  }

  static int pointsToNextRank(int currentPoints) {
    final currentRank = getRankForPoints(currentPoints);
    final nextRank = getNextRank(currentRank.index);
    if (nextRank != null) {
      return nextRank.minPoints - currentPoints;
    }
    return 0;
  }

  static double progressToNextRank(int currentPoints) {
    final currentRank = getRankForPoints(currentPoints);
    final nextRank = getNextRank(currentRank.index);
    if (nextRank != null) {
      final pointsInCurrentRank = currentPoints - currentRank.minPoints;
      final pointsNeeded = nextRank.minPoints - currentRank.minPoints;
      return pointsInCurrentRank / pointsNeeded;
    }
    return 1.0;
  }
}
