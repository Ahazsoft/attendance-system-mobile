import 'package:flutter/material.dart';

class EditProfileSkeleton extends StatelessWidget {
  const EditProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // match your background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.close, color: Colors.grey),
        title: _box(width: 100, height: 20),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar placeholder
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(radius: 60, backgroundColor: Colors.grey),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade400,
                      radius: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Three input field placeholders
            _inputFieldSkeleton(),
            const SizedBox(height: 20),
            _inputFieldSkeleton(),
            const SizedBox(height: 20),
            _inputFieldSkeleton(),

            const SizedBox(height: 40),

            // Save button placeholder
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A single input field skeleton (label + rounded rectangle).
  Widget _inputFieldSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(width: 80, height: 12),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ],
    );
  }

  /// Simple grey rounded rectangle helper.
  Widget _box({
    required double width,
    required double height,
    double borderRadius = 8.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
