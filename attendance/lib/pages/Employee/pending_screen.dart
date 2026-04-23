import 'package:attendance/Pages/auth/login.dart';
import 'package:flutter/material.dart';
import '../../theme/appTheme.dart';

class EmployeePendingPage extends StatelessWidget {
  final String adminEmail;

  const EmployeePendingPage({super.key, this.adminEmail = 'admin@example.com'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top, size: 96, color: AppColors.primaryText),
            const SizedBox(height: 20),
            Text(
              'Account Pending Approval',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your account is pending approval. An administrator will review and approve your account shortly.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyRegular,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    8,
                  ), // ← Less rounded (was 30)
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text(
                "Return To Login",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
