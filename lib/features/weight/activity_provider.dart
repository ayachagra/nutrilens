import 'package:flutter/foundation.dart';
import 'activity_log.dart';
import 'activity_repository.dart';
import 'activity_type.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityRepository _repo;
  ActivityProvider(this._repo) {
    load();
  }

  static const weeklyTarget = 150; // minutes, repère OMS

  DateTime _day = DateTime.now();
  List<ActivityLog> _week = [];
  bool _loading = false;

  DateTime get selectedDay => _day;
  bool get loading => _loading;

  bool get isToday {
    final n = DateTime.now();
    return _day.year == n.year && _day.month == n.month && _day.day == n.day;
  }

  DateTime get _weekStart =>
      DateTime(_day.year, _day.month, _day.day - (_day.weekday - 1));

  List<ActivityLog> get dayItems => _week
      .where((a) =>
  a.date.year == _day.year &&
      a.date.month == _day.month &&
      a.date.day == _day.day)
      .toList();

  int get dayMinutes => dayItems.fold(0, (s, a) => s + a.durationMin);
  double get dayKcal => dayItems.fold(0.0, (s, a) => s + a.kcal);
  int get weekMinutes => _week.fold(0, (s, a) => s + a.durationMin);

  /// Les minutes intenses comptent double (règle OMS).
  int get weekEquivalentMinutes => _week.fold(
      0,
          (s, a) =>
      s + (a.intensity == Intensity.high ? a.durationMin * 2 : a.durationMin));

  int get strengthSessions =>
      _week.where((a) => a.type == ActivityType.strength).length;

  Set<ActivityType> get typesThisWeek => _week.map((a) => a.type).toSet();
  Set<ActivityType> get typesToday => dayItems.map((a) => a.type).toSet();

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final start = _weekStart;
    final end = DateTime(start.year, start.month, start.day + 7);
    _week = await _repo.getRange(start, end);
    _loading = false;
    notifyListeners();
  }

  Future<void> changeDay(DateTime d) async {
    _day = d;
    await load();
  }

  Future<void> add(ActivityLog a) async {
    await _repo.add(a);
    await load();
  }

  Future<void> update(ActivityLog a) async {
    await _repo.update(a);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}