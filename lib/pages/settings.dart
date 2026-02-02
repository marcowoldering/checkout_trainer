import 'package:checout_trainer/repositories/gamification_repository.dart';
import 'package:checout_trainer/repositories/settings_repository.dart';
import 'package:checout_trainer/repositories/statistics_repository.dart';
import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsRepository>().init();
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
                      'SETTINGS',
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
              // Settings content
              Expanded(
                child: Consumer<SettingsRepository>(
                  builder: (context, settings, child) {
                    if (!settings.initialized) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.amberGold),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSectionHeader('Training'),
                        const SizedBox(height: 12),

                        // Timer Duration
                        _buildSettingCard(
                          title: 'Timer Duration',
                          subtitle: '${settings.timerDuration} seconds',
                          child: _buildTimerSelector(settings),
                        ),
                        const SizedBox(height: 12),

                        // Score Range
                        _buildSettingCard(
                          title: 'Score Range',
                          subtitle: '${settings.minScore} - ${settings.maxScore}',
                          child: _buildScoreRangeSlider(settings),
                        ),
                        const SizedBox(height: 12),

                        // Dart Count Filter
                        _buildSettingCard(
                          title: 'Dart Count',
                          subtitle: _getDartCountLabel(settings.dartCountFilter),
                          child: _buildDartCountSelector(settings),
                        ),
                        const SizedBox(height: 24),

                        _buildSectionHeader('Feedback'),
                        const SizedBox(height: 12),

                        // Haptic Feedback
                        _buildToggleCard(
                          title: 'Haptic Feedback',
                          subtitle: 'Vibrate on interactions',
                          value: settings.hapticEnabled,
                          onChanged: (value) => settings.setHapticEnabled(value),
                        ),
                        const SizedBox(height: 24),

                        _buildSectionHeader('Support'),
                        const SizedBox(height: 12),
                        _buildSupportCard(),
                        const SizedBox(height: 24),

                        _buildSectionHeader('Data'),
                        const SizedBox(height: 12),

                        // Reset All Data
                        _buildResetDataCard(context),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.chivo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.amberGold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.chivo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pureWhite,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.chivo(
                  fontSize: 14,
                  color: AppColors.mutedGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gunmetal),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.chivo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.pureWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.chivo(
                    fontSize: 12,
                    color: AppColors.mutedGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              if (context.read<SettingsRepository>().hapticEnabled) {
                HapticFeedback.lightImpact();
              }
              onChanged(newValue);
            },
            activeColor: AppColors.amberGold,
            activeTrackColor: AppColors.amberGold.withOpacity(0.3),
            inactiveThumbColor: AppColors.mutedGrey,
            inactiveTrackColor: AppColors.richBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSelector(SettingsRepository settings) {
    const options = [15, 30, 45, 60];

    return Row(
      children: options.map((seconds) {
        final isSelected = settings.timerDuration == seconds;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (settings.hapticEnabled) {
                HapticFeedback.lightImpact();
              }
              settings.setTimerDuration(seconds);
            },
            child: Container(
              margin: EdgeInsets.only(
                right: seconds != options.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.amberGold : AppColors.richBlack,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.amberGold : AppColors.gunmetal,
                ),
              ),
              child: Center(
                child: Text(
                  '${seconds}s',
                  style: GoogleFonts.chivo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.richBlack : AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreRangeSlider(SettingsRepository settings) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.amberGold,
        inactiveTrackColor: AppColors.gunmetal,
        thumbColor: AppColors.amberGold,
        overlayColor: AppColors.amberGold.withOpacity(0.2),
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
      ),
      child: RangeSlider(
        values: RangeValues(
          settings.minScore.toDouble(),
          settings.maxScore.toDouble(),
        ),
        min: 2,
        max: 170,
        divisions: 168,
        labels: RangeLabels(
          settings.minScore.toString(),
          settings.maxScore.toString(),
        ),
        onChanged: (values) {
          settings.setScoreRange(values.start.round(), values.end.round());
        },
        onChangeEnd: (values) {
          if (settings.hapticEnabled) {
            HapticFeedback.lightImpact();
          }
        },
      ),
    );
  }

  Widget _buildDartCountSelector(SettingsRepository settings) {
    const options = [
      {'value': 'all', 'label': 'All'},
      {'value': '2-dart', 'label': '2-Dart'},
      {'value': '3-dart', 'label': '3-Dart'},
    ];

    return Row(
      children: options.map((option) {
        final isSelected = settings.dartCountFilter == option['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (settings.hapticEnabled) {
                HapticFeedback.lightImpact();
              }
              settings.setDartCountFilter(option['value']!);
            },
            child: Container(
              margin: EdgeInsets.only(
                right: option != options.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.amberGold : AppColors.richBlack,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.amberGold : AppColors.gunmetal,
                ),
              ),
              child: Center(
                child: Text(
                  option['label']!,
                  style: GoogleFonts.chivo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.richBlack : AppColors.pureWhite,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDartCountLabel(String filter) {
    switch (filter) {
      case '2-dart':
        return '2-Dart Only';
      case '3-dart':
        return '3-Dart Only';
      default:
        return 'All Checkouts';
    }
  }

  Widget _buildResetDataCard(BuildContext context) {
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
            'Reset All Data',
            style: GoogleFonts.chivo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.pureWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clear all statistics, achievements, points, and streaks',
            style: GoogleFonts.chivo(
              fontSize: 12,
              color: AppColors.mutedGrey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showResetConfirmationDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimsonRed,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Reset All Data',
                style: GoogleFonts.chivo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return GestureDetector(
      onTap: () async {
        if (context.read<SettingsRepository>().hapticEnabled) {
          HapticFeedback.lightImpact();
        }
        final url = Uri.parse('https://buymeacoffee.com/marcowoldering');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gunmetal),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amberGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.coffee,
                color: AppColors.amberGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy Me a Coffee',
                    style: GoogleFonts.chivo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Support the development of this app',
                    style: GoogleFonts.chivo(
                      fontSize: 12,
                      color: AppColors.mutedGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.mutedGrey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gunmetal),
        ),
        title: Text(
          'Reset All Data?',
          style: GoogleFonts.chivo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.pureWhite,
          ),
        ),
        content: Text(
          'This will permanently delete all your statistics, checkout history, daily progress, achievements, points, and streaks. This action cannot be undone.',
          style: GoogleFonts.chivo(
            fontSize: 14,
            color: AppColors.mutedGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.chivo(
                color: AppColors.mutedGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final statisticsRepo = context.read<StatisticsRepository>();
              final gamificationRepo = context.read<GamificationRepository>();

              await statisticsRepo.resetStats();
              await gamificationRepo.resetProgress();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All data has been reset',
                      style: GoogleFonts.chivo(),
                    ),
                    backgroundColor: AppColors.charcoal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimsonRed,
              foregroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.chivo(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
