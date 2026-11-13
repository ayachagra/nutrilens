import 'package:flutter/material.dart';

enum Intensity { low, moderate, high }

extension IntensityX on Intensity {
  String get label => switch (this) {
    Intensity.low => 'Légère',
    Intensity.moderate => 'Modérée',
    Intensity.high => 'Intense',
  };
}

enum ActivityType {
  walking,
  running,
  cycling,
  swimming,
  strength,
  yoga,
  hiit,
  football,
  other
}

extension ActivityTypeX on ActivityType {
  String get label => switch (this) {
    ActivityType.walking => 'Marche',
    ActivityType.running => 'Course',
    ActivityType.cycling => 'Vélo',
    ActivityType.swimming => 'Natation',
    ActivityType.strength => 'Musculation',
    ActivityType.yoga => 'Yoga',
    ActivityType.hiit => 'HIIT',
    ActivityType.football => 'Football',
    ActivityType.other => 'Autre',
  };

  IconData get icon => switch (this) {
    ActivityType.walking => Icons.directions_walk,
    ActivityType.running => Icons.directions_run,
    ActivityType.cycling => Icons.directions_bike,
    ActivityType.swimming => Icons.pool,
    ActivityType.strength => Icons.fitness_center,
    ActivityType.yoga => Icons.self_improvement,
    ActivityType.hiit => Icons.bolt,
    ActivityType.football => Icons.sports_soccer,
    ActivityType.other => Icons.sports,
  };

  /// MET approximatifs (légère, modérée, intense).
  double met(Intensity i) {
    final v = switch (this) {
      ActivityType.walking => [2.8, 3.5, 5.0],
      ActivityType.running => [7.0, 9.8, 11.8],
      ActivityType.cycling => [4.0, 6.8, 10.0],
      ActivityType.swimming => [4.5, 5.8, 9.8],
      ActivityType.strength => [3.0, 4.5, 6.0],
      ActivityType.yoga => [2.0, 2.8, 4.0],
      ActivityType.hiit => [6.0, 8.0, 10.0],
      ActivityType.football => [5.0, 7.0, 9.0],
      ActivityType.other => [3.0, 4.5, 6.5],
    };
    return v[i.index];
  }
}

/// Calories = MET x poids (kg) x durée (heures).
double estimateKcal({
  required ActivityType type,
  required Intensity intensity,
  required int minutes,
  required double weightKg,
}) =>
    type.met(intensity) * weightKg * minutes / 60;