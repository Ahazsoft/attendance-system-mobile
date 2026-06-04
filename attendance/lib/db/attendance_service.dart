import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:attendance/db/attendance_service.dart';

class AttendanceService {
  // static const String baseUrl = 'http://192.168.1.7:3001/api/v1/attendance';
  // static const String baseUrl =
  //     'http://10.118.185.202:3000/api/public/attendance';
  static const String baseUrl =
      'https://ahaz-dashboard.vercel.app/api/public/attendance';

  static Future<Map<String, dynamic>> checkIn({
    required String employeeId,
    required String secret,
    required bool isBssid,
  }) async {
    final url = Uri.parse('$baseUrl/checkin');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'secret': secret,
        'isBssid': isBssid,
      }),
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return responseBody;
    } else {
      final error = responseBody['error'] ?? 'Check‑in failed';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> getAttendanceById(
    int attendanceId,
  ) async {
    final url = Uri.parse('$baseUrl/$attendanceId');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['error'] ?? 'Failed to fetch attendance');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  static Future<Map<String, dynamic>> checkOut(int attendanceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/checkout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'attendanceId': attendanceId}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception(data['error'] ?? 'Checkout failed');
    }
  }

  static Future<Map<String, dynamic>> getTodayStatus(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id/today'));
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getAllAttendance(
    String id, {
    String period = 'week',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/$id/all',
      ).replace(queryParameters: {'period': period});
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] as List<dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('getDailyAttendance failed: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getAllEmpAttendance() async {
    final response = await http.get(Uri.parse('$baseUrl/getAll'));
    return jsonDecode(response.body);
  }

  //
}
