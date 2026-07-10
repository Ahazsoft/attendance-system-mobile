import 'dart:convert';
import 'package:attendance/model/user.dart';
import 'package:attendance/service/employee_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'employee_provider.g.dart';

// 1. The main notifier that acts as the source of truth
@Riverpod(keepAlive: true)
class EmployeeNotifier extends _$EmployeeNotifier {
  String get _cacheKey => 'profile_cache_$id';

  @override
  FutureOr<User> build(String id) async {
    // Initial load: Fetch from API and update the cache
    return _fetchAndUpdateCache();
  }

  /// Centralized method to hit the API and update the local cache
  Future<User> _fetchAndUpdateCache() async {
    // 3. Errors are allowed to bubble up naturally, handled by your API layer
    final user = await EmployeeService.fetchUserById(id);

    // Update the cache so it's ready for immediate use on next app launch
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(user.toJson()));

    return user;
  }

  /// Call this from your UI (e.g., RefreshIndicator) for a hard refresh
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAndUpdateCache());
  }

  /// Updates the profile, then fetches the fresh user data
  Future<void> updateUserProfile({
    required String fullName,
    required String telephone,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // Execute the update request
      await EmployeeService.updateUserProfile(
        id: id,
        fullName: fullName,
        telephone: telephone,
      );

      // 2. Fetch the new user directly from the server to guarantee
      // the UI and cache are perfectly synced with the database
      return _fetchAndUpdateCache();
    });
  }
}
