import 'package:attendance/pages/Employee/dashboard_screen.dart';
import 'package:attendance/pages/Employee/history_screen.dart';
// import 'package:attendance/pages/Employee/pending_screen.dart';
import 'package:attendance/pages/Employee/scanner_screen.dart';
import 'package:attendance/pages/shared/profile_screen.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmployeeHomeScreen extends StatefulWidget {
  final int id;
  // const EmployeeHomeScreen({super.key});
  const EmployeeHomeScreen({super.key, required this.id});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // print("EmployeeHomeScreen Init with : ${widget.id}");
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      EmployeeDashboardScreen(
        onScanPressed: () {
          setState(() {
            currentIndex = 1;
          });
        },
        onProfilePressed: () {
          setState(() {
            currentIndex = 3;
          });
        },
        id: widget.id,
      ),
      ScannerScreen(
        id: widget.id,
        onCheckInSuccess: (response) {
          setState(() {
            currentIndex = 0; // Switch back to Dashboard
          });
        },
      ),
      HistoryScreen(id: widget.id),
      ProfileViewPage(id: widget.id),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: Container(
        // decoration: BoxDecoration(
        //   border: Border(
        //     top: BorderSide(color: AppColors.primaryText.withOpacity(0.3)),
        //   ),
        // ),
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
          currentIndex: currentIndex,
          unselectedItemColor: Colors.grey.shade600,
          onTap: (index) => {
            setState(() {
              currentIndex = index;
            }),
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.house()),
              activeIcon: Icon(
                PhosphorIcons.house(),
                color: AppColors.primaryColor,
              ),

              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.qrCode()),
              activeIcon: PhosphorIcon(
                PhosphorIcons.qrCode(),
                color: AppColors.primaryColor,
              ),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.clockCounterClockwise()),
              activeIcon: Icon(
                PhosphorIcons.clockCounterClockwise(),
                color: AppColors.primaryColor,
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.user()),
              activeIcon: Icon(
                PhosphorIcons.user(),
                color: AppColors.primaryColor,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
