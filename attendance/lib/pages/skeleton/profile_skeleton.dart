import 'package:flutter/material.dart';

class ProfileSkeletonContent extends StatelessWidget {
  const ProfileSkeletonContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        _buildProfile(),
        const SizedBox(height: 30),
        _buildInfoCard(),
        _buildSettingsCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        const CircleAvatar(radius: 55, backgroundColor: Colors.grey),
        const SizedBox(height: 15),
        _box(width: 150, height: 18),
        const SizedBox(height: 8),
        _box(width: 80, height: 14),
        const SizedBox(height: 15),
        _box(width: 120, height: 36, borderRadius: 8),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoTilePlaceholder(),
          const Divider(height: 30),
          _infoTilePlaceholder(),
          const Divider(height: 30),
          _infoTilePlaceholder(),
        ],
      ),
    );
  }

  Widget _infoTilePlaceholder() {
    return Row(
      children: [
        const Icon(Icons.circle, size: 20, color: Colors.grey),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(width: 60, height: 10),
            const SizedBox(height: 4),
            _box(width: 100, height: 14),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.grey),
            title: _box(width: 120, height: 16),
            trailing: _box(width: 40, height: 24, borderRadius: 12),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 20),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: _box(width: 80, height: 16),
          ),
        ],
      ),
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
        color: Colors.grey.shade300, // ← still works, shimmer will override it
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
