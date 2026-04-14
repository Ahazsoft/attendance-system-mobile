import 'package:flutter/material.dart';

class EmployeePendingPage extends StatelessWidget {
  const EmployeePendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsetsGeometry.all(20),
          child: Text(
            'Your account is pending approval. Please wait for an administrator to approve your account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
