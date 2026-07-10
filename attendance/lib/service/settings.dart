import 'dart:async';
import 'dart:io';
import 'package:attendance/service/app_config.dart';
import 'package:dio/dio.dart';
import 'package:attendance/model/token.dart';

class SettingsService {
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

  /// Fetch current organisation/attendance settings
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/settings',
        options: Options(headers: {'Authorization': authHeader}),
      );
      print("Get Settings : $response");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not load settings. (${e.toString()})');
    }
  }

  /// Update organisation/attendance settings
  static Future<void> updateSettings({
    required double radius,
    required String lat,
    required String lng,
    required String bssid,
    required String lateThreshold,
    required String secret,
  }) async {
    try {
      final authHeader = await _getAuthHeader();
      await _dio.put(
        '/api/public/settings',
        data: {
          'radius': radius.toInt(),
          'gpsLatitude': lat,
          'gpsLongitude': lng,
          'bssid': bssid,
          'lateThreshold': lateThreshold,
          'SecretCode': secret,
        },
        options: Options(headers: {'Authorization': authHeader}),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not update settings. (${e.toString()})');
    }
  }

  /// Get the current server UTC time (used for clock synchronisation)
  static Future<DateTime> getServerTime() async {
    try {
      final authHeader = await _getAuthHeader();
      final response = await _dio.get(
        '/api/public/settings/time',
        options: Options(headers: {'Authorization': authHeader}),
      );

      final data = response.data;
      return DateTime.parse(data['utcTime']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Could not fetch server time. (${e.toString()})');
    }
  }
}
