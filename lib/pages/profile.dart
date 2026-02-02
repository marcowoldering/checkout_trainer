import 'package:checout_trainer/models/achievement.dart';
import 'package:checout_trainer/models/player_rank.dart';
import 'package:checout_trainer/repositories/gamification_repository.dart';
import 'package:checout_trainer/repositories/statistics_repository.dart';
import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationRepository>().init();
      context.read<StatisticsRepository>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.gradientBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gunmetal),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                        tooltip: 'Go back',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'PROFILE',
                      style: GoogleFonts.chivo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pureWhite,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gunmetal),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: AppColors.pureWhite),
                        tooltip: 'Settings',
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ),
                  ],
                ),
              ),
              // Profile content
              Expanded(
                child: Consumer2<GamificationRepository, StatisticsRepository>(
                  builder: (context, gamification, stats, child) {
                    if (!gamification.initialized || !stats.initialized) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.amberGold),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Rank display
                        _buildRankCard(gamification),
                        const SizedBox(height: 16),

                        // Points and streak row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                label: 'Total Points',
                                value: gamification.totalPoints.toString(),
                                icon: Icons.stars,
                                color: AppColors.amberGold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                label: 'Daily Streak',
                                value: '${gamification.dailyStreak} days',
                                icon: Icons.local_fire_department,
                                color: AppColors.crimsonRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Achievements section
                        _buildAchievementsSection(gamification),
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(GamificationRepository gamification) {
    final rank = gamification.currentRank;
    final nextRank = PlayerRank.getNextRank(rank.index);
    final progress = gamification.progressToNextRank;
    final pointsToNext = gamification.pointsToNextRank;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rank.color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: rank.color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Rank icon and name
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: rank.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rank.color, width: 3),
            ),
            child: Icon(rank.icon, color: rank.color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            rank.name,
            style: GoogleFonts.chivo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: rank.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${gamification.totalPoints} points',
            style: GoogleFonts.chivo(
              fontSize: 16,
              color: AppColors.mutedGrey,
            ),
          ),
          if (nextRank != null) ...[
            const SizedBox(height: 20),
            // Progress bar to next rank
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rank.name,
                      style: GoogleFonts.chivo(
                        fontSize: 12,
                        color: AppColors.mutedGrey,
                      ),
                    ),
                    Text(
                      nextRank.name,
                      style: GoogleFonts.chivo(
                        fontSize: 12,
                        color: AppColors.mutedGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.richBlack,
                    valueColor: AlwaysStoppedAnimation<Color>(rank.color),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pointsToNext points to ${nextRank.name}',
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    color: AppColors.mutedGrey,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: rank.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Maximum Rank Achieved!',
                style: GoogleFonts.chivo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: rank.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gunmetal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.chivo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.chivo(
              fontSize: 12,
              color: AppColors.mutedGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(GamificationRepository gamification) {
    final unlockedCount = gamification.unlockedAchievements.length;
    final totalCount = Achievement.all.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gunmetal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.chivo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
              Text(
                '$unlockedCount / $totalCount',
                style: GoogleFonts.chivo(
                  fontSize: 14,
                  color: AppColors.amberGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: Achievement.all.length,
            itemBuilder: (context, index) {
              final achievement = Achievement.all[index];
              final isUnlocked = gamification.hasAchievement(achievement.id);
              return _buildAchievementBadge(achievement, isUnlocked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(Achievement achievement, bool isUnlocked) {
    return GestureDetector(
      onTap: () => _showAchievementDetails(achievement, isUnlocked),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? achievement.color.withOpacity(0.2)
                  : AppColors.richBlack,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUnlocked
                    ? achievement.color
                    : AppColors.gunmetal,
                width: isUnlocked ? 2 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: achievement.color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked ? achievement.color : AppColors.gunmetal,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.chivo(
              fontSize: 10,
              color: isUnlocked ? AppColors.pureWhite : AppColors.mutedGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.richBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isUnlocked
                ? achievement.color.withOpacity(0.5)
                : AppColors.gunmetal,
            width: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? achievement.color.withOpacity(0.2)
                    : AppColors.charcoal,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnlocked ? achievement.color : AppColors.gunmetal,
                  width: 2,
                ),
              ),
              child: Icon(
                achievement.icon,
                color: isUnlocked ? achievement.color : AppColors.gunmetal,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              style: GoogleFonts.chivo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? achievement.color : AppColors.mutedGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.chivo(
                fontSize: 14,
                color: AppColors.mutedGrey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.emeraldGreen.withOpacity(0.2)
                    : AppColors.charcoal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUnlocked ? 'Unlocked!' : 'Locked',
                style: GoogleFonts.chivo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked ? AppColors.emeraldGreen : AppColors.mutedGrey,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.chivo(color: AppColors.amberGold),
            ),
          ),
        ],
      ),
    );
  }
}
