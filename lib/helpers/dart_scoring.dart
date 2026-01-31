class DartScoring {
  static final _modifierRegex = RegExp(r'[DTdt]');

  static int calculateScore(List<String> darts) {
    return darts.fold(0, (sum, dart) {
      final trimmed = dart.trim();
      if (trimmed.isEmpty) return sum;

      final upper = trimmed.toUpperCase();
      if (upper == 'BULL') return sum + 50;
      if (upper == '25') return sum + 25;

      final numberPart = upper.replaceAll(_modifierRegex, '');
      final value = int.tryParse(numberPart);
      if (value == null) return sum;

      final multiplier = upper.startsWith('D') ? 2 : upper.startsWith('T') ? 3 : 1;
      return sum + value * multiplier;
    });
  }
}
