import 'package:shared_preferences/shared_preferences.dart';

class WorkingCopyUriPreferences {
  static const String key = 'working_copy_uri';
  static const String initialSetupDoneKey = 'working_copy_initial_setup_done';

  Future<String?> loadUri() async {
    final preferences = await SharedPreferences.getInstance();
    final uri = preferences.getString(key);
    if (uri == null) {
      return null;
    }
    final normalized = uri.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<void> saveUri(String uri) async {
    final normalized = uri.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Die URI darf nicht leer sein.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, normalized);
  }

  Future<void> clearUri() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  Future<bool> isInitialSetupDone() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(initialSetupDoneKey) ?? false;
  }

  Future<void> markInitialSetupDone() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(initialSetupDoneKey, true);
  }
}
