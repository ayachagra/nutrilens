enum GoalType { lose, maintain, gain }

extension GoalTypeLabel on GoalType {
  String get label => switch (this) {
    GoalType.lose => 'Perte de poids',
    GoalType.maintain => 'Maintien',
    GoalType.gain => 'Prise de poids',
  };
}


class Goal {
  final GoalType type;
  final double startWeightKg;
  final double targetWeightKg;
  final DateTime targetDate;

  const Goal({
    required this.type,
    required this.startWeightKg,
    required this.targetWeightKg,
    required this.targetDate,
  });

  Map<String, dynamic> toMap() => {
    'id': 1, // un seul objectif actif
    'type': type.name,
    'startWeightKg': startWeightKg,
    'targetWeightKg': targetWeightKg,
    'targetDate': targetDate.millisecondsSinceEpoch,
  };

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
    type: GoalType.values.byName(m['type'] as String),
    startWeightKg: (m['startWeightKg'] as num).toDouble(),
    targetWeightKg: (m['targetWeightKg'] as num).toDouble(),
    targetDate:
    DateTime.fromMillisecondsSinceEpoch(m['targetDate'] as int),
  );
}