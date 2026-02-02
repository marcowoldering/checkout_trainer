import 'package:checout_trainer/models/daily_stats.dart';
import 'package:checout_trainer/repositories/statistics_repository.dart';
import 'package:checout_trainer/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _chartDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
                      'STATISTICS',
                      style: GoogleFonts.chivo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pureWhite,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // Statistics content
              Expanded(
                child: Consumer<StatisticsRepository>(
                  builder: (context, stats, child) {
                    if (!stats.initialized) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.amberGold),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Stat cards row
                        _buildStatCardsRow(stats),
                        const SizedBox(height: 24),

                        // Progress chart
                        _buildProgressChart(stats),
                        const SizedBox(height: 24),

                        // Most missed checkouts
                        _buildMostMissedSection(stats),
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

  Widget _buildStatCardsRow(StatisticsRepository stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total',
                value: stats.totalPracticed.toString(),
                icon: Icons.sports,
                color: AppColors.amberGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Accuracy',
                value: '${(stats.accuracy * 100).toStringAsFixed(1)}%',
                icon: Icons.gps_fixed,
                color: AppColors.emeraldGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Avg Time',
                value: _formatTime(stats.averageTimeMs),
                icon: Icons.timer,
                color: AppColors.crimsonRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Best Streak',
                value: stats.bestStreak.toString(),
                icon: Icons.local_fire_department,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.chivo(
              fontSize: 24,
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

  Widget _buildProgressChart(StatisticsRepository stats) {
    final recentDays = stats.getRecentDays(days: _chartDays);

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
                'Progress',
                style: GoogleFonts.chivo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
              _buildChartDaysSelector(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildChart(recentDays),
          ),
        ],
      ),
    );
  }

  Widget _buildChartDaysSelector() {
    return Row(
      children: [7, 30].map((days) {
        final isSelected = _chartDays == days;
        return GestureDetector(
          onTap: () {
            setState(() {
              _chartDays = days;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.amberGold : AppColors.richBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.amberGold : AppColors.gunmetal,
              ),
            ),
            child: Text(
              '${days}D',
              style: GoogleFonts.chivo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.richBlack : AppColors.mutedGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(List<DailyStats> recentDays) {
    if (recentDays.every((d) => d.practiced == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, color: AppColors.mutedGrey, size: 48),
            const SizedBox(height: 12),
            Text(
              'No data yet',
              style: GoogleFonts.chivo(
                color: AppColors.mutedGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start practicing to see your progress',
              style: GoogleFonts.chivo(
                color: AppColors.mutedGrey.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final maxPracticed = recentDays.map((d) => d.practiced).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxPracticed * 1.2).ceilToDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.richBlack,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = recentDays[group.x.toInt()];
              return BarTooltipItem(
                '${day.practiced} practiced\n${day.correct} correct',
                GoogleFonts.chivo(
                  color: AppColors.pureWhite,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= recentDays.length) {
                  return const SizedBox.shrink();
                }
                // For 30-day view, only show every 5th label
                if (_chartDays == 30 && index % 5 != 0) {
                  return const SizedBox.shrink();
                }
                final date = recentDays[index].date;
                final parts = date.split('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${parts[2]}/${parts[1]}',
                    style: GoogleFonts.chivo(
                      color: AppColors.mutedGrey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.chivo(
                    color: AppColors.mutedGrey,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxPracticed > 0 ? (maxPracticed / 4).ceilToDouble() : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.gunmetal,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: recentDays.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: day.practiced.toDouble(),
                color: AppColors.amberGold,
                width: _chartDays == 7 ? 20 : 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxPracticed * 1.2,
                  color: AppColors.richBlack,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMostMissedSection(StatisticsRepository stats) {
    final mostMissed = stats.getMostMissed(limit: 5);

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
          Text(
            'Most Missed Checkouts',
            style: GoogleFonts.chivo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: 16),
          if (mostMissed.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.emeraldGreen, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No struggling checkouts yet',
                      style: GoogleFonts.chivo(
                        color: AppColors.mutedGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...mostMissed.map((entry) {
              final checkout = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.crimsonRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.crimsonRed.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${checkout.score}',
                          style: GoogleFonts.chivo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.crimsonRed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(checkout.successRate * 100).toStringAsFixed(0)}% success rate',
                            style: GoogleFonts.chivo(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.pureWhite,
                            ),
                          ),
                          Text(
                            '${checkout.successes}/${checkout.attempts} correct',
                            style: GoogleFonts.chivo(
                              fontSize: 12,
                              color: AppColors.mutedGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMasteryColor(checkout.masteryLevel).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getMasteryColor(checkout.masteryLevel).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        checkout.masteryLevel,
                        style: GoogleFonts.chivo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getMasteryColor(checkout.masteryLevel),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getMasteryColor(String level) {
    switch (level) {
      case 'Mastered':
        return AppColors.emeraldGreen;
      case 'Learning':
        return AppColors.amberGold;
      case 'Struggling':
        return AppColors.crimsonRed;
      default:
        return AppColors.mutedGrey;
    }
  }

  String _formatTime(double ms) {
    if (ms == 0) return '0s';
    final seconds = ms / 1000;
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)}s';
    }
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).round();
    return '${minutes}m ${remainingSeconds}s';
  }
}
