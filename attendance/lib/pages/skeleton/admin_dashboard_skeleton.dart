import 'package:flutter/material.dart';

class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Placeholder ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(width: 80, height: 14),
                  const SizedBox(height: 8),
                  _box(width: 140, height: 24),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _box(width: 120, height: 14),
                  const SizedBox(height: 4),
                  _box(width: 80, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Stats Grid (2x2) ---
          Row(
            children: [
              Expanded(child: _statCard()),
              const SizedBox(width: 16),
              Expanded(child: _statCard()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard()),
              const SizedBox(width: 16),
              Expanded(child: _statCard()),
            ],
          ),
          const SizedBox(height: 24),

          // --- Weekly Presence Card ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 120, height: 16),
                const SizedBox(height: 24),
                // Fake bar chart area
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      5,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          height: _randomBarHeight(index),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Simple grey rounded rectangle.
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

  /// Placeholder for one stat card (icon + value + label).
  Widget _statCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 24, color: Colors.grey),
          const SizedBox(height: 12),
          _box(width: 40, height: 20),
          const SizedBox(height: 4),
          _box(width: 80, height: 14),
        ],
      ),
    );
  }

  // Give each bar a different fixed height to look realistic.
  double _randomBarHeight(int index) {
    const heights = [100.0, 140.0, 80.0, 160.0, 120.0];
    return heights[index % heights.length];
  }
}
