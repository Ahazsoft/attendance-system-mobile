import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/model/user.dart';

class EmployeeService {
  // static const String baseUrl = 'http://192.168.1.7:3001/api/v1/users';
  // static const String baseUrl =
  //     'http://10.118.185.202:3000/api/public/employee';
  static const String baseUrl =
      'https://ahaz-dashboard.vercel.app/api/public/employee';

  static Future<User> fetchUserById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // ✅ FIX 1: Change URL to your actual Next.js get-user POST route
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    required String id,
    required String fullName,
    required String telephone,
    File? imageFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Use MultipartRequest for sending files
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/$id'));

    request.headers['Authorization'] = 'Bearer $token';

    // Attach text fields
    request.fields['fullName'] = fullName;
    // request.fields['lastName'] = lastName;
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
