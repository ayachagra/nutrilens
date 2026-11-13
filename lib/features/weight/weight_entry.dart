class WeightEntry {
  final String id;
  final double weightKg;
  final double? waistCm;
  final String? note;
  final DateTime date;

  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.date,
    this.waistCm,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'weightKg': weightKg,
    'waistCm': waistCm,
    'note': note,
    'date': date.millisecondsSinceEpoch,
  };

  factory WeightEntry.fromMap(Map<String, dynamic> m) => WeightEntry(
    id: m['id'] as String,
    weightKg: (m['weightKg'] as num).toDouble(),
    waistCm: (m['waistCm'] as num?)?.toDouble(),
    note: m['note'] as String?,
    date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
  );
}