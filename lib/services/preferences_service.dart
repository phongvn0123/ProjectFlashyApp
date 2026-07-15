import 'package:shared_preferences/shared_preferences.dart';

/// Lưu các thiết lập nhỏ dạng key-value trên thiết bị.
///
/// Phù hợp cho theme, cờ onboarding, bộ lọc gần nhất. Không dùng để lưu mật
/// khẩu, Firebase ID token hoặc dữ liệu nghiệp vụ lớn như Quiz/Flashcard.
class PreferencesService {
  const PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  static Future<PreferencesService> create() async {
    return PreferencesService(await SharedPreferences.getInstance());
  }

  String? getString(String key) => _preferences.getString(key);

  bool? getBool(String key) => _preferences.getBool(key);

  int? getInt(String key) => _preferences.getInt(key);

  Future<bool> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  Future<bool> setBool(String key, bool value) {
    return _preferences.setBool(key, value);
  }

  Future<bool> setInt(String key, int value) {
    return _preferences.setInt(key, value);
  }

  Future<bool> remove(String key) => _preferences.remove(key);
}
