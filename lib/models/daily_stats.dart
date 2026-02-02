class DailyStats {
  final String date; // Format: YYYY-MM-DD
  int practiced;
  int correct;
  int totalTimeMs;
  int pointsEarned;

  DailyStats({
    required this.date,
    this.practiced = 0,
    this.correct = 0,
    this.totalTimeMs = 0,
    this.pointsEarned = 0,
  });

  double get accuracy => practiced > 0 ? correct / practiced : 0.0;

  Map<String, dynamic> toJson() => {
    'date': date,
    'practiced': practiced,
    'correct': correct,
    'totalTimeMs': totalTimeMs,
    'pointsEarned': pointsEarned,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    date: json['date'] as String,
    practiced: json['practiced'] as int? ?? 0,
    correct: json['correct'] as int? ?? 0,
    totalTimeMs: json['totalTimeMs'] as int? ?? 0,
    pointsEarned: json['pointsEarned'] as int? ?? 0,
  );
}
