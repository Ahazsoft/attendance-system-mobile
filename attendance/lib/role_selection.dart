import 'package:attendance/pages/Admin/home_screen.dart';
import 'package:attendance/pages/Auth/login.dart';
import 'package:attendance/pages/Employee/home_screen.dart';
import 'package:attendance/pages/Employee/pending_screen.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:attendance/db/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    // Start the animation
    _animController.forward();

    // After animation completes, check login status
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkLogin(); // same method you already have
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Your existing _checkLogin logic (unchanged)
  Future<void> _checkLogin() async {
    final loggedIn = await AuthProvider.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final data = await AuthProvider.getUserData();
      final isAdmin = data['isAdmin'] as bool;
      final isApproved = data['isApproved'] as bool;
      final userId = data['userId'] as String;

      Widget destination;
      if (isAdmin) {
        destination = const AdminHomeScreen();
      } else if (isApproved) {
        destination = EmployeeHomeScreen(id: userId);
      } else {
        destination = const EmployeePendingPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // use your app background
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 130,
                      width: 200,
                    ),
                    const SizedBox(height: 20),
                    // Text
                    const Text(
                      'Ahaz Attendance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
