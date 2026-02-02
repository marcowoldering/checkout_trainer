import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<Achievement> all = [
    Achievement(
      id: 'first_checkout',
      name: 'First Blood',
      description: 'Complete your first checkout',
      icon: Icons.looks_one,
      color: Color(0xFF10B981),
    ),
    Achievement(
      id: 'streak_10',
      name: 'On Fire',
      description: 'Get 10 correct in a row',
      icon: Icons.local_fire_department,
      color: Color(0xFFEF4444),
    ),
    Achievement(
      id: 'streak_25',
      name: 'Unstoppable',
      description: 'Get 25 correct in a row',
      icon: Icons.bolt,
      color: Color(0xFFF59E0B),
    ),
    Achievement(
      id: 'daily_7',
      name: 'Weekly Warrior',
      description: 'Practice 7 consecutive days',
      icon: Icons.calendar_month,
      color: Color(0xFF3B82F6),
    ),
    Achievement(
      id: 'daily_30',
      name: 'Monthly Master',
      description: 'Practice 30 consecutive days',
      icon: Icons.event_available,
      color: Color(0xFF8B5CF6),
    ),
    Achievement(
      id: 'accuracy_90',
      name: 'Sharp Shooter',
      description: '90% accuracy (min 50 attempts)',
      icon: Icons.gps_fixed,
      color: Color(0xFF10B981),
    ),
    Achievement(
      id: 'master_170',
      name: 'Big Fish',
      description: 'Master 170 checkout (80%+ on 10+ attempts)',
      icon: Icons.emoji_events,
      color: Color(0xFFF59E0B),
    ),
    Achievement(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Answer correctly in under 3 seconds',
      icon: Icons.speed,
      color: Color(0xFFEF4444),
    ),
    Achievement(
      id: 'century',
      name: 'Century',
      description: '100 total correct checkouts',
      icon: Icons.emoji_events_outlined,
      color: Color(0xFF3B82F6),
    ),
    Achievement(
      id: 'half_millennium',
      name: 'Half Millennium',
      description: '500 total correct checkouts',
      icon: Icons.star,
      color: Color(0xFF8B5CF6),
    ),
    Achievement(
      id: 'all_checkouts',
      name: 'Completionist',
      description: 'Practice every checkout at least once',
      icon: Icons.done_all,
      color: Color(0xFFF59E0B),
    ),
    Achievement(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Practice after midnight',
      icon: Icons.nightlight,
      color: Color(0xFF6366F1),
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
