import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  // static const String baseUrl = 'http://192.168.1.7:3001/api/v1/attendance';
  static const String baseUrl = 'http://10.68.70.202:3001/api/v1/attendance';

  static Future<Map<String, dynamic>> checkIn({
    required int employeeId,
    required String secret,
    required bool isBssid,
  }) async {
    final url = Uri.parse('$baseUrl/check-in');

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
    print("responseBody: $responseBody");

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
      Uri.parse('$baseUrl/check-out'),
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

  static Future<Map<String, dynamic>> getTodayStatus(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/today/$id'));
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getAllAttendance(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/all/$id'));
    return jsonDecode(response.body);
  }

  //
}
