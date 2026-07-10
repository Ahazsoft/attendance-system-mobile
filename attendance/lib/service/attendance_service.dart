import 'dart:async';
import 'dart:io';
import 'package:attendance/service/app_config.dart';
import 'package:dio/dio.dart';
import 'package:attendance/model/token.dart';

class AttendanceService {
  // Same base URL as AuthService for consistency
  static const String baseUrl = AppConfig.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  static final TokenStorageService _tokenStorage = TokenStorageService();

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

  /// Employee check‑in (requires authentication)
  static Future<Map<String, dynamic>> checkIn({
    required String employeeId,
    required String secret,
    required bool isBssid,
  }) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.post(
        '/api/public/attendance/checkin',
        data: {'employeeId': employeeId, 'secret': secret, 'isBssid': isBssid},
        options: Options(headers: {'Authorization': authHeader}),
      );

      // Backend returns { ... } (check‑in record)
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Check‑in failed. (${e.toString()})');
    }
  }

  /// Get a single attendance record by ID
  static Future<Map<String, dynamic>> getAttendanceById(
    int attendanceId,
  ) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/attendance/$attendanceId',
        options: Options(headers: {'Authorization': authHeader}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not fetch attendance. (${e.toString()})');
    }
  }

  /// Employee check‑out
  static Future<Map<String, dynamic>> checkOut(int attendanceId) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.post(
        '/api/public/attendance/checkout',
        data: {'attendanceId': attendanceId},
        options: Options(headers: {'Authorization': authHeader}),
      );

      final data = response.data;
      if (data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(data['error'] ?? 'Checkout failed');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Checkout failed. (${e.toString()})');
    }
  }

  /// Get today's attendance status for an employee
  static Future<Map<String, dynamic>> getTodayStatus(String employeeId) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/attendance/$employeeId/today',
        options: Options(headers: {'Authorization': authHeader}),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not get today status. (${e.toString()})');
    }
  }

  /// Fetch attendance records for an employee (week, month, etc.)
  static Future<List<dynamic>> getAllAttendance(
    String employeeId, {
    String period = 'week',
  }) async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/attendance/$employeeId/all',
        queryParameters: {'period': period},
        options: Options(headers: {'Authorization': authHeader}),
      );

      // Backend returns { data: [...] } or just a list; adapt accordingly
      final body = response.data;
      if (body is Map && body.containsKey('data')) {
        return body['data'] as List<dynamic>;
      }
      // If the backend directly returns a list
      return body as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not load attendance history. (${e.toString()})');
    }
  }

  /// Get attendance records for all employees (admin only)
  static Future<List<dynamic>> getAllEmpAttendance() async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/attendance/getAll',
        options: Options(headers: {'Authorization': authHeader}),
      );

      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not fetch all attendance. (${e.toString()})');
    }
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// // import 'package:attendance/db/attendance_service.dart';

// class AttendanceService {
//   // static const String baseUrl = 'http://192.168.1.7:3001/api/v1/attendance';
//   // static const String baseUrl =
//   //     'http://10.118.185.202:3000/api/public/attendance';
//   static const String baseUrl =
//       'https://ahaz-dashboard.vercel.app/api/public/attendance';

//   static Future<Map<String, dynamic>> checkIn({
//     required String employeeId,
//     required String secret,
//     required bool isBssid,
//   }) async {
//     final url = Uri.parse('$baseUrl/checkin');

//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'employeeId': employeeId,
//         'secret': secret,
//         'isBssid': isBssid,
//       }),
//     );
//     final responseBody = jsonDecode(response.body);
//     if (response.statusCode == 201) {
//       return responseBody;
//     } else {
//       final error = responseBody['error'] ?? 'Check‑in failed';
//       throw Exception(error);
//     }
//   }

//   static Future<Map<String, dynamic>> getAttendanceById(
//     int attendanceId,
//   ) async {
//     final url = Uri.parse('$baseUrl/$attendanceId');

//     try {
//       final response = await http.get(
//         url,
//         headers: {'Content-Type': 'application/json'},
//       );

//       final responseBody = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return responseBody;
//       } else {
//         throw Exception(responseBody['error'] ?? 'Failed to fetch attendance');
//       }
//     } catch (e) {
//       throw Exception('Connection error: $e');
//     }
//   }

//   static Future<Map<String, dynamic>> checkOut(int attendanceId) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/checkout'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'attendanceId': attendanceId}),
//     );

//     final data = jsonDecode(response.body);

//     if (response.statusCode == 200 && data['success'] == true) {
//       return data['data'];
//     } else {
//       throw Exception(data['error'] ?? 'Checkout failed');
//     }
//   }

//   static Future<Map<String, dynamic>> getTodayStatus(String id) async {
//     final response = await http.get(Uri.parse('$baseUrl/$id/today'));
//     return jsonDecode(response.body);
//   }

//   static Future<List<dynamic>> getAllAttendance(
//     String id, {
//     String period = 'week',
//   }) async {
//     try {
//       final uri = Uri.parse(
//         '$baseUrl/$id/all',
//       ).replace(queryParameters: {'period': period});
//       final response = await http.get(uri).timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final body = jsonDecode(response.body);
//         return body['data'] as List<dynamic>;
//       } else {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('getDailyAttendance failed: $e');
//       return [];
//     }
//   }

//   static Future<List<dynamic>> getAllEmpAttendance() async {
//     final response = await http.get(Uri.parse('$baseUrl/getAll'));
//     return jsonDecode(response.body);
//   }

//   //
// }
