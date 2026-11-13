enum Sex { male, female }

extension SexX on Sex {
  String get label => this == Sex.male ? 'Homme' : 'Femme';
}

enum ActivityLevel { sedentary, light, moderate, high, extreme }

extension ActivityLevelX on ActivityLevel {
  double get factor => switch (this) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.light => 1.375,
    ActivityLevel.moderate => 1.55,
    ActivityLevel.high => 1.725,
    ActivityLevel.extreme => 1.9,
  };

  String get label => switch (this) {
    ActivityLevel.sedentary => 'Sédentaire (peu ou pas de sport)',
    ActivityLevel.light => 'Légèrement actif (1 à 3 séances/sem.)',
    ActivityLevel.moderate => 'Modérément actif (3 à 5 séances/sem.)',
    ActivityLevel.high => 'Très actif (6 à 7 séances/sem.)',
    ActivityLevel.extreme => 'Extrêmement actif (travail physique)',
  };
}

class UserProfile {
  final Sex sex;
  final int age;
  final double heightCm;
  final ActivityLevel activity;

  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.activity,
  });
}