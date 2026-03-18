import 'dart:math' as math;

import 'package:checout_trainer/helpers/dart_scoring.dart';
import 'package:checout_trainer/helpers/darts_checkouts.dart';
import 'package:checout_trainer/models/achievement.dart';
import 'package:checout_trainer/repositories/custom_checkout_repository.dart';
import 'package:checout_trainer/repositories/settings_repository.dart';
import 'package:checout_trainer/repositories/statistics_repository.dart';
import 'package:checout_trainer/repositories/gamification_repository.dart';
import 'package:checout_trainer/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TrainerPage extends StatefulWidget {
  const TrainerPage({Key? key}) : super(key: key);

  @override
  State<TrainerPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<TrainerPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<int> numbers = List.generate(20, (index) => index + 1);
  late AnimationController _timerController;
  Duration _timerDuration = const Duration(seconds: 30);
  DateTime? _startTime;

  CustomCheckoutRepository get _repository => context.read<CustomCheckoutRepository>();
  SettingsRepository get _settings => context.read<SettingsRepository>();
  StatisticsRepository get _statistics => context.read<StatisticsRepository>();
  GamificationRepository get _gamification => context.read<GamificationRepository>();

  int score = 0;
  List<String> solution = [];
  List<String> inputs = [];
  String modifier = "Single";
  int? _pointsEarned;
  bool _showPointsAnimation = false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: _timerDuration,
    );
    _timerController.addStatusListener(_onTimerStatusChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initRepositories();
      _loadCheckouts();
      _timerController.forward();
    });
  }

  Future<void> _initRepositories() async {
    await _settings.init();
    await _statistics.init();
    await _gamification.init();

    // Update timer duration from settings
    _timerDuration = _settings.timerDurationValue;
    _timerController.duration = _timerDuration;
  }

  void _onTimerStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _showTimeUpDialog();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_timerController.value < 1.0) {
        _timerController.forward();
      }
    } else if (state == AppLifecycleState.inactive) {
      _timerController.stop();
    } else if (state == AppLifecycleState.detached) {
      _timerController.stop();
    }
  }

  Future<void> _loadCheckouts() async {
    await _repository.initCheckouts();
    generateRandomCheckout();
  }

  int _calculateInputSum() {
    return DartScoring.calculateScore(inputs);
  }

  bool _canFinishWithDouble(int remaining) {
    return remaining == 50 || (remaining >= 2 && remaining <= 40 && remaining.isEven);
  }

  Map<int, List<String>> _getFilteredCheckouts() {
    final combined = {...DartCheckouts.checkouts, ..._repository.checkouts};
    final minScore = _settings.minScore;
    final maxScore = _settings.maxScore;
    final dartFilter = _settings.dartCountFilter;

    return Map.fromEntries(
      combined.entries.where((entry) {
        // Filter by score range
        if (entry.key < minScore || entry.key > maxScore) return false;

        // Filter by dart count
        if (dartFilter == '2-dart' && entry.value.length != 2) return false;
        if (dartFilter == '3-dart' && entry.value.length != 3) return false;

        return true;
      }),
    );
  }

  void generateRandomCheckout() async {
    final filteredCheckouts = _getFilteredCheckouts();

    if (filteredCheckouts.isEmpty) {
      // Fallback to all checkouts if filter is too restrictive
      final randomCheckout = DartCheckouts.getRandomCheckout(_repository.checkouts);
      setState(() {
        score = randomCheckout.key;
        solution = randomCheckout.value;
        inputs.clear();
        modifier = _canFinishWithDouble(randomCheckout.key) ? 'Double' : 'Single';
      });
      _startTime = DateTime.now();
      return;
    }

    // Weighted selection based on success rate
    final entries = filteredCheckouts.entries.toList();
    final weights = entries.map((e) => _statistics.getCheckoutWeight(e.key)).toList();
    final totalWeight = weights.reduce((a, b) => a + b);

    final random = math.Random();
    var randomValue = random.nextDouble() * totalWeight;

    MapEntry<int, List<String>>? selectedEntry;
    for (int i = 0; i < entries.length; i++) {
      randomValue -= weights[i];
      if (randomValue <= 0) {
        selectedEntry = entries[i];
        break;
      }
    }

    selectedEntry ??= entries[random.nextInt(entries.length)];

    setState(() {
      score = selectedEntry!.key;
      solution = selectedEntry.value;
      inputs.clear();
      modifier = _canFinishWithDouble(selectedEntry.key) ? 'Double' : 'Single';
    });
    _startTime = DateTime.now();
  }

  void addInput(String value) {
    if (inputs.length < 3) {
      if (_settings.hapticEnabled) {
        HapticFeedback.lightImpact();
      }
      setState(() {
        inputs.add(value);

        final remaining = score - _calculateInputSum();
        final bool isLastDart = inputs.length == solution.length - 1;
        if (isLastDart && _canFinishWithDouble(remaining)) {
          modifier = 'Double';
        }
      });
    }
  }

  void undoInput() {
    if (inputs.isNotEmpty) {
      if (_settings.hapticEnabled) {
        HapticFeedback.lightImpact();
      }
      setState(() {
        inputs.removeLast();
        final remaining = score - _calculateInputSum();
        final bool isLastDart = inputs.length == solution.length - 1;
        modifier = (isLastDart && _canFinishWithDouble(remaining)) ? 'Double' : 'Single';
      });
    }
  }

  int _getElapsedTimeMs() {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inMilliseconds;
  }

  int _getRemainingTimeMs() {
    final elapsed = _getElapsedTimeMs();
    final total = _timerDuration.inMilliseconds;
    return (total - elapsed).clamp(0, total);
  }

  Future<void> _recordAttempt(bool correct) async {
    final timeMs = _getElapsedTimeMs();
    int points = 0;

    if (correct) {
      points = await _gamification.awardPoints(
        score: score,
        remainingTimeMs: _getRemainingTimeMs(),
        maxTimeMs: _timerDuration.inMilliseconds,
      );
    }

    await _statistics.recordAttempt(
      score: score,
      correct: correct,
      timeMs: timeMs,
      pointsEarned: points,
    );

    if (correct) {
      await _gamification.checkAchievements(
        totalCorrect: _statistics.totalCorrect,
        totalPracticed: _statistics.totalPracticed,
        currentStreak: _statistics.currentStreak,
        timeMs: timeMs,
        score: score,
        checkoutHistory: _statistics.checkoutHistory,
      );

      // Check for new achievements to show
      final newAchievements = _gamification.popPendingAchievements();
      if (newAchievements.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAchievementUnlocked(newAchievements.first);
        });
      }
    }

    if (correct && points > 0) {
      setState(() {
        _pointsEarned = points;
        _showPointsAnimation = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showPointsAnimation = false;
          });
        }
      });
    }
  }

  void _showAchievementUnlocked(Achievement achievement) {
    if (_settings.hapticEnabled) {
      HapticFeedback.heavyImpact();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.richBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: achievement.color.withOpacity(0.5), width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ACHIEVEMENT UNLOCKED!',
              style: GoogleFonts.chivo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.amberGold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: achievement.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: achievement.color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: achievement.color.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                achievement.icon,
                color: achievement.color,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              style: GoogleFonts.chivo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: achievement.color,
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
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.crimsonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Text(
                    'Awesome!',
                    style: GoogleFonts.chivo(
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void submit() {
    _timerController.stop();
    bool arraysMatch(List<String> a, List<String> b) => a.join(', ') == b.join(', ');

    void showResultDialog(String title, IconData icon, Color iconColor, Widget content, String buttonLabel, VoidCallback onPressed) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.richBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: iconColor.withOpacity(0.5), width: 2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.chivo(
                  fontWeight: FontWeight.bold,
                  color: AppColors.pureWhite,
                ),
              ),
            ],
          ),
          content: content,
          actions: [
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.crimsonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Text(
                      buttonLabel,
                      style: GoogleFonts.chivo(
                        fontWeight: FontWeight.w600,
                        color: AppColors.pureWhite,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final int total = DartScoring.calculateScore(inputs);
    final int solutionTotal = DartScoring.calculateScore(solution);

    // Get the recommended checkout (custom checkout takes priority over default)
    final recommendedCheckout = _repository.checkouts[score] ?? DartCheckouts.checkouts[score];
    final bool matchesRecommended = recommendedCheckout != null &&
        inputs.join(', ') == recommendedCheckout.join(', ');

    // In strict mode, only accept exact match with recommended checkout
    final bool isCorrect = _settings.strictMode
        ? matchesRecommended
        : total == solutionTotal;

    if (isCorrect) {
      _recordAttempt(true);
      if (_settings.hapticEnabled) {
        HapticFeedback.heavyImpact();
      }

      final bool exactMatch = arraysMatch(inputs, solution);
      showResultDialog(
        "Correct!",
        Icons.check_circle,
        AppColors.emeraldGreen,
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You matched the checkout!",
              style: TextStyle(color: AppColors.pureWhite),
            ),
            if (!exactMatch) ...[
              const SizedBox(height: 12),
              const Text(
                "Recommended sequence:",
                style: TextStyle(color: AppColors.mutedGrey),
              ),
              const SizedBox(height: 4),
              Text(
                solution.join(' | '),
                style: GoogleFonts.chivo(
                  fontWeight: FontWeight.bold,
                  color: AppColors.amberGold,
                ),
              ),
            ],
            if (_pointsEarned != null && _pointsEarned! > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.stars, color: AppColors.amberGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+$_pointsEarned points',
                    style: GoogleFonts.chivo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.amberGold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        "Next",
        () {
          modifier = 'Single';
          Navigator.of(context).pop();
          generateRandomCheckout();
          _timerController.reset();
          _timerController.forward();
        },
      );
      return;
    }

    // Incorrect answer
    _recordAttempt(false);
    if (_settings.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    // Determine the appropriate error message
    // In strict mode, if score matches but checkout doesn't, don't reveal the answer
    final bool scoreMatches = total == solutionTotal;
    final Widget incorrectContent = _settings.strictMode && scoreMatches
        ? const Text(
            "Your checkout is valid, but doesn't match the recommended sequence.",
            style: TextStyle(color: AppColors.pureWhite),
          )
        : Text(
            "You scored $total but needed $solutionTotal.",
            style: const TextStyle(color: AppColors.pureWhite),
          );

    showResultDialog(
      "Incorrect!",
      Icons.cancel,
      AppColors.crimsonRed,
      incorrectContent,
      "Try Again",
      () {
        Navigator.of(context).pop();
        _timerController.forward();
      },
    );
  }

  void _showTimeUpDialog() {
    _recordAttempt(false);
    if (_settings.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.richBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.crimsonRed.withOpacity(0.5), width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.crimsonRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.timer_off, color: AppColors.crimsonRed, size: 28),
            ),
            const SizedBox(width: 12),
            Text(
              "Time's Up!",
              style: GoogleFonts.chivo(
                fontWeight: FontWeight.bold,
                color: AppColors.pureWhite,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You ran out of time!",
              style: TextStyle(color: AppColors.pureWhite),
            ),
            const SizedBox(height: 12),
            const Text(
              "The correct sequence was:",
              style: TextStyle(color: AppColors.mutedGrey),
            ),
            const SizedBox(height: 4),
            Text(
              solution.join(' | '),
              style: GoogleFonts.chivo(
                fontWeight: FontWeight.bold,
                color: AppColors.amberGold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.crimsonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  generateRandomCheckout();
                  _timerController.reset();
                  _timerController.forward();
                },
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Text(
                    "Next",
                    style: GoogleFonts.chivo(
                      fontWeight: FontWeight.w600,
                      color: AppColors.pureWhite,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getChipBorderColor(String input) {
    if (input.startsWith('D') || input == 'Bull') {
      return AppColors.crimsonRed;
    } else if (input.startsWith('T')) {
      return AppColors.emeraldGreen;
    }
    return AppColors.gunmetal;
  }

  String _getMasteryLevel() {
    final stats = _statistics.getCheckoutStats(score);
    return stats?.masteryLevel ?? 'New';
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

  @override
  Widget build(BuildContext context) {
    final masteryLevel = _getMasteryLevel();
    final masteryColor = _getMasteryColor(masteryLevel);

    return Scaffold(
      body: Container(
        decoration: AppDecorations.gradientBackground,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Score Display with circular timer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Back button on the left
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
                        // Timer in the center (Expanded + Center)
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: 180,
                              height: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background track
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 6,
                                      color: AppColors.charcoal,
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  // Animated timer ring
                                  AnimatedBuilder(
                                    animation: _timerController,
                                    builder: (context, child) {
                                      return SizedBox(
                                        width: 180,
                                        height: 180,
                                        child: CustomPaint(
                                          painter: _CircularTimerPainter(
                                            progress: 1.0 - _timerController.value,
                                            color: AppColors.amberGold,
                                            strokeWidth: 6,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Checkout score display
                                  Container(
                                    width: 168,
                                    height: 168,
                                    decoration: const BoxDecoration(
                                      color: AppColors.richBlack,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "CHECKOUT",
                                            style: GoogleFonts.chivo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mutedGrey,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                          Text(
                                            "$score",
                                            style: GoogleFonts.chivo(
                                              fontSize: 48,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.amberGold,
                                            ),
                                          ),
                                          // Mastery badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: masteryColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: masteryColor.withOpacity(0.5),
                                              ),
                                            ),
                                            child: Text(
                                              masteryLevel,
                                              style: GoogleFonts.chivo(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: masteryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Streak indicator on the right
                        Container(
                          width: 48,
                          decoration: BoxDecoration(
                            color: AppColors.charcoal,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gunmetal),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: _statistics.currentStreak > 0
                                    ? AppColors.crimsonRed
                                    : AppColors.mutedGrey,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_statistics.currentStreak}',
                                style: GoogleFonts.chivo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _statistics.currentStreak > 0
                                      ? AppColors.pureWhite
                                      : AppColors.mutedGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Input chips with color-coded borders
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: inputs.isEmpty
                        ? Center(
                            child: Text(
                              "Enter your checkout...",
                              style: GoogleFonts.chivo(color: AppColors.mutedGrey),
                            ),
                          )
                        : Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: inputs.map((input) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.charcoal,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getChipBorderColor(input),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getChipBorderColor(input).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          input,
                                          style: GoogleFonts.chivo(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.pureWhite,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),
                  // Dark keyboard with rounded top corners
                  Expanded(
                    child: Container(
                    decoration: AppDecorations.keyboardContainer,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      child: Column(
                        children: [
                          // Segmented modifier selector (S/D/T)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.richBlack,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: ['Single', 'Double', 'Treble'].map((mod) {
                                final remaining = score - _calculateInputSum();
                                final bool isLastDart = inputs.length == solution.length - 1;
                                final bool isDisabled = (mod != 'Double' && isLastDart && _canFinishWithDouble(remaining));
                                final bool isSelected = modifier == mod && !isDisabled;

                                Color getModifierColor(String mod) {
                                  if (mod == 'Double') return AppColors.crimsonRed;
                                  if (mod == 'Treble') return AppColors.emeraldGreen;
                                  return AppColors.gunmetal;
                                }

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: isDisabled
                                        ? null
                                        : () {
                                            if (_settings.hapticEnabled) {
                                              HapticFeedback.lightImpact();
                                            }
                                            setState(() {
                                              modifier = mod;
                                            });
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? getModifierColor(mod) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          mod[0], // S, D, or T
                                          style: GoogleFonts.chivo(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDisabled
                                                ? AppColors.mutedGrey.withOpacity(0.5)
                                                : isSelected
                                                    ? AppColors.pureWhite
                                                    : AppColors.mutedGrey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Number grid
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth < 320 ? 4 : 5;
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                  childAspectRatio: 1.1,
                                ),
                                itemCount: numbers.length,
                                itemBuilder: (context, index) {
                                  final number = numbers[index];
                                  final int value = modifier == 'Single'
                                      ? number
                                      : modifier == 'Double'
                                          ? number * 2
                                          : number * 3;
                                  final String multiplierText =
                                      modifier == 'Single' ? '' : '($value)';

                                  final bool isDisabled = inputs.length >= 3;

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: isDisabled
                                          ? null
                                          : () {
                                              final prefix = modifier == 'Single'
                                                  ? ''
                                                  : modifier == 'Double'
                                                      ? 'D'
                                                      : 'T';
                                              addInput('$prefix$number');
                                            },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDisabled
                                              ? AppColors.richBlack.withOpacity(0.5)
                                              : AppColors.richBlack,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDisabled
                                                ? AppColors.gunmetal.withOpacity(0.5)
                                                : AppColors.gunmetal,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$number',
                                              style: GoogleFonts.chivo(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDisabled
                                                    ? AppColors.mutedGrey.withOpacity(0.5)
                                                    : AppColors.pureWhite,
                                              ),
                                            ),
                                            if (multiplierText.isNotEmpty)
                                              Text(
                                                multiplierText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDisabled
                                                      ? AppColors.mutedGrey.withOpacity(0.3)
                                                      : AppColors.mutedGrey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          // Bull, Outer, Undo buttons
                          Row(
                            children: [
                              // Bull button with outlined style
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: inputs.length < 3
                                        ? AppColors.charcoal
                                        : AppColors.richBlack.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: inputs.length < 3
                                          ? AppColors.amberGold
                                          : AppColors.gunmetal,
                                      width: 2,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: inputs.length < 3
                                          ? () => addInput("Bull")
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Text(
                                          "Bull (50)",
                                          style: GoogleFonts.chivo(
                                            fontWeight: FontWeight.bold,
                                            color: inputs.length < 3
                                                ? AppColors.pureWhite
                                                : AppColors.mutedGrey.withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Outer button
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: !_canFinishWithDouble(score - _calculateInputSum()) &&
                                            inputs.length < 3
                                        ? AppColors.richBlack
                                        : AppColors.richBlack.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.gunmetal),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: !_canFinishWithDouble(score - _calculateInputSum()) &&
                                              inputs.length < 3
                                          ? () => addInput("25")
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Text(
                                          "Outer (25)",
                                          style: GoogleFonts.chivo(
                                            fontWeight: FontWeight.bold,
                                            color: !_canFinishWithDouble(score - _calculateInputSum()) &&
                                                    inputs.length < 3
                                                ? AppColors.pureWhite
                                                : AppColors.mutedGrey.withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Undo button
                              Container(
                                height: 50,
                                width: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.richBlack,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gunmetal),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: undoInput,
                                    borderRadius: BorderRadius.circular(12),
                                    child: const Center(
                                      child: Icon(Icons.undo, color: AppColors.pureWhite),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Submit button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: inputs.isEmpty ? null : AppColors.crimsonGradient,
                              color: inputs.isEmpty ? AppColors.charcoal : null,
                              borderRadius: BorderRadius.circular(14),
                              border: inputs.isEmpty ? Border.all(color: AppColors.gunmetal) : null,
                              boxShadow: inputs.isEmpty
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.crimsonRed.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: inputs.isEmpty ? null : submit,
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: Text(
                                    "Submit",
                                    style: GoogleFonts.chivo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: inputs.isEmpty ? AppColors.mutedGrey : AppColors.pureWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
              // Points animation overlay
              if (_showPointsAnimation && _pointsEarned != null)
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value > 0.8 ? (1.0 - (value - 0.8) * 5) : 1.0,
                          child: Transform.translate(
                            offset: Offset(0, -30 * value),
                            child: Transform.scale(
                              scale: 0.5 + (value * 0.5),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.amberGold,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amberGold.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stars, color: AppColors.richBlack, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+$_pointsEarned',
                                      style: GoogleFonts.chivo(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.richBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc starting from top (-90 degrees) going clockwise
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
