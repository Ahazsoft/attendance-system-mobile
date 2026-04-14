import 'package:attendance/db/employee_service.dart';
import 'package:attendance/model/user.dart';
import 'package:attendance/pages/shared/edit_profile_screen.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';

class ProfileViewPage extends StatefulWidget {
  final int id;
  const ProfileViewPage({super.key, required this.id});

  @override
  State<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends State<ProfileViewPage> {
  final User _currentUser = User(
    id: 1,
    firstName: 'Temp',
    lastName: 'Temp',
    email: 'temp',
    isAdmin: false,
    isApproved: true,
    streak: 0,
  );
  bool _notificationsEnabled = false;
  // Data State Variables
  User? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  void _navigateToEdit() async {
    // Wait for the updated user object from the Edit page
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: _userData ?? _currentUser),
      ),
    );

    if (updatedUser != null && updatedUser is User) {
      setState(() {
        _userData = updatedUser;
      });
    }
  }

  Future<void> _fetchEmployeeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Using widget.id passed from the parent screen
      final user = await EmployeeService.fetchUserById(widget.id);

      setState(() {
        _userData = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryText),
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
              onPressed: _fetchEmployeeData,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Creamy background
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildProfile(),
            // const SizedBox(height: 30),
            // _buildStatsRow(),
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
          backgroundImage: NetworkImage(
            _userData?.imageUrl ??
                'https://randomuser.me/api/portraits/men/20.jpg',
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "${_userData!.firstName} ${_userData!.lastName}",
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
            backgroundColor: const Color(0xFF8D6E63),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // ← Less rounded (was 30)
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

  // Widget _buildStatsRow() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     margin: const EdgeInsets.symmetric(horizontal: 20),
  //     decoration: BoxDecoration(
  //       color: AppColors.cardWhite,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
  //       boxShadow: [
  //         BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         Column(
  //           children: [
  //             Text(
  //               "Streak",
  //               style: const TextStyle(fontSize: 12, color: Colors.brown),
  //             ),
  //             Text(
  //               "${_currentUser.streak} 🔥",
  //               style: const TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ],
  //         ),
  //         Container(
  //           height: 40,
  //           width: 1,
  //           color: AppColors.primaryText.withOpacity(0.2),
  //         ),
  //         Column(
  //           children: [
  //             Text(
  //               "Status",
  //               style: const TextStyle(fontSize: 12, color: Colors.brown),
  //             ),
  //             Text(
  //               _currentUser.isApproved ? "Verified" : "Pending",
  //               style: const TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
          const Divider(height: 30),
          _infoTile(
            Icons.attach_money_outlined,
            "Salary",
            _userData!.salary != null
                ? "\$${_userData!.salary!.toStringAsFixed(2)}"
                : "Not set",
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8D6E63), size: 20),
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
              color: Color(0xFF8D6E63),
            ),
            activeColor: const Color(0xFF8D6E63),
            value: _notificationsEnabled,
            onChanged: (bool value) =>
                setState(() => _notificationsEnabled = value),
          ),
          const Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
            child: Divider(height: 20),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF8D6E63)),
            title: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            onTap: () {}, // Navigate to change password screen
          ),
        ],
      ),
    );
  }
}
