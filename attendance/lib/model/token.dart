import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  // Use Android encrypted shared preferences for modern security
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    // aOptions: AndroidOptions.biometric(
    //   enforceBiometrics: false,
    //   biometricPromptTitle: 'Authenticate to access data',
    // ),
  );

  static const String _tokenKey = 'ahaz_dashboard_token';

  // Save the token upon successful sign-in
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Retrieve the token for API requests
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete token upon logout
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
