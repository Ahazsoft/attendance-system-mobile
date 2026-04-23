import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/model/user.dart';

class EmployeeService {
  // static const String baseUrl = 'http://192.168.1.7:3001/api/v1/users';
  // static const String baseUrl = 'http://10.68.70.202:3001/api/v1/users';
  static const String baseUrl =
      'https://attendance-backend.ahaz.io/api/v1/users';

  static Future<User> fetchUserById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/get-user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({'id': id}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        return User.fromJson(data['user']);
      } catch (e) {
        throw Exception("Failed to parse user data");
      }
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch user');
    }
  }

  static Future<User> updateUserProfile({
    required int id,
    required String firstName,
    required String lastName,
    required String telephone,
    File? imageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Use MultipartRequest for sending files
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/update-user/$id'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    // Attach text fields
    request.fields['firstName'] = firstName;
    request.fields['lastName'] = lastName;
    request.fields['telephone'] = telephone;

    // Attach image file if one was selected
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      // Assuming your User model has a fromJson method
      return User.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to update profile');
    }
  }

  static Future<List<User>> fetchAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/fetchAllUsers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((e) => User.fromJson(e)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to fetch users');
    }
  }
}
