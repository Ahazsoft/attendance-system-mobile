import 'package:attendance/db/attendance_service.dart';
import 'package:attendance/db/settings.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final int id;
  const HistoryScreen({super.key, required this.id});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isThisWeek = true;
  List<dynamic> allAttendance = [];
  bool isLoading = true;
  String? error;
  // DateTime? _serverTimeUtc;
  DateTime? _serverTimeEat;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch server time and attendance in parallel
      await Future.wait([_fetchServerTime(), _fetchAttendance()]);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchServerTime() async {
    try {
      final serverTimeUtc = await SettingsService.getServerTime();
      final serverTimeEat = serverTimeUtc.add(const Duration(hours: 3));
      if (mounted) {
        setState(() {
          _serverTimeEat = serverTimeEat;
        });
      }
    } catch (e) {
      // If server time fetch fails, fallback to local device time
      debugPrint('Failed to fetch server time: $e');
      final now = DateTime.now();
      if (mounted) {
        setState(() {
          _serverTimeEat = now.toUtc().add(const Duration(hours: 3));
        });
      }
    }
  }

  Future<void> _fetchAttendance() async {
    final data = await AttendanceService.getAllAttendance(widget.id);
    if (mounted) {
      setState(() {
        allAttendance = data;
      });
    }
  }

  // Get reference current time in EAT (server or fallback)
  DateTime get currentEat {
    return _serverTimeEat ??
        DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  // Filter attendance based on current toggle
  List<dynamic> get filteredAttendance {
    final now = currentEat;
    if (isThisWeek) {
      // Get start of week (Monday) in EAT
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      return allAttendance.where((record) {
        // Convert record's UTC check-in to EAT for comparison
        final checkInUtc = DateTime.parse(record['checkInTime']);
        final checkInEat = checkInUtc.add(const Duration(hours: 3));
        return checkInEat.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            checkInEat.isBefore(endOfWeek);
      }).toList();
    } else {
      // Current month in EAT
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return allAttendance.where((record) {
        final checkInUtc = DateTime.parse(record['checkInTime']);
        final checkInEat = checkInUtc.add(const Duration(hours: 3));
        return checkInEat.isAfter(
              startOfMonth.subtract(const Duration(seconds: 1)),
            ) &&
            checkInEat.isBefore(endOfMonth.add(const Duration(seconds: 1)));
      }).toList();
    }
  }

  // Calculate stats for the filtered period
  Map<String, dynamic> get stats {
    final records = filteredAttendance;
    final daysPresent = records.length;
    final totalHours = records.fold<double>(0.0, (sum, r) {
      final hours = r['workingHours'];
      if (hours == null) return sum;
      return sum + (hours is int ? hours.toDouble() : hours as double);
    });
    final lateDays = records.where((r) => r['isLate'] == true).length;
    return {
      'days': daysPresent.toString(),
      'hours': '${totalHours.toStringAsFixed(2)}h',
      'late': lateDays.toString(),
    };
  }

  String _formatDate(DateTime checkInUtc) {
    final nowEat = currentEat;
    final todayEat = DateTime(nowEat.year, nowEat.month, nowEat.day);
    final recordEat = checkInUtc.add(const Duration(hours: 3));
    final recordDateEat = DateTime(
      recordEat.year,
      recordEat.month,
      recordEat.day,
    );
    if (recordDateEat == todayEat) return 'Today';
    return DateFormat('MMM d').format(recordEat);
  }

  String _formatDay(DateTime checkInUtc) {
    final recordEat = checkInUtc.add(const Duration(hours: 3));
    return DateFormat('EEE').format(recordEat);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final eat = dateTime.add(const Duration(hours: 3));
    return DateFormat('h:mm a').format(eat);
  }

  String _formatDuration(double? hours) {
    if (hours == null) return '--';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    final records = filteredAttendance;
    final stat = stats;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My History', style: AppTextStyles.heading1),
          Text(
            'Your attendance roots',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.greyText,
            ),
          ),
          const SizedBox(height: 24),

          // Toggle Buttons
          Row(
            children: [
              _buildToggleBtn('This Week', isThisWeek, () {
                setState(() {
                  isThisWeek = true;
                });
              }),
              const SizedBox(width: 8),
              _buildToggleBtn('This Month', !isThisWeek, () {
                setState(() {
                  isThisWeek = false;
                });
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Stat Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  stat['days'],
                  'Days Present',
                  AppColors.cardWhite,
                  AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  stat['hours'],
                  'Total Hours',
                  AppColors.lightGreen,
                  AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  stat['late'],
                  'Late Days',
                  AppColors.cardWhite,
                  AppColors.redLate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Timeline List
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Text(
                      'No attendance records for this period',
                      style: AppTextStyles.bodyRegular,
                    ),
                  )
                : ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final checkInUtc = DateTime.parse(record['checkInTime']);
                      final checkOutUtc = record['checkOutTime'] != null
                          ? DateTime.parse(record['checkOutTime'])
                          : null;

                      // Safe conversion: handle both int and double from JSON
                      final rawHours = record['workingHours'];
                      final double? workingHours = rawHours != null
                          ? (rawHours is int
                                ? rawHours.toDouble()
                                : rawHours as double)
                          : null;

                      final isLate = record['isLate'] ?? false;
                      final nowEat = currentEat;
                      final checkInEat = checkInUtc.add(
                        const Duration(hours: 3),
                      );
                      final isToday =
                          checkInEat.year == nowEat.year &&
                          checkInEat.month == nowEat.month &&
                          checkInEat.day == nowEat.day;

                      return _buildTimelineItem(
                        _formatDate(checkInUtc),
                        _formatDay(checkInUtc),
                        _formatTime(checkInUtc),
                        _formatTime(checkOutUtc),
                        _formatDuration(workingHours),
                        isLate: isLate,
                        isToday: isToday,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryText : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: bgColor == AppColors.lightGreen
            ? Border.all(color: AppColors.primaryGreen.withOpacity(0.3))
            : Border.all(color: AppColors.greyText.withOpacity(0.3)),
        boxShadow: bgColor == AppColors.cardWhite
            ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)]
            : [],
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.heading2.copyWith(color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String date,
    String day,
    String inTime,
    String outTime,
    String total, {
    bool isLate = false,
    bool isToday = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primaryGreen
                          : (isLate ? AppColors.redLate : Colors.grey.shade400),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(date, style: AppTextStyles.bodyBold),
                      const SizedBox(width: 8),
                      Text(day, style: AppTextStyles.label),
                      const Spacer(),
                      if (isLate)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightRed,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.redLate.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Late',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.redLate,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.greyText.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.wb_sunny_outlined,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(inTime, style: AppTextStyles.label),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.nightlight_round,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(outTime, style: AppTextStyles.label),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              total,
                              style: AppTextStyles.bodyBold.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
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
