class AppConfig {
  // Base URL for all API calls
  // static const String baseUrl = 'http://192.168.1.5:3000';
  static const String baseUrl = 'https://ahaz-attendance.vercel.app';

  // Timeout duration used by all services
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Optionally, you can add other shared constants like:
  // static const String apiVersion = '/api/public';
}
