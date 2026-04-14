import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';

class TeamGroveScreen extends StatefulWidget {
  const TeamGroveScreen({super.key});

  @override
  State<TeamGroveScreen> createState() => _TeamGroveScreenState();
}

class _TeamGroveScreenState extends State<TeamGroveScreen> {
  // Mock data for the team list
  final List<Map<String, dynamic>> teamMembers = [
    {
      'name': 'Sarah Johnson',
      'role': 'Frontend Developer',
      'streak': '12d',
      'avg': '8.2h',
      'status': Colors.green,
      'hours': [8.0, 7.5, 8.0, 8.0, 7.8], // Mon - Fri
    },
    {
      'name': 'Ahmed Ali',
      'role': 'Backend Developer',
      'streak': '8d',
      'avg': '8.5h',
      'status': Colors.green,
      'hours': [8.0, 8.0, 8.0, 8.0, 8.0],
    },
    {
      'name': 'Maya Chen',
      'role': 'Designer',
      'streak': '3d',
      'avg': '7.8h',
      'status': Colors.green,
      'hours': [7.0, 8.0, 6.5, 8.0, 7.2],
    },
    {
      'name': 'James Okafor',
      'role': 'Project Manager',
      'streak': '15d',
      'avg': '8h',
      'status': Colors.orange,
      'hours': [8.0, 4.0, 8.0, 8.0, 8.0], // Partial day on Tuesday
    },
    {
      'name': 'Priya Sharma',
      'role': 'QA Engineer',
      'streak': '10d',
      'avg': '8.1h',
      'status': Colors.green,
      'hours': [8.0, 8.0, 7.5, 8.0, 8.0],
    },
    {
      'name': 'Luca Rossi',
      'role': 'DevOps',
      'streak': '2d',
      'avg': '7.5h',
      'status': Colors.green,
      'hours': [6.0, 7.0, 8.0, 7.0, 6.5],
    },
    {
      'name': 'Emma Wilson',
      'role': 'Marketing',
      'streak': '0d',
      'avg': '7.9h',
      'status': Colors.grey,
      'hours': [0.0, 0.0, 8.0, 8.0, 7.5], // Absent Mon-Tue
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Team', style: AppTextStyles.label),
              const Text('Your Grove', style: AppTextStyles.heading1),
              const SizedBox(height: 24),

              // 1. Top Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      '8',
                      'Active',
                      AppColors.lightGreen,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      '2',
                      'Absent',
                      AppColors.lightRed,
                      AppColors.redLate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      '88%',
                      'Avg Rate',
                      AppColors.cardWhite,
                      AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Team Member List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: teamMembers.length,
            itemBuilder: (context, index) {
              final member = teamMembers[index];
              return _buildMemberCard(member);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String value,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.heading2.copyWith(color: textColor)),
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          // Avatar with Initial
          CircleAvatar(
            backgroundColor: AppColors.background,
            child: Text(
              member['name'].substring(0, 1),
              style: AppTextStyles.bodyBold,
            ),
          ),
          const SizedBox(width: 16),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(member['name'], style: AppTextStyles.bodyBold),
                  ],
                ),
                Text(member['role'], style: AppTextStyles.label),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.energy_savings_leaf_outlined,
                      color: AppColors.primaryGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${member['streak']} streak',
                      style: AppTextStyles.label.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.schedule, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${member['avg']} avg',
                      style: AppTextStyles.label.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Mini Indicator Chart (Represented by small vertical bars)
          _buildMiniChart(member),
        ],
      ),
    );
  }

  Widget _buildMiniChart(Map<String, dynamic> member) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(Icons.circle, color: member['status'], size: 10),
        SizedBox(height: 25),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(member['hours'].length, (index) {
            final double dayHours = member['hours'][index];

            double height;

            if (dayHours == 0) {
              // If hours is 0 use 10
              height = 10.0;
            } else if (dayHours >= 8) {
              // 8 hours and above use 24
              height = 24.0;
            } else {
              // Otherwise use the % logic for all others
              height = 10.0 + (index * 2) % 15;
            }
            return Container(
              width: 4,
              height: height,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: height == 24.0
                    ? AppColors.primaryGreen.withOpacity(0.6)
                    : AppColors.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }
}
