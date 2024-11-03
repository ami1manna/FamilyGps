import 'package:shared_preferences/shared_preferences.dart';

class LocationServiceRepository {
  static const String _userIdKey = 'user_id';
  static const String _lastLatKey = 'last_lat';
  static const String _lastLongKey = 'last_long';

  /// Save user ID to local storage.
  static Future<void> saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// Retrieve the saved user ID.
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Save last known location to local storage.
  static Future<void> saveLastLocation(double lat, double long) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastLatKey, lat);
    await prefs.setDouble(_lastLongKey, long);
  }

  /// Retrieve last known location from local storage.
  static Future<Map<String, double?>> getLastLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble(_lastLatKey);
    double? long = prefs.getDouble(_lastLongKey);
    return {'lat': lat, 'long': long};
  }

  /// Clear user data from local storage.
  static Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_lastLatKey);
    await prefs.remove(_lastLongKey);
  }
}