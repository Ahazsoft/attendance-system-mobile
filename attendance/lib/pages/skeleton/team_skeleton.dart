import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TeamGroveSkeleton extends StatelessWidget {
  const TeamGroveSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header placeholder ---
            _buildTextPlaceholder(width: 80, height: 12),
            const SizedBox(height: 8),
            _buildTextPlaceholder(width: 160, height: 28),
            const SizedBox(height: 24),

            // --- Summary cards row ---
            Row(
              children: [
                Expanded(child: _buildCardPlaceholder()),
                const SizedBox(width: 12),
                Expanded(child: _buildCardPlaceholder()),
                const SizedBox(width: 12),
                Expanded(child: _buildCardPlaceholder()),
              ],
            ),
            const SizedBox(height: 24),

            // --- Member card list placeholders ---
            Expanded(
              child: ListView.builder(
                itemCount: 7, // enough to fill the screen
                itemBuilder: (context, index) => _buildMemberCardPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPlaceholder({
    double width = double.infinity,
    double height = 14,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // Shimmer overrides this
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCardPlaceholder() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildMemberCardPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          const CircleAvatar(backgroundColor: Colors.white, radius: 20),
          const SizedBox(width: 16),
          // Text column placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextPlaceholder(width: 120, height: 14),
                const SizedBox(height: 6),
                _buildTextPlaceholder(width: 80, height: 12),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTextPlaceholder(width: 50, height: 10),
                    const SizedBox(width: 12),
                    _buildTextPlaceholder(width: 50, height: 10),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Mini chart placeholder
          _buildMiniChartPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildMiniChartPlaceholder() {
    return SizedBox(
      height: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              return Container(
                width: 4,
                height: 10.0 + (index * 3) % 15,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
