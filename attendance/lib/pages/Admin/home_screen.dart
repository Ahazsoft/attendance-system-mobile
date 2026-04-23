import 'package:attendance/pages/Admin/dashboard_screen.dart';
import 'package:attendance/pages/Admin/digital_ledger_screen.dart';
import 'package:attendance/pages/Admin/settings_screen.dart';
import 'package:attendance/pages/Admin/team_screen.dart';
import 'package:attendance/pages/shared/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:attendance/theme/appTheme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  // The 4 main Admin screens
  final List<Widget> _pages = [
    const AdminDashboardScreen(),
    const DigitalLedgerScreen(),
    const TeamGroveScreen(), // Placeholder
    const ProfileViewPage(id: 2),
    const OfficeSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          fixedColor: AppColors.primaryGreen,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed, // Needed for 4+ items
          items: [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.chartBar()),
              activeIcon: Icon(
                PhosphorIconsBold.chartBar,
                color: AppColors.primaryColor,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.bookOpen()),
              activeIcon: Icon(
                PhosphorIconsBold.bookOpen,
                color: AppColors.primaryColor,
              ),
              label: 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.usersThree()),
              activeIcon: Icon(
                PhosphorIconsBold.usersThree,
                color: AppColors.primaryColor,
              ),
              label: 'Team',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.user()),
              activeIcon: Icon(
                PhosphorIcons.user(),
                color: AppColors.primaryColor,
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.gear()),
              activeIcon: Icon(
                PhosphorIconsBold.gear,
                color: AppColors.primaryColor,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
