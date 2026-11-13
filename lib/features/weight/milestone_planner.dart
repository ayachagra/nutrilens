import 'goal.dart';
import 'weight_entry.dart';

enum PlanStatus { ahead, onTrack, behind }

class Milestone {
  final int week;
  final DateTime date;
  final double targetKg;
  final double? actualKg;
  final bool isPast;
  final bool reached;

  const Milestone({
    required this.week,
    required this.date,
    required this.targetKg,
    required this.actualKg,
    required this.isPast,
    required this.reached,
  });
}

class PlanResult {
  final DateTime start;
  final List<Milestone> milestones;
  final PlanStatus status;
  final double expectedNowKg;
  final double currentKg;
  final double weeklyRateKg;
  final String? warning;

  const PlanResult({
    required this.start,
    required this.milestones,
    required this.status,
    required this.expectedNowKg,
    required this.currentKg,
    required this.weeklyRateKg,
    this.warning,
  });

  double get deviationKg => currentKg - expectedNowKg;
}

class MilestonePlanner {
  static const _tolerance = 0.3; // kg

  /// [entries] dans n'importe quel ordre. Retourne null si le plan
  /// ne peut pas être construit.
  static PlanResult? build(Goal g, List<WeightEntry> entries,
      {DateTime? now}) {
    if (entries.isEmpty) return null;
    final today = now ?? DateTime.now();

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first.date;
    final start = DateTime(first.year, first.month, first.day);
    final end =
    DateTime(g.targetDate.year, g.targetDate.month, g.targetDate.day);

    final totalDays = end.difference(start).inDays;
    if (totalDays < 1) return null;

    final weeks = (totalDays / 7).ceil().clamp(1, 104);
    final diff = g.targetWeightKg - g.startWeightKg;

    final milestones = <Milestone>[];
    for (var i = 1; i <= weeks; i++) {
      final date = i == weeks ? end : start.add(Duration(days: 7 * i));
      final target = g.startWeightKg + diff * i / weeks;
      final isPast = date.isBefore(today);

      double? actual;
      for (final e in sorted) {
        if (!e.date.isAfter(date.add(const Duration(days: 1)))) {
          actual = e.weightKg;
        }
      }

      final reached = isPast && actual != null && _reached(g.type, actual, target);
      milestones.add(Milestone(
        week: i,
        date: date,
        targetKg: target,
        actualKg: isPast ? actual : null,
        isPast: isPast,
        reached: reached,
      ));
    }

    final fraction =
    (today.difference(start).inDays / totalDays).clamp(0.0, 1.0);
    final expectedNow = g.startWeightKg + diff * fraction;
    final current = sorted.last.weightKg;
    final dev = current - expectedNow;

    final status = switch (g.type) {
      GoalType.lose => dev < -_tolerance
          ? PlanStatus.ahead
          : dev > _tolerance
          ? PlanStatus.behind
          : PlanStatus.onTrack,
      GoalType.gain => dev > _tolerance
          ? PlanStatus.ahead
          : dev < -_tolerance
          ? PlanStatus.behind
          : PlanStatus.onTrack,
      GoalType.maintain => dev.abs() <= 1.0
          ? PlanStatus.onTrack
          : PlanStatus.behind,
    };

    final rate = diff / weeks;
    String? warning;
    if (rate.abs() > g.startWeightKg * 0.01) {
      warning = 'Ce plan demande ${rate.abs().toStringAsFixed(2)} kg par '
          'semaine, ce qui dépasse 1 % du poids corporel. Allonger la durée '
          'serait plus sûr et plus facile à tenir.';
    }

    return PlanResult(
      start: start,
      milestones: milestones,
      status: status,
      expectedNowKg: expectedNow,
      currentKg: current,
      weeklyRateKg: rate,
      warning: warning,
    );
  }

  static bool _reached(GoalType type, double actual, double target) =>
      switch (type) {
        GoalType.lose => actual <= target + _tolerance,
        GoalType.gain => actual >= target - _tolerance,
        GoalType.maintain => (actual - target).abs() <= 1.0,
      };
}