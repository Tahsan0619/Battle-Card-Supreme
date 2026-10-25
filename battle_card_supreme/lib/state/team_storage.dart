import 'package:shared_preferences/shared_preferences.dart';

const _kTeamKey = 'bcs_squad_ids_v1';

class TeamStorage {
  Future<List<String>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kTeamKey);
  }

  Future<void> save(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kTeamKey, ids);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTeamKey);
  }
}
