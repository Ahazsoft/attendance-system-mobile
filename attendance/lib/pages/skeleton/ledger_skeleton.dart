import 'package:flutter/material.dart';

class DigitalLedgerSkeleton extends StatelessWidget {
  const DigitalLedgerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header area
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 40, height: 12),
              const SizedBox(height: 8),
              _box(width: 150, height: 24),
              const SizedBox(height: 16),

              // Search bar placeholder
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),

              // Legend placeholders
              Row(
                children: [
                  _legendChip(),
                  const SizedBox(width: 12),
                  _legendChip(),
                  const SizedBox(width: 12),
                  _legendChip(),
                ],
              ),
              const SizedBox(height: 8),
              _box(width: 100, height: 12),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of placeholder cards
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: List.generate(5, (index) => _cardPlaceholder()),
          ),
        ),
      ],
    );
  }

  Widget _cardPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar placeholder
          const CircleAvatar(backgroundColor: Colors.grey, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 100, height: 14),
                        const SizedBox(height: 4),
                        _box(width: 60, height: 10),
                      ],
                    ),
                    const Icon(Icons.circle, size: 20, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(width: 50, height: 10),
                    _box(width: 50, height: 10),
                    _box(width: 50, height: 10),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendChip() {
    return Row(
      children: [
        const Icon(Icons.circle, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        _box(width: 60, height: 10),
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
