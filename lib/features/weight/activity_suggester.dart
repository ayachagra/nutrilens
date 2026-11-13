import '../weight/goal.dart';
import 'activity_type.dart';

class Suggestion {
  final ActivityType type;
  final Intensity intensity;
  final int minutes;
  final String reason;
  const Suggestion(this.type, this.intensity, this.minutes, this.reason);
}

class ActivitySuggester {
  static const weeklyTarget = 150;

  static List<Suggestion> suggest({
    GoalType? goal,
    required int weekEqMinutes,
    required int todayMinutes,
    required Set<ActivityType> doneThisWeek,
    required Set<ActivityType> doneToday,
    required int strengthSessions,
  }) {
    // Déjà beaucoup de mouvement aujourd'hui : on ne propose rien de plus.
    if (todayMinutes >= 90) return [];

    final remaining = (weeklyTarget - weekEqMinutes).clamp(0, weeklyTarget);
    final base = remaining > 0
        ? 'Il vous reste $remaining min pour atteindre les $weeklyTarget min '
        'hebdomadaires.'
        : 'Objectif hebdomadaire atteint : faites-vous plaisir.';

    final out = <Suggestion>[];

    if (strengthSessions < 2 && !doneToday.contains(ActivityType.strength)) {
      out.add(Suggestion(
        ActivityType.strength,
        Intensity.moderate,
        40,
        'Le renforcement musculaire est recommandé 2 fois par semaine '
            '($strengthSessions cette semaine).',
      ));
    }

    final pool = switch (goal) {
      GoalType.lose => const [
        (ActivityType.walking, Intensity.moderate, 40),
        (ActivityType.cycling, Intensity.moderate, 40),
        (ActivityType.swimming, Intensity.moderate, 30),
        (ActivityType.running, Intensity.moderate, 30),
        (ActivityType.hiit, Intensity.moderate, 20),
      ],
      GoalType.gain => const [
        (ActivityType.strength, Intensity.moderate, 45),
        (ActivityType.swimming, Intensity.moderate, 30),
        (ActivityType.walking, Intensity.moderate, 30),
        (ActivityType.cycling, Intensity.low, 30),
      ],
      _ => const [
        (ActivityType.walking, Intensity.moderate, 30),
        (ActivityType.cycling, Intensity.moderate, 40),
        (ActivityType.yoga, Intensity.low, 30),
        (ActivityType.swimming, Intensity.moderate, 30),
        (ActivityType.running, Intensity.moderate, 30),
      ],
    };

    // On privilégie les activités pas encore faites cette semaine.
    final fresh = pool.where((e) => !doneThisWeek.contains(e.$1));
    final repeated = pool.where((e) => doneThisWeek.contains(e.$1));

    for (final e in [...fresh, ...repeated]) {
      if (out.length >= 3) break;
      if (doneToday.contains(e.$1)) continue;
      if (out.any((s) => s.type == e.$1)) continue;
      final isNew = !doneThisWeek.contains(e.$1);
      out.add(Suggestion(
        e.$1,
        e.$2,
        e.$3,
        isNew ? 'Pas encore pratiqué cette semaine. $base' : base,
      ));
    }
    return out;
  }
}