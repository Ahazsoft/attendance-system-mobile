import 'dart:convert';
import 'package:attendance/db/auth_service.dart';
import 'package:http/http.dart' as http;

class SettingsService {
  // static const String baseUrl = 'http://192.168.1.7:3001/api/v1/settings';
  static const String baseUrl = 'http://10.68.70.202:3001/api/v1/settings';

  // Fetch settings from DB
  static Future<Map<String, dynamic>> getSettings() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load settings');
    }
  }

  // Update settings in DB
  static Future<void> updateSettings({
    required double radius,
    required String lat,
    required String lng,
    required String bssid,
    required String lateThreshold,
    required String secret,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'radius': radius.toInt(),
        'gpsLatitude': lat,
        'gpsLongitude': lng,
        'bssid': bssid,
        'lateThreshold': lateThreshold, // Should be "HH:mm:ss"
        'SecretCode': secret,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update settings');
    }
  }

  static Future<DateTime> getServerTime() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/getServerTime'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return DateTime.parse(data['utcTime']); // ✅ FIXED
    }

    throw Exception("Could not fetch server time");
  }

  //
}
