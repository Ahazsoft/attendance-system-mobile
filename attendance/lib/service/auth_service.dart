import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:attendance/service/app_config.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/model/token.dart';

class AuthService {
  static const String baseUrl = AppConfig.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  static final TokenStorageService _tokenStorage = TokenStorageService();

  // Create and configure a single reusable Dio instance
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _timeoutDuration,
      receiveTimeout: _timeoutDuration,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Helper to handle Dio network exceptions cleanly
  static Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'Request timed out. The server may be busy. Please try again later.',
      );
    }

    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return Exception(
        'No internet connection. Please check your network and try again.',
      );
    }

    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('error')) {
        return Exception(data['error']);
      }
      return Exception('Server error: ${e.response?.statusCode}');
    }

    return Exception('Something went wrong. Please try again later.');
  }

  // Signup method
  static Future<Map<String, dynamic>> signup(
    String fullName,
    String email,
    String password, [
    String? position,
    bool? gender,
  ]) async {
    try {
      // Dio automatically handles maps into JSON data bodies
      final response = await _dio.post(
        '/api/auth/signup',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'position': position,
          'gender': gender,
        },
      );

      // Dio automatically decodes JSON responses into native Dart Maps
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Something went wrong. Please try again later. (${e.toString()})',
      );
    }
  }

  // Signin method
  static Future<Map<String, dynamic>> signin(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/signin',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;

      // 1. Extract the access token from the modified backend JSON payload
      final accessToken = data['accessToken'];
      if (accessToken != null) {
        // 2. Save it securely inside the encrypted KeyStore/Keychain hardware layer
        await _tokenStorage.saveToken(accessToken);
      } else {
        throw Exception('Token not provided by authentication service.');
      }

      // 3. Keep user profile data in standard shared preferences for quick layout updates
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(data['user']));

      return data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Something went wrong. Please try again later. (${e.toString()})',
      );
    }
  }

  // Logout method
  static Future<void> logout() async {
    // 1. Wipe the security tokens out of the hardware enclave
    await _tokenStorage.clearToken();

    // 2. Clean out the cached user maps from memory
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  // Get stored token
  static Future<String?> getToken() async {
    return await _tokenStorage.getToken();
  }

  // Get stored user profile mapping
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   static const String baseUrl = 'http://192.168.1.11:3000/api/auth';
//   static const Duration _timeoutDuration = Duration(seconds: 15);

//   // Helper to handle HTTP calls consistently
//   static Future<http.Response> _safeHttpCall(
//     Future<http.Response> Function() request,
//   ) async {
//     try {
//       return await request().timeout(_timeoutDuration);
//     } on SocketException {
//       throw Exception(
//         'No internet connection. Please check your network and try again.',
//       );
//     } on TimeoutException {
//       throw Exception(
//         'Request timed out. The server may be busy. Please try again later.',
//       );
//     } on HttpException catch (e) {
//       throw Exception('HTTP error: ${e.message}');
//     } catch (e) {
//       throw Exception(
//         'Something went wrong. Please try again later.\n(${e.toString()})',
//       );
//     }
//   }

//   // Signup method
//   static Future<Map<String, dynamic>> signup(
//     String fullName,
//     String email,
//     String password, [
//     String? position,
//     bool? gender,
//   ]) async {
//     final response = await _safeHttpCall(
//       () => http.post(
//         Uri.parse('$baseUrl/signup'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'fullName': fullName,
//           'email': email,
//           'password': password,
//           'position': position,
//           'gender': gender,
//         }),
//       ),
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
//     final response = await _safeHttpCall(
//       () => http.post(
//         Uri.parse('$baseUrl/signin'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'email': email, 'password': password}),
//       ),
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
