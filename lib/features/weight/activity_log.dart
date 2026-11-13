import 'activity_type.dart';

class ActivityLog {
  final String id;
  final ActivityType type;
  final Intensity intensity;
  final int durationMin;
  final double kcal;
  final String? note;
  final DateTime date;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.intensity,
    required this.durationMin,
    required this.kcal,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'intensity': intensity.name,
    'durationMin': durationMin,
    'kcal': kcal,
    'note': note,
    'date': date.millisecondsSinceEpoch,
  };

  factory ActivityLog.fromMap(Map<String, dynamic> m) => ActivityLog(
    id: m['id'] as String,
    type: ActivityType.values.byName(m['type'] as String),
    intensity: Intensity.values.byName(m['intensity'] as String),
    durationMin: m['durationMin'] as int,
    kcal: (m['kcal'] as num).toDouble(),
    note: m['note'] as String?,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
  );
}