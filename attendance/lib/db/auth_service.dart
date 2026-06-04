import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://ahaz-dashboard.vercel.app/api/auth';
  static const Duration _timeoutDuration = Duration(seconds: 15);

  // Helper to handle HTTP calls consistently
  static Future<http.Response> _safeHttpCall(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeoutDuration);
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      throw Exception(
        'Request timed out. The server may be busy. Please try again later.',
      );
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      throw Exception(
        'Something went wrong. Please try again later.\n(${e.toString()})',
      );
    }
  }

  // Signup method
  static Future<Map<String, dynamic>> signup(
    String fullName,
    String email,
    String password, [
    String? position,
    bool? gender,
  ]) async {
    final response = await _safeHttpCall(
      () => http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'position': position,
          'gender': gender,
        }),
      ),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Signup failed');
    }
  }

  // Signin method
  static Future<Map<String, dynamic>> signin(
    String email,
    String password,
  ) async {
    final response = await _safeHttpCall(
      () => http.post(
        Uri.parse('$baseUrl/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));
      return data;
    } else {
      final error = jsonDecode(response.body);
      print(error);
      throw Exception(error['error'] ?? 'Signin failed');
    }
  }

  // Logout method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   // static const String baseUrl = 'http://192.168.1.7:3001/api/v1/auth';
//   //static const String baseUrl = 'http://10.118.185.202:3000/api/auth';
//   static const String baseUrl = 'https://ahaz-dashboard.vercel.app/api/auth';

//   // Signup method
//   static Future<Map<String, dynamic>> signup(
//     String firstName,
//     String lastName,
//     String email,
//     String password, [
//     String? position,
//   ]) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/signup'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'firstName': firstName,
//         'lastName': lastName,
//         'email': email,
//         'password': password,
//         'position': position,
//       }),
//     );

//     if (response.statusCode == 201) {
//       return jsonDecode(response.body);
//     } else {
//       final error = jsonDecode(response.body);
//       throw Exception(error['error'] ?? 'Signup failed');
//     }
//   }

//   // Signin method
//   static Future<Map<String, dynamic>> signin(
//     String email,
//     String password,
//   ) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/signin'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'password': password}),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('token', data['token']);
//       await prefs.setString('user', jsonEncode(data['user']));
//       return data;
//     } else {
//       final error = jsonDecode(response.body);
//       print(error);
//       throw Exception(error['error'] ?? 'Signin failed');
//     }
//   }

//   // Logout method
//   static Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     // final token = prefs.getString('token');

//     // if (token != null) {
//     //   await http.post(
//     //     Uri.parse('$baseUrl/logout'),
//     //     headers: {'Authorization': 'Bearer $token'},
//     //   );
//     // }

//     await prefs.remove('token');
//     await prefs.remove('user');
//   }

//   // Get stored token
//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('token');
//   }

//   static Future<Map<String, dynamic>?> getUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     final userJson = prefs.getString('user');
//     if (userJson != null) {
//       return jsonDecode(userJson);
//     }
//     return null;
//   }

//   // Check if user is logged in
//   static Future<bool> isLoggedIn() async {
//     final token = await getToken();
//     return token != null;
//   }
// }
