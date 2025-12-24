class SpectrumSummary {
  final List<double> dominantFrequencies;
  final double chaosLevel;
  final double density;

  SpectrumSummary({
    required this.dominantFrequencies,
    required this.chaosLevel,
    required this.density,
  });

  @override
  String toString() {
    return 'SpectrumSummary(dominantFrequencies: $dominantFrequencies, chaosLevel: $chaosLevel, density: $density)';
  }
}
