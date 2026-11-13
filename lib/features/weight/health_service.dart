import 'package:health/health.dart';
import 'weight_entry.dart';

class HealthService {
  final Health _health = Health();

  static const _types = [HealthDataType.WEIGHT, HealthDataType.STEPS];
  static const _perms = [HealthDataAccess.READ, HealthDataAccess.READ];

  Future<bool> authorize() async {
    await _health.configure();
    return await _health.requestAuthorization(_types, permissions: _perms);
  }

  /// Poids des [days] derniers jours. L'id `hc_<uuid>` évite les doublons
  /// (addEntry remplace en cas d'id identique).
  Future<List<WeightEntry>> importWeights({int days = 90}) async {
    final now = DateTime.now();
    final points = await _health.getHealthDataFromTypes(
      types: [HealthDataType.WEIGHT],
      startTime: now.subtract(Duration(days: days)),
      endTime: now,
    );

    final result = <WeightEntry>[];
    for (final p in _health.removeDuplicates(points)) {
      final value = p.value;
      if (value is! NumericHealthValue) continue;
      final kg = value.numericValue.toDouble();
      if (kg < 20 || kg > 500) continue;
      final uid = p.uuid.isNotEmpty
          ? p.uuid
          : p.dateFrom.millisecondsSinceEpoch.toString();
      result.add(WeightEntry(id: 'hc_$uid', weightKg: kg, date: p.dateFrom));
    }
    return result;
  }

  Future<int?> stepsToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return _health.getTotalStepsInInterval(midnight, now);
  }
}