import 'package:flutter/foundation.dart';
import 'goal.dart';
import 'weight_entry.dart';
import 'weight_repository.dart';

class WeightProvider extends ChangeNotifier {
  final WeightRepository _repo;
  WeightProvider(this._repo) {
    load();
  }

  List<WeightEntry> _entries = [];
  Goal? _goal;
  bool _loading = false;

  List<WeightEntry> get entries => _entries;
  Goal? get goal => _goal;
  bool get loading => _loading;

  WeightEntry? get latest => _entries.isEmpty ? null : _entries.first;

  /// Progression vers l'objectif entre 0 et 1.
  double? get progress {
    final g = _goal;
    final cur = latest?.weightKg;
    if (g == null || cur == null) return null;
    final total = g.startWeightKg - g.targetWeightKg;
    if (total == 0) return 1;
    return ((g.startWeightKg - cur) / total).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _entries = await _repo.getAllEntries();
    _goal = await _repo.getGoal();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(WeightEntry e) async {
    await _repo.addEntry(e);
    await load();
  }

  Future<void> update(WeightEntry e) async {
    await _repo.updateEntry(e);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.deleteEntry(id);
    await load();
  }

  Future<void> saveGoal(Goal g) async {
    await _repo.saveGoal(g);
    await load();
  }
  Future<int> importEntries(List<WeightEntry> list) async {
    for (final e in list) {
      await _repo.addEntry(e);
    }
    await load();
    return list.length;
  }
}