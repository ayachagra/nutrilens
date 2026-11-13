import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _loading = true;

  ProfileProvider() {
    load();
  }

  UserProfile? get profile => _profile;
  bool get loading => _loading;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final sex = prefs.getString('p_sex');
    if (sex != null) {
      _profile = UserProfile(
        sex: Sex.values.byName(sex),
        age: prefs.getInt('p_age') ?? 30,
        heightCm: prefs.getDouble('p_height') ?? 170,
        activity: ActivityLevel.values
            .byName(prefs.getString('p_activity') ?? 'light'),
      );
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> save(UserProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('p_sex', p.sex.name);
    await prefs.setInt('p_age', p.age);
    await prefs.setDouble('p_height', p.heightCm);
    await prefs.setString('p_activity', p.activity.name);
    _profile = p;
    notifyListeners();
  }
}