import 'dart:async';
import 'package:attendance/service/attendance_service.dart';
import 'package:attendance/service/employee_service.dart';
import 'package:attendance/model/user.dart';
import 'package:attendance/pages/skeleton/team_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:intl/intl.dart';

class TeamGroveScreen extends StatefulWidget {
  const TeamGroveScreen({super.key});

  @override
  State<TeamGroveScreen> createState() => _TeamGroveScreenState();
}

class _TeamGroveScreenState extends State<TeamGroveScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _teamMembers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch all users
      final List<User> users = await EmployeeService.fetchAllUsers();

      // Filter out any user without an id (safety)
      final validUsers = users.where((u) => u.id != null).toList();

      final now = DateTime.now().toLocal(); // work in local time
      final weekday = now.weekday; // 1=Mon … 7=Sun
      final monday = now.subtract(Duration(days: weekday - 1));
      final thisWeekDates = List.generate(
        5,
        (i) => monday.add(Duration(days: i)),
      ); // Mon–Fri

      final List<Map<String, dynamic>> processed = [];

      for (final user in validUsers) {
        final attendanceRecords = await AttendanceService.getAllAttendance(
          user.id,
        );

        // Index records by local date string "yyyy-MM-dd"
        final Map<String, Map<String, dynamic>> byDate = {};
        for (final record in attendanceRecords) {
          final checkInStr = record['checkInTime'] as String?;
          if (checkInStr == null || checkInStr.isEmpty) continue;

          final checkInUtc = DateTime.parse(checkInStr);
          final dateKey = DateFormat('yyyy-MM-dd').format(checkInUtc.toLocal());
          // Use first record per day (no double‑counting)
          if (!byDate.containsKey(dateKey)) {
            byDate[dateKey] = record as Map<String, dynamic>;
          }
        }

        // Compute hours for Mon–Fri of the current week
        final List<double> weekHours = [];
        for (final date in thisWeekDates) {
          final key = DateFormat('yyyy-MM-dd').format(date);
          if (byDate.containsKey(key)) {
            final record = byDate[key]!;
            final checkIn = DateTime.parse(record['checkInTime'] as String);
            final checkOutStr =
                record['checkOutTime'] as String?; // camelCase, nullable
            double hours = 0;
            if (checkOutStr != null && checkOutStr.isNotEmpty) {
              final checkOut = DateTime.parse(checkOutStr);
              hours = checkOut.difference(checkIn).inMinutes / 60.0;
            }
            weekHours.add(hours);
          } else {
            weekHours.add(0.0);
          }
        }

        // Today’s status colour
        final todayHours = weekHours[now.weekday - 1]; // Mon=0
        Color status;
        if (todayHours >= 8) {
          status = Colors.green;
        } else if (todayHours > 0) {
          status = Colors.orange;
        } else {
          status = Colors.grey;
        }

        // Average hours (just for display)
        final sum = weekHours.fold(0.0, (prev, e) => prev + e);
        final avgHours = weekHours.any((h) => h > 0)
            ? sum / weekHours.length
            : 0;

        // Days with any worked hours (used for the “Avg Rate” below)
        final daysWorked = weekHours.where((h) => h > 0).length;

        // Streak is not recorded for now – placeholder
        // final streak = _calculateStreak(byDate, now);

        processed.add({
          'id': user.id,
          'name': user.fullName,
          'role': user.position ?? 'Team Member',
          'streak': '0d', // placeholder since streak is not recorded
          'avg': '${avgHours.toStringAsFixed(1)}h',
          'status': status,
          'hours': weekHours,
          'daysWorked': daysWorked,
        });
      }

      setState(() {
        _teamMembers = processed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Streak method removed – not used for now
  /*
  int _calculateStreak(
    Map<String, Map<String, dynamic>> byDate,
    DateTime today,
  ) {
    // ... old code
  }
  */

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return TeamGroveSkeleton();
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $_errorMessage',
            style: AppTextStyles.bodyRegular,
          ),
        ),
      );
    }

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
              _buildSummaryRow(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _teamMembers.isEmpty
              ? const Center(
                  child: Text(
                    'No team members found',
                    style: AppTextStyles.bodyRegular,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _teamMembers.length,
                  itemBuilder: (context, index) =>
                      _buildMemberCard(_teamMembers[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final activeCount = _teamMembers
        .where(
          (m) => m['status'] == Colors.green || m['status'] == Colors.orange,
        )
        .length;
    final absentCount = _teamMembers
        .where((m) => m['status'] == Colors.grey)
        .length;

    // Average attendance rate: for each member, daysWorked/5, then average
    double avgAttendanceRate = 0;
    if (_teamMembers.isNotEmpty) {
      final totalRate = _teamMembers
          .map((m) => (m['daysWorked'] as int) / 5.0)
          .reduce((a, b) => a + b);
      avgAttendanceRate = (totalRate / _teamMembers.length) * 100;
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            activeCount.toString(),
            'Active',
            AppColors.lightGreen,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            absentCount.toString(),
            'Absent',
            AppColors.lightRed,
            AppColors.redLate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '${avgAttendanceRate.toStringAsFixed(0)}%',
            'Avg Rate',
            AppColors.cardWhite,
            AppColors.primaryText,
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
          CircleAvatar(
            backgroundColor: AppColors.background,
            child: Text(
              (member['name'] as String).substring(0, 1),
              style: AppTextStyles.bodyBold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        member['name'],
                        style: AppTextStyles.bodyBold,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                Text(member['role'], style: AppTextStyles.label),
                const SizedBox(height: 8),
                Row(
                  children: [
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
          _buildMiniChart(member),
        ],
      ),
    );
  }

  Widget _buildMiniChart(Map<String, dynamic> member) {
    final List<double> hours = (member['hours'] as List).cast<double>();
    const double maxDisplayHours = 8.0;
    const double maxBarHeight = 24.0;
    const double minBarHeight = 4.0;

    return SizedBox(
      height: 40, // <-- fixed height to prevent layout errors
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(Icons.circle, color: member['status'], size: 10),
          // No Spacer needed now – spaceBetween will distribute the remaining
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(hours.length, (index) {
              final h = hours[index];
              double barHeight;
              Color barColor;

              if (h <= 0) {
                barHeight = minBarHeight;
                barColor = Colors.grey.shade300;
              } else if (h >= maxDisplayHours) {
                barHeight = maxBarHeight;
                barColor = AppColors.primaryGreen;
              } else {
                barHeight =
                    minBarHeight +
                    (h / maxDisplayHours) * (maxBarHeight - minBarHeight);
                barColor = AppColors.primaryGreen.withOpacity(0.4);
              }

              return Container(
                width: 4,
                height: barHeight,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: barColor,
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
