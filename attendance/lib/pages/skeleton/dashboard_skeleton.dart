import 'package:flutter/material.dart';

class EmployeeDashboardSkeleton extends StatelessWidget {
  const EmployeeDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top row (greeting + avatar) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 120, height: 16),
                  const SizedBox(height: 8),
                  _shimmerBox(width: 160, height: 24),
                ],
              ),
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE0E0E0),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Date / time card ---
          _shimmerCard(height: 60),

          const Spacer(),

          // --- Central scan button placeholder ---
          Center(
            child: Column(
              children: [
                // Outer ripple circle placeholder
                _shimmerBox(width: 210, height: 210, shape: BoxShape.circle),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const Spacer(),

          // --- "TODAY'S SUMMARY" label ---
          _shimmerBox(width: 130, height: 14),
          const SizedBox(height: 16),

          // --- Summary grid of 4 cards ---
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: List.generate(4, (index) => _shimmerCard()),
          ),
        ],
      ),
    );
  }

  /// A simple grey rounded rectangle.
  Widget _shimmerBox({
    required double width,
    required double height,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(8)
            : null,
      ),
    );
  }

  /// A card-like placeholder with same styling as the real summary cards.
  Widget _shimmerCard({double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
