import 'package:attendance/pages/Admin/dashboard_screen.dart';
import 'package:attendance/pages/Admin/digital_ledger_screen.dart';
import 'package:attendance/pages/Admin/settings_screen.dart';
import 'package:attendance/pages/Admin/team_screen.dart';
import 'package:attendance/pages/shared/profile_screen.dart';
import 'package:flutter/material.dart';
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
    const ProfileViewPage(id: 'AHZ-0001'),
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
          fixedColor: AppColors.primaryColor,
          currentIndex: _currentIndex,
          unselectedItemColor: Colors.grey.shade600,
          onTap: (index) => {
            setState(() {
              _currentIndex = index;
            }),
          },
          // type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(
                Icons.dashboard_outlined,
                color: AppColors.primaryColor,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note_alt_outlined),
              activeIcon: Icon(
                Icons.note_alt_outlined,
                color: AppColors.primaryColor,
              ),
              label: 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(
                Icons.group_outlined,
                color: AppColors.primaryColor,
              ),
              label: 'Team',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_outlined),
              activeIcon: Icon(
                Icons.person_outline_outlined,
                color: AppColors.primaryColor,
              ),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(
                Icons.settings_outlined,
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
