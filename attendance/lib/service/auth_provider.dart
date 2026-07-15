import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider {
  static const String _keyUserId = 'userId';
  static const String _keyIsAdmin = 'isAdmin';
  static const String _keyIsApproved = 'isApproved';
  static const String _keyToken = 'authToken';
  static const String _keyTokenExpiry =
      'tokenExpiry'; // milliseconds since epoch

  /// Login: receives the JWT and user metadata
  static Future<void> login({
    required String userId,
    required bool isAdmin,
    required bool isApproved,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Decode the JWT to get its expiration time
    final int? expiryMs = _extractExpiry(token);
    if (expiryMs == null) {
      throw Exception('Invalid token: cannot extract expiration');
    }

    // Store all data
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyIsAdmin, isAdmin);
    await prefs.setBool(_keyIsApproved, isApproved);
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyTokenExpiry, expiryMs);
  }

  /// Check if user is logged in AND token is not expired
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyUserId) || !prefs.containsKey(_keyTokenExpiry)) {
      return false;
    }

    final expiry = prefs.getInt(_keyTokenExpiry) ?? 0;
    print("Expiry Date : $expiry");
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= expiry) {
      await logout(); // Clear everything if token expired
      return false;
    }
    return true;
  }

  /// Retrieve stored user data
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_keyUserId),
      'isAdmin': prefs.getBool(_keyIsAdmin) ?? false,
      'isApproved': prefs.getBool(_keyIsApproved) ?? false,
    };
  }

  /// Get the stored token (for API calls)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Only return token if it’s still valid
    if (await isLoggedIn()) {
      return prefs.getString(_keyToken);
    }
    return null;
  }

  /// Clear all stored data (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyIsAdmin);
    await prefs.remove(_keyIsApproved);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyTokenExpiry);
  }

  /// Helper: decode JWT payload and return 'exp' as milliseconds
  static int? _extractExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64url decode the payload (part 1)
      String payload = parts[1];
      // Normalize base64url to base64
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      // Add padding if needed
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          return null;
      }
      final decodedBytes = base64.decode(payload);
      final jsonPayload = json.decode(utf8.decode(decodedBytes));
      if (jsonPayload is Map && jsonPayload.containsKey('exp')) {
        final expSeconds = jsonPayload['exp'];
        if (expSeconds is int) {
          return expSeconds * 1000; // convert to milliseconds
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

// import 'package:shared_preferences/shared_preferences.dart';

// class AuthProvider {
//   static const String _keyUserId = 'userId';
//   static const String _keyIsAdmin = 'isAdmin';
//   static const String _keyIsApproved = 'isApproved';

//   // Store login data
//   static Future<void> login(
//     String userId,
//     bool isAdmin,
//     bool isApproved,
//   ) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_keyUserId, userId);
//     await prefs.setBool(_keyIsAdmin, isAdmin);
//     await prefs.setBool(_keyIsApproved, isApproved);
//   }

//   // Check if user is already logged in
//   static Future<bool> isLoggedIn() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.containsKey(_keyUserId);
//   }

//   // Retrieve stored user data
//   static Future<Map<String, dynamic>> getUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     return {
//       'userId': prefs.getString(_keyUserId),
//       'isAdmin': prefs.getBool(_keyIsAdmin) ?? false,
//       'isApproved': prefs.getBool(_keyIsApproved) ?? false,
//     };
//   }

//   // Clear all login data (logout)
//   static Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_keyUserId);
//     await prefs.remove(_keyIsAdmin);
//     await prefs.remove(_keyIsApproved);
//   }
// }
