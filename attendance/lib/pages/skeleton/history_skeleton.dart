import 'package:flutter/material.dart';

class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Title & Subtitle ---
          _box(width: 100, height: 24),
          const SizedBox(height: 8),
          _box(width: 150, height: 16),
          const SizedBox(height: 24),

          // --- Toggle Buttons (This Week / This Month) ---
          Row(
            children: [
              _box(width: 100, height: 36, borderRadius: 24),
              const SizedBox(width: 8),
              _box(width: 100, height: 36, borderRadius: 24),
            ],
          ),
          const SizedBox(height: 24),

          // --- 3 Stat Cards ---
          Row(children: List.generate(3, (i) => Expanded(child: _statCard()))),
          const SizedBox(height: 32),

          // --- Timeline Placeholder Items (shows 3) ---
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => _timelineItem(),
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Placeholder for one stat card (days / hours / late).
  Widget _statCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _box(width: 40, height: 20, borderRadius: 4),
          const SizedBox(height: 4),
          _box(width: 60, height: 10, borderRadius: 4),
        ],
      ),
    );
  }

  /// Placeholder for one timeline entry (date line + summary card).
  Widget _timelineItem() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator (circle + vertical line)
          SizedBox(
            width: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 24,
                  bottom: 0,
                  child: Container(width: 1, color: Colors.grey.shade300),
                ),
                Positioned(
                  top: 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right side content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _box(width: 50, height: 14),
                      const SizedBox(width: 8),
                      _box(width: 40, height: 14),
                      const Spacer(),
                      _box(width: 40, height: 14, borderRadius: 8),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        3,
                        (_) => Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            _box(width: 40, height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
