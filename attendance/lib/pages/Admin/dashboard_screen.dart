import 'dart:async';
import 'package:attendance/db/attendance_service.dart';
import 'package:attendance/db/employee_service.dart';
import 'package:attendance/db/settings.dart';
import 'package:attendance/model/user.dart';
import 'package:flutter/material.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Data
  List<User> _users = [];
  List<dynamic> _attendance = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Server time
  DateTime? _serverTime;
  DateTime? _serverTimeEat;
  Timer? _serverTimeTimer;

  // Computed stats
  int _presentToday = 0;
  double _weekAttendancePercent = 0.0;
  double _avgHoursToday = 0.0;
  int _lateToday = 0;
  List<double> _weeklyPresence = [0, 0, 0, 0, 0];
  double _ontimePercent = 0.0;
  double _latePercent = 0.0;
  double _absentPercent = 0.0;

  // Refresh timer
  Timer? _refreshTimer;

  // Constants
  static const int _expectedStartHour = 9; // 9:00 AM considered on-time
  static const int _expectedStartMinute = 0;

  @override
  void initState() {
    super.initState();
    _refreshAllData();
    // Refresh every minute to keep "today" stats current
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _refreshAllData();
    });
    // Sync server time every minute
    _serverTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchServerTime();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _serverTimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAllData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        EmployeeService.fetchAllUsers(),
        AttendanceService.getAllEmpAttendance(),
        _fetchServerTime(),
      ]);

      setState(() {
        _users = results[0] as List<User>;
        _attendance = results[1] as List<dynamic>;
        _isLoading = false;
        _errorMessage = null;
      });

      _computeStatistics();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchServerTime() async {
    try {
      final serverTimeUtc = await SettingsService.getServerTime();
      final serverTimeEat = serverTimeUtc.add(const Duration(hours: 3));
      if (mounted) {
        setState(() {
          _serverTime = serverTimeUtc;
          _serverTimeEat = serverTimeEat;
        });
      }
    } catch (e) {
      // debugPrint('Failed to fetch server time: $e');
      // silently fail
    }
  }

  void _computeStatistics() {
    if (_users.isEmpty || _attendance.isEmpty) {
      setState(() {
        _presentToday = 0;
        _weekAttendancePercent = 0;
        _avgHoursToday = 0;
        _lateToday = 0;
        _weeklyPresence = [0, 0, 0, 0, 0];
        _ontimePercent = 0;
        _latePercent = 0;
        _absentPercent = 0;
      });
      return;
    }

    final now = _serverTime ?? DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);

    // Today's attendance
    final todayAttendance = _attendance.where((record) {
      final checkIn = DateTime.parse(record['checkInTime']);
      return checkIn.year == today.year &&
          checkIn.month == today.month &&
          checkIn.day == today.day;
    }).toList();

    // Present today count (use employeeId)
    final presentEmployeeIds = todayAttendance
        .map((r) => r['employeeId'])
        .toSet();
    _presentToday = presentEmployeeIds.length;

    // Late today (check-in after 9:00 AM EAT)
    final expectedCheckIn = today.add(
      const Duration(
        hours: 3 + _expectedStartHour,
        minutes: _expectedStartMinute,
      ),
    );
    _lateToday = todayAttendance.where((record) {
      final checkIn = DateTime.parse(record['checkInTime']);
      return checkIn.isAfter(expectedCheckIn);
    }).length;

    // Avg hours today
    double totalHours = 0;
    int checkedOutCount = 0;
    for (var record in todayAttendance) {
      if (record['checkOutTime'] != null) {
        final checkIn = DateTime.parse(record['checkInTime']);
        final checkOut = DateTime.parse(record['checkOutTime']);
        totalHours += checkOut.difference(checkIn).inMinutes / 60.0;
        checkedOutCount++;
      }
    }
    _avgHoursToday = checkedOutCount > 0 ? totalHours / checkedOutCount : 0.0;

    // Week attendance percentage
    final startOfWeek = _getStartOfWeek(today);
    double totalWorkdays = 0;
    double daysPresent = 0;
    for (int i = 0; i < 5; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (day.isAfter(today)) break;
      totalWorkdays++;
      final dayAttendance = _attendance.where((record) {
        final checkIn = DateTime.parse(record['checkInTime']);
        return checkIn.year == day.year &&
            checkIn.month == day.month &&
            checkIn.day == day.day;
      });
      if (dayAttendance.isNotEmpty) daysPresent++;
    }
    _weekAttendancePercent = totalWorkdays > 0
        ? (daysPresent / totalWorkdays) * 100
        : 0.0;

    // Weekly presence (unique employees per day)
    for (int i = 0; i < 5; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (day.isAfter(today)) {
        _weeklyPresence[i] = 0;
        continue;
      }
      final dayEmployeeIds = _attendance
          .where((record) {
            final checkIn = DateTime.parse(record['checkInTime']);
            return checkIn.year == day.year &&
                checkIn.month == day.month &&
                checkIn.day == day.day;
          })
          .map((r) => r['employeeId'])
          .toSet();
      _weeklyPresence[i] = dayEmployeeIds.length.toDouble();
    }

    // Punctuality breakdown
    int ontimeCount = 0;
    int lateCount = 0;
    int absentCount = 0;
    for (int i = 0; i < 5; i++) {
      final day = startOfWeek.add(Duration(days: i));
      if (day.isAfter(today)) continue;
      final dayExpectedCheckIn = day.add(
        const Duration(
          hours: 3 + _expectedStartHour,
          minutes: _expectedStartMinute,
        ),
      );
      final dayAttendance = _attendance.where((record) {
        final checkIn = DateTime.parse(record['checkInTime']);
        return checkIn.year == day.year &&
            checkIn.month == day.month &&
            checkIn.day == day.day;
      }).toList();

      final presentIds = dayAttendance.map((r) => r['employeeId']).toSet();
      final expectedPresent = _users.length;
      absentCount += (expectedPresent - presentIds.length);

      for (var record in dayAttendance) {
        final checkIn = DateTime.parse(record['checkInTime']);
        if (checkIn.isBefore(dayExpectedCheckIn) ||
            checkIn.isAtSameMomentAs(dayExpectedCheckIn)) {
          ontimeCount++;
        } else {
          lateCount++;
        }
      }
    }

    final totalRecords = ontimeCount + lateCount + absentCount;
    if (totalRecords > 0) {
      _ontimePercent = (ontimeCount / totalRecords) * 100;
      _latePercent = (lateCount / totalRecords) * 100;
      _absentPercent = (absentCount / totalRecords) * 100;
    } else {
      _ontimePercent = _latePercent = _absentPercent = 0;
    }

    setState(() {}); // Refresh UI with computed values
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Monday = 1, Sunday = 7 in DateTime.weekday
    int daysSinceMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysSinceMonday));
  }

  String _getFormattedDate() {
    final now = _serverTime ?? DateTime.now();
    return DateFormat("E, MMM d, yyyy").format(now);
  }

  String _getFormattedTime() {
    final now = _serverTimeEat ?? DateTime.now();
    return DateFormat("hh:mm a").format(now);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryText),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            Text("Something went wrong", style: AppTextStyles.bodyBold),
            TextButton(onPressed: _refreshAllData, child: const Text("Retry")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date/time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.greyText,
                      ),
                    ),
                    const Text('Howdy, Admin', style: AppTextStyles.heading1),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getFormattedDate(),
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 15),
                    ),
                    Text(
                      _getFormattedTime(),
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Weekly Presence Chart
            _buildWeeklyPresenceCard(),
            const SizedBox(height: 24),

            // Punctuality Breakdown
            _buildPunctualityCard(),
            const SizedBox(height: 24),

            // Team Hours Trend
            _buildTrendCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Present Today',
                value: '$_presentToday/${_users.length}',
                icon: PhosphorIconsBold.users,
                iconColor: AppColors.primaryGreen,
                bgColor: AppColors.lightGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Week Attendance',
                value: '${_weekAttendancePercent.toStringAsFixed(0)}%',
                icon: PhosphorIconsBold.trendUp,
                iconColor: AppColors.primaryGreen,
                bgColor: AppColors.cardWhite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Avg Hours Today',
                value: '${_avgHoursToday.toStringAsFixed(1)}h',
                icon: PhosphorIconsBold.clock,
                iconColor: Colors.orange,
                bgColor: AppColors.cardWhite,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Late Today',
                value: '$_lateToday',
                icon: PhosphorIconsBold.warning,
                iconColor: AppColors.redLate,
                bgColor: AppColors.lightRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.label),
        ],
      ),
    );
  }

  Widget _buildWeeklyPresenceCard() {
    final maxY =
        _weeklyPresence.reduce((a, b) => a > b ? a : b).ceilToDouble() + 2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Presence', style: AppTextStyles.bodyBold),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY > 10 ? 2 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY > 10 ? 2 : 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTextStyles.label,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[value.toInt()],
                              style: AppTextStyles.label,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  _weeklyPresence.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyPresence[index],
                        width: 40,
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunctualityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Punctuality Breakdown', style: AppTextStyles.bodyBold),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: [
                      PieChartSectionData(
                        value: _ontimePercent,
                        color: AppColors.primaryGreen,
                        title: "${_ontimePercent.toStringAsFixed(0)}%",
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: _latePercent,
                        color: AppColors.redLate,
                        title: "${_latePercent.toStringAsFixed(0)}%",
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: _absentPercent,
                        color: AppColors.greyText,
                        title: "${_absentPercent.toStringAsFixed(0)}%",
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(
                      'On Time',
                      '${_ontimePercent.toStringAsFixed(0)}%',
                      AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Late',
                      '${_latePercent.toStringAsFixed(0)}%',
                      AppColors.redLate,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Absent',
                      '${_absentPercent.toStringAsFixed(0)}%',
                      AppColors.greyText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyRegular.copyWith(color: AppColors.greyText),
        ),
        const Spacer(),
        Text(percentage, style: AppTextStyles.bodyBold),
      ],
    );
  }

  Widget _buildTrendCard() {
    // Team hours trend (average hours per day for the week)
    final startOfWeek = _getStartOfWeek(_serverTime ?? DateTime.now().toUtc());
    List<FlSpot> spots = [];
    for (int i = 0; i < 5; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayAttendance = _attendance.where((record) {
        final checkIn = DateTime.parse(record['checkInTime']);
        return checkIn.year == day.year &&
            checkIn.month == day.month &&
            checkIn.day == day.day;
      }).toList();

      double totalHours = 0;
      int checkedOutCount = 0;
      for (var record in dayAttendance) {
        if (record['checkOutTime'] != null) {
          final checkIn = DateTime.parse(record['checkInTime']);
          final checkOut = DateTime.parse(record['checkOutTime']);
          totalHours += checkOut.difference(checkIn).inMinutes / 60.0;
          checkedOutCount++;
        }
      }
      final avgHours = checkedOutCount > 0 ? totalHours / checkedOutCount : 0.0;
      spots.add(FlSpot(i.toDouble(), avgHours));
    }

    final maxY =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b).ceilToDouble() +
        2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Team Hours Trend', style: AppTextStyles.bodyBold),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY > 10 ? 2 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.10),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.10),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY > 10 ? 2 : 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTextStyles.label,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
                        final index = value.toInt();
                        if (index >= 0 && index < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[index],
                              style: AppTextStyles.label,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryGreen,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryGreen.withOpacity(0.15),
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

// import 'package:attendance/db/attendance_service.dart';
// import 'package:attendance/db/employee_service.dart';
// import 'package:attendance/model/user.dart';
// import 'package:flutter/material.dart';
// import 'package:attendance/theme/appTheme.dart'; // Adjust import path as needed
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:fl_chart/fl_chart.dart';

// class AdminDashboardScreen extends StatefulWidget {
//   const AdminDashboardScreen({super.key});

//   @override
//   State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
// }

// class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
//   List<User> users = [];
//   List<dynamic> attendance = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _reloadData();
//   }

//   Future<void> _reloadData() async {
//     final results = await Future.wait([
//       EmployeeService.fetchAllUsers(),
//       AttendanceService.getAllEmpAttendance(),
//     ]);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Admin Dashboard',
//             style: AppTextStyles.bodyRegular.copyWith(
//               color: AppColors.greyText,
//             ),
//           ),
//           const Text('Howdy, Admin', style: AppTextStyles.heading1),
//           const SizedBox(height: 24),

//           // 1. Stats Grid
//           _buildStatsGrid(),
//           const SizedBox(height: 24),

//           // 2. Weekly Presence Chart
//           _buildWeeklyPresenceCard(),
//           const SizedBox(height: 24),

//           // 3. Punctuality Breakdown
//           _buildPunctualityCard(ontime: 72, late: 18, absent: 10),
//           const SizedBox(height: 24),

//           // 4. Team Hours Trend Placeholder
//           _buildTrendCard(),

//           const SizedBox(height: 24), // Bottom padding
//         ],
//       ),
//     );
//   }

//   Widget _buildStatsGrid() {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _buildStatCard(
//                 title: 'Present Today',
//                 value: '8/10',
//                 icon: PhosphorIconsBold.users,
//                 iconColor: AppColors.primaryGreen,
//                 bgColor: AppColors.lightGreen,
//               ),
//             ),
//             const SizedBox(width: 16),

//             Expanded(
//               child: _buildStatCard(
//                 title: 'Week Attendance',
//                 value: '92%',
//                 icon: PhosphorIconsBold.trendUp,
//                 iconColor: AppColors.primaryGreen,
//                 bgColor: AppColors.cardWhite,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         Row(
//           children: [
//             Expanded(
//               child: _buildStatCard(
//                 title: 'Avg Hours Today',
//                 value: '8.2h',
//                 icon: PhosphorIconsBold.clock,
//                 iconColor: Colors.orange,
//                 bgColor: AppColors.cardWhite,
//               ),
//             ),
//             const SizedBox(width: 16),

//             Expanded(
//               child: _buildStatCard(
//                 title: 'Late Today',
//                 value: '2',
//                 icon: PhosphorIconsBold.warning,
//                 iconColor: AppColors.redLate,
//                 bgColor: AppColors.lightRed,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color iconColor,
//     required Color bgColor,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: iconColor, size: 24),
//           const SizedBox(height: 12),
//           Text(value, style: AppTextStyles.heading2),
//           const SizedBox(height: 4),
//           Text(title, style: AppTextStyles.label),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeeklyPresenceCard() {
//     final weeklyPresence = [7, 9, 6, 8, 5];

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppColors.cardWhite,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.black.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Weekly Presence', style: AppTextStyles.bodyBold),
//           const SizedBox(height: 24),

//           SizedBox(
//             height: 200,
//             child: BarChart(
//               BarChartData(
//                 alignment: BarChartAlignment.spaceAround,
//                 maxY: 10,

//                 gridData: FlGridData(
//                   show: true,
//                   horizontalInterval: 2,
//                   getDrawingHorizontalLine: (value) {
//                     return FlLine(
//                       color: Colors.grey.withOpacity(0.15),
//                       strokeWidth: 1,
//                     );
//                   },
//                 ),

//                 borderData: FlBorderData(show: false),

//                 titlesData: FlTitlesData(
//                   topTitles: AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   rightTitles: AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),

//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       interval: 2,
//                       reservedSize: 28,
//                       getTitlesWidget: (value, meta) {
//                         return Text(
//                           value.toInt().toString(),
//                           style: AppTextStyles.label,
//                         );
//                       },
//                     ),
//                   ),

//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) {
//                         const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

//                         if (value.toInt() >= 0 && value.toInt() < days.length) {
//                           return Padding(
//                             padding: const EdgeInsets.only(top: 6),
//                             child: Text(
//                               days[value.toInt()],
//                               style: AppTextStyles.label,
//                             ),
//                           );
//                         }

//                         return const SizedBox();
//                       },
//                     ),
//                   ),
//                 ),

//                 barGroups: List.generate(
//                   weeklyPresence.length,
//                   (index) => BarChartGroupData(
//                     x: index,
//                     barRods: [
//                       BarChartRodData(
//                         toY: weeklyPresence[index].toDouble(),
//                         width: 40,
//                         color: AppColors.primaryGreen,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPunctualityCard({
//     required double ontime,
//     required double late,
//     required double absent,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppColors.cardWhite,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.black.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Punctuality Breakdown', style: AppTextStyles.bodyBold),
//           const SizedBox(height: 24),
//           Row(
//             children: [
//               // Placeholder for a donut chart
//               SizedBox(
//                 width: 120,
//                 height: 120,
//                 child: PieChart(
//                   PieChartData(
//                     sectionsSpace: 2,
//                     centerSpaceRadius: 30,

//                     sections: [
//                       PieChartSectionData(
//                         value: ontime,
//                         color: AppColors.primaryGreen,
//                         title: "${ontime.toStringAsFixed(0)}%",
//                         radius: 40,
//                         titleStyle: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       PieChartSectionData(
//                         value: late,
//                         color: AppColors.redLate,
//                         title: "${late.toStringAsFixed(0)}%",
//                         radius: 40,
//                         titleStyle: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       PieChartSectionData(
//                         value: absent,
//                         color: AppColors.greyText,
//                         title: "${absent.toStringAsFixed(0)}%",
//                         radius: 40,
//                         titleStyle: const TextStyle(
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 32),
//               // Legend
//               Expanded(
//                 child: Column(
//                   children: [
//                     _buildLegendItem('On Time', '72%', AppColors.primaryGreen),
//                     const SizedBox(height: 12),
//                     _buildLegendItem('Late', '18%', AppColors.redLate),
//                     const SizedBox(height: 12),
//                     _buildLegendItem('Absent', '10%', AppColors.greyText),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLegendItem(String label, String percentage, Color color) {
//     return Row(
//       children: [
//         Container(
//           width: 10,
//           height: 10,
//           decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           label,
//           style: AppTextStyles.bodyRegular.copyWith(color: AppColors.greyText),
//         ),
//         const Spacer(),
//         Text(percentage, style: AppTextStyles.bodyBold),
//       ],
//     );
//   }

