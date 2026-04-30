import 'package:flutter/material.dart';

class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          // Radius (meters)
          _fieldSkeleton(),
          const SizedBox(height: 30),
          // GPS Latitude
          _fieldSkeleton(),
          const SizedBox(height: 24),
          // GPS Longitude
          _fieldSkeleton(),
          const SizedBox(height: 24),
          // Wi‑Fi BSSID
          _fieldSkeleton(),
          const SizedBox(height: 24),
          // Late Threshold (HH:mm)
          _fieldSkeleton(),
          const SizedBox(height: 24),
          // Secret Code
          _fieldSkeleton(),
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
    );
  }

  /// A single input field skeleton (label line + rounded rectangle).
  Widget _fieldSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _box(width: 100, height: 12), // fake label
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
