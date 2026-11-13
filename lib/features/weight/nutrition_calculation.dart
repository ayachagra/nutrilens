import 'goal.dart';
import 'user_profile.dart';

class NutritionTargets {
  final double bmr;
  final double tdee;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String? warning;

  const NutritionTargets({
    required this.bmr,
    required this.tdee,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.warning,
  });
}

class NutritionCalculator {
  static const _kcalPerKg = 7700.0;
  static const _maxDailyAdjust = 750.0;

  /// Formule de Mifflin-St Jeor.
  static double bmr(UserProfile p, double weightKg) {
    final base = 10 * weightKg + 6.25 * p.heightCm - 5 * p.age;
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  static NutritionTargets compute({
    required UserProfile profile,
    required double weightKg,
    required GoalType goalType,
    double? targetWeightKg,
    DateTime? targetDate,
  }) {
    final bmrValue = bmr(profile, weightKg);
    final tdee = bmrValue * profile.activity.factor;

    double adjust = switch (goalType) {
      GoalType.lose => -400,
      GoalType.maintain => 0,
      GoalType.gain => 300,
    };

    String? warning;
    if (goalType != GoalType.maintain &&
        targetWeightKg != null &&
        targetDate != null) {
      final days = targetDate.difference(DateTime.now()).inDays;
      if (days > 0) {
        final needed = (targetWeightKg - weightKg) * _kcalPerKg / days;
        if (needed.abs() > _maxDailyAdjust) {
          warning = 'Votre objectif est très rapide : le rythme a été limité '
              'pour rester raisonnable. Pensez à allonger la durée.';
          adjust = needed.isNegative ? -_maxDailyAdjust : _maxDailyAdjust;
        } else {
          adjust = needed;
        }
      }
    }

    final floor = profile.sex == Sex.male ? 1500.0 : 1200.0;
    var kcal = tdee + adjust;
    if (kcal < floor) {
      kcal = floor;
      warning = 'Les calories ont été relevées au minimum recommandé '
          '(${floor.toStringAsFixed(0)} kcal).';
    }

    final proteinPerKg = goalType == GoalType.maintain ? 1.4 : 1.8;
    final protein = proteinPerKg * weightKg;
    final fat = (kcal * 0.27) / 9;
    final carbs = (kcal - protein * 4 - fat * 9) / 4;

    return NutritionTargets(
      bmr: bmrValue,
      tdee: tdee,
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs < 0 ? 0 : carbs,
      fatG: fat,
      warning: warning,
    );
  }
}