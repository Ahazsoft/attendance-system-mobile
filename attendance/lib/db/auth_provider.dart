import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider {
  static const String _keyUserId = 'userId';
  static const String _keyIsAdmin = 'isAdmin';
  static const String _keyIsApproved = 'isApproved';

  // Store login data
  static Future<void> login(
    String userId,
    bool isAdmin,
    bool isApproved,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyIsAdmin, isAdmin);
    await prefs.setBool(_keyIsApproved, isApproved);
  }

  // Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserId);
  }

  // Retrieve stored user data
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'isAdmin': prefs.getBool(_keyIsAdmin) ?? false,
      'isApproved': prefs.getBool(_keyIsApproved) ?? false,
    };
  }

  // Clear all login data (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyIsAdmin);
    await prefs.remove(_keyIsApproved);
  }
}
