import 'package:attendance/pages/Admin/home_screen.dart';
import 'package:attendance/pages/Employee/home_screen.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors matching your organic theme

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Top Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.energy_savings_leaf_outlined,
                  color: AppColors.primaryGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Main Title
              const Text(
                'AttendLeaf',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily:
                      'Serif', // Ensure you have a serif font defined in pubspec.yaml
                ),
              ),
              const SizedBox(height: 8),

              // 3. Subtitle
              Text(
                'Nature-inspired attendance tracking',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 48),

              // 4. Employee Portal Card
              _buildRoleCard(
                title: 'Employee Portal',
                subtitle: 'Check in & view history',
                icon: Icons.shield_outlined,
                iconBgColor: AppColors.lightGreen,
                iconColor: AppColors.primaryGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeHomeScreen(id: 3),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 5. Admin Dashboard Card
              _buildRoleCard(
                title: 'Admin Dashboard',
                subtitle: 'Manage & monitor team',
                icon: Icons.people_outline,
                iconBgColor: AppColors.background,
                iconColor:
                    AppColors.primaryText, // Using primary brown for admin icon
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminHomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable widget for the selection cards
  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28), // Smooth organic corners
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Icon Background
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),

            // Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF624232), // primaryText
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E), // greyText
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
