import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider {
  static const String _keyUserId = 'userId';
  static const String _keyIsAdmin = 'isAdmin';
  static const String _keyIsApproved = 'isApproved';
  static const String _keyToken = 'authToken';
  static const String _keyTokenExpiry = 'tokenExpiry';

  static Future<void> login({
    required String userId,
    required bool isAdmin,
    required bool isApproved,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final expiryMs = expiryDate.millisecondsSinceEpoch;

      await prefs.setString(_keyUserId, userId);
      await prefs.setBool(_keyIsAdmin, isAdmin);
      await prefs.setBool(_keyIsApproved, isApproved);
      await prefs.setString(_keyToken, token);
      await prefs.setInt(_keyTokenExpiry, expiryMs);
    } catch (e) {
      throw Exception('Invalid token: cannot extract expiration');
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyUserId) || !prefs.containsKey(_keyTokenExpiry)) {
      return false;
    }
    final expiry = prefs.getInt(_keyTokenExpiry) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= expiry) {
      await logout();
      return false;
    }
    return true;
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'isAdmin': prefs.getBool(_keyIsAdmin) ?? false,
      'isApproved': prefs.getBool(_keyIsApproved) ?? false,
    };
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (await isLoggedIn()) {
      return prefs.getString(_keyToken);
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyIsAdmin);
    await prefs.remove(_keyIsApproved);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyTokenExpiry);
  }
}
