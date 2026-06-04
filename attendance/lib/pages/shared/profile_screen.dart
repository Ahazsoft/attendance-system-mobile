// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:attendance/db/auth_provider.dart';
import 'package:attendance/db/auth_service.dart';
import 'package:attendance/db/employee_service.dart';
import 'package:attendance/model/user.dart';
import 'package:attendance/pages/shared/edit_profile_screen.dart';
import 'package:attendance/pages/Auth/login.dart';
import 'package:attendance/pages/skeleton/profile_skeleton.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class ProfileViewPage extends StatefulWidget {
  final String id;
  const ProfileViewPage({super.key, required this.id});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  bool _notificationsEnabled = false;
  User? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  // Cache helpers
  String get _cacheKey => 'profile_cache_${widget.id}';

  String _todayEatDateString() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json != null) return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Profile cache read error: $e');
    }
    return null;
  }

  Future<void> _writeCache(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'date': _todayEatDateString(),
        'user': user.toJson(),
      });
      await prefs.setString(_cacheKey, payload);
    } catch (e) {
      debugPrint('Profile cache write error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData(); // cache‑first logic
  }

  // Cache‑first: use today's cache if available, else fetch from server
  Future<void> _loadData() async {
    final cached = await _readCache();
    if (cached != null && cached['date'] == _todayEatDateString()) {
      try {
        setState(() {
          _userData = User.fromJson(cached['user'] as Map<String, dynamic>);
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      } catch (e) {
        debugPrint('Profile cache corrupt: $e');
        // Corrupt cache – remove it and fall through to server fetch
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cacheKey);
      }
    }
    await _fetchFromServer();
  }

  // Fetch fresh data from server and cache it
  Future<void> _fetchFromServer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final user = await EmployeeService.fetchUserById(widget.id);
      if (!mounted) return;
      setState(() {
        _userData = user;
        _isLoading = false;
      });
      _writeCache(user);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToEdit() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: _userData!),
      ),
    );

    if (updatedUser != null && updatedUser is User) {
      setState(() {
        _userData = updatedUser;
      });
      // Update cache with new user data
      _writeCache(updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ProfileSkeletonContent(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            Text("Something went wrong", style: AppTextStyles.bodyBold),
            TextButton(
              onPressed: _loadData, // retry using cache‑first again
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildProfile(),
            const SizedBox(height: 30),
            _buildInfoCard(),
            _buildSettingsCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundImage:
              _userData?.imageUrl != null && _userData!.imageUrl!.isNotEmpty
              ? NetworkImage(_userData!.imageUrl!)
              : null,
          child: _userData?.imageUrl == null || _userData!.imageUrl!.isEmpty
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 15),
        Text(
          _userData!.fullName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
        Text(
          _userData?.position ?? "Member",
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _navigateToEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          ),
          child: const Text(
            "Edit Profile",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _infoTile(Icons.email_outlined, "Email", _userData!.email),
          const Divider(height: 30),
          _infoTile(
            Icons.phone_outlined,
            "Phone",
            _userData?.telephone ?? "Not set",
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryText, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              "Notifications",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            secondary: const Icon(
              Icons.notifications_none,
              color: AppColors.primaryText,
            ),
            activeThumbColor: AppColors.primaryText,
            inactiveThumbColor: AppColors.primaryText,
            value: _notificationsEnabled,
            onChanged: (bool value) =>
                setState(() => _notificationsEnabled = value),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 20),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.primaryText),
            title: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () async {
              try {
                await AuthProvider.logout();
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
