import 'dart:io';
import 'package:attendance/service/app_config.dart';
import 'package:dio/dio.dart';
import 'package:attendance/model/token.dart';
import 'package:attendance/model/user.dart';

class EmployeeService {
  // Use the same base URL as AuthService for consistency
  static const String baseUrl = AppConfig.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  // Reuse the same token storage class that AuthService uses
  static final TokenStorageService _tokenStorage = TokenStorageService();

  // Single Dio instance for all employee requests
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

  // ------------------- Error Handling -------------------
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

  // ------------------- Helper: get auth token -------------------
  static Future<String> _getAuthHeader() async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please sign in again.');
    }
    return 'Bearer $token';
  }

  // ------------------- Public Methods -------------------

  /// Fetch a single user by ID
  static Future<User> fetchUserById(String id) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/employee/$id',
        options: Options(headers: {'Authorization': authHeader}),
      );

      // Backend returns { "user": { ... } }
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not load user data. (${e.toString()})');
    }
  }

  /// Update a user's profile (with optional image)
  static Future<User> updateUserProfile({
    required String id,
    required String fullName,
    required String telephone,
    File? imageFile,
  }) async {
    try {
      final authHeader = await _getAuthHeader();

      // Build multipart form data
      final formData = FormData.fromMap({
        'fullName': fullName,
        'telephone': telephone,
        if (imageFile != null)
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });

      final response = await _dio.put(
        '/api/public/employee/$id',
        data: formData,
        options: Options(headers: {'Authorization': authHeader}),
      );

      // Backend returns the updated user object directly
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not update profile. (${e.toString()})');
    }
  }

  /// Fetch all users (requires authentication)
  static Future<List<User>> fetchAllUsers() async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/employee/fetchAllUsers',
        options: Options(headers: {'Authorization': authHeader}),
      );

      // Backend returns a list of user objects
      final List<dynamic> data = response.data;
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not load employees. (${e.toString()})');
    }
  }
}

// import 'dart:convert';
// import 'dart:async';
// import 'package:dio/dio.dart';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:attendance/model/user.dart';

// class EmployeeService {
//   static const String baseUrl = 'http://192.168.1.6:3000/api/public/employee';
//   // static const String baseUrl =
//   //     'http://10.118.185.202:3000/api/public/employee';
//   // static const String baseUrl =      'https://ahaz-dashboard.vercel.app/api/public/employee';

//   static Future<User> fetchUserById(String id) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//     if (token == null) {
//       throw Exception('Not authenticated');
//     }

//     // ✅ FIX 1: Change URL to your actual Next.js get-user POST route
//     final response = await http.get(
//       Uri.parse('$baseUrl/$id'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       try {
//         return User.fromJson(data['user']);
//       } catch (e) {
//         throw Exception("Failed to parse user data");
//       }
//     } else {
//       final error = jsonDecode(response.body);
//       throw Exception(error['error'] ?? 'Failed to fetch user');
//     }
//   }

//   static Future<User> updateUserProfile({
//     required String id,
//     required String fullName,
//     required String telephone,
//     File? imageFile,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     // Use MultipartRequest for sending files
//     var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/$id'));

//     request.headers['Authorization'] = 'Bearer $token';

//     // Attach text fields
//     request.fields['fullName'] = fullName;
//     // request.fields['lastName'] = lastName;
//     request.fields['telephone'] = telephone;

//     // Attach image file if one was selected
//     if (imageFile != null) {
//       request.files.add(
//         await http.MultipartFile.fromPath('image', imageFile.path),
//       );
//     }

//     var streamedResponse = await request.send();
//     var response = await http.Response.fromStream(streamedResponse);

//     if (response.statusCode == 200) {
//       // Assuming your User model has a fromJson method
//       return User.fromJson(jsonDecode(response.body));
//     } else {
//       final error = jsonDecode(response.body);
//       throw Exception(error['error'] ?? 'Failed to update profile');
//     }
//   }

//   static Future<List<User>> fetchAllUsers() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     if (token == null) {
//       throw Exception('Not authenticated');
//     }

//     final response = await http.get(
//       Uri.parse('$baseUrl/fetchAllUsers'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );

//     if (response.statusCode == 200) {
//       final List data = jsonDecode(response.body);

//       return data.map((e) => User.fromJson(e)).toList();
//     } else {
//       final error = jsonDecode(response.body);
//       throw Exception(error['error'] ?? 'Failed to fetch users');
//     }
//   }
// }
