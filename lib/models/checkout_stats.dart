class CheckoutStats {
  final int score;
  int attempts;
  int successes;
  int totalTimeMs;

  CheckoutStats({
    required this.score,
    this.attempts = 0,
    this.successes = 0,
    this.totalTimeMs = 0,
  });

  double get successRate => attempts > 0 ? successes / attempts : 0.0;

  double get averageTimeMs => attempts > 0 ? totalTimeMs / attempts : 0.0;

  String get masteryLevel {
    if (attempts == 0) return 'New';
    if (successRate >= 0.8) return 'Mastered';
    if (successRate >= 0.5) return 'Learning';
    return 'Struggling';
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'attempts': attempts,
    'successes': successes,
    'totalTimeMs': totalTimeMs,
  };

  factory CheckoutStats.fromJson(Map<String, dynamic> json) => CheckoutStats(
    score: json['score'] as int,
    attempts: json['attempts'] as int? ?? 0,
    successes: json['successes'] as int? ?? 0,
    totalTimeMs: json['totalTimeMs'] as int? ?? 0,
  );
}