//   Widget _buildTrendCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: AppColors.cardWhite,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.black.withOpacity(0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Team Hours Trend', style: AppTextStyles.bodyBold),
//           const SizedBox(height: 24),

//           SizedBox(
//             height: 180,
//             child: LineChart(
//               LineChartData(
//                 gridData: FlGridData(
//                   show: true,
//                   drawVerticalLine: true,
//                   horizontalInterval: 2,
//                   verticalInterval: 1,
//                   getDrawingHorizontalLine: (value) {
//                     return FlLine(
//                       color: Colors.grey.withOpacity(0.10),
//                       strokeWidth: 1,
//                     );
//                   },
//                   getDrawingVerticalLine: (value) {
//                     return FlLine(
//                       color: Colors.grey.withOpacity(0.10),
//                       strokeWidth: 1,
//                     );
//                   },
//                 ),

//                 titlesData: FlTitlesData(
//                   topTitles: AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),
//                   rightTitles: AxisTitles(
//                     sideTitles: SideTitles(showTitles: false),
//                   ),

//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       interval: 2,
//                       reservedSize: 30,
//                       getTitlesWidget: (value, meta) {
//                         return Text(
//                           value.toInt().toString(),
//                           style: AppTextStyles.label,
//                         );
//                       },
//                     ),
//                   ),

//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       interval: 1,
//                       getTitlesWidget: (value, meta) {
//                         switch (value.toInt()) {
//                           case 0:
//                             return const Text('Mon');
//                           case 1:
//                             return const Text('Tue');
//                           case 2:
//                             return const Text('Wed');
//                           case 3:
//                             return const Text('Thu');
//                           case 4:
//                             return const Text('Fri');
//                         }
//                         return const Text('');
//                       },
//                     ),
//                   ),
//                 ),

//                 borderData: FlBorderData(show: false),

//                 minX: 0,
//                 maxX: 4,
//                 minY: 0,
//                 maxY: 10,

//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: const [
//                       FlSpot(0, 7),
//                       FlSpot(1, 8),
//                       FlSpot(2, 6),
//                       FlSpot(3, 9),
//                       FlSpot(4, 7),
//                     ],

//                     isCurved: true,
//                     color: AppColors.primaryGreen,
//                     barWidth: 3,

//                     dotData: FlDotData(show: true),

//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: AppColors.primaryGreen.withOpacity(0.15),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   _fetchServerTime() {}

//   // keep the closing } away
// }
