import 'dart:convert';
import 'package:attendance/db/attendance_service.dart';
import 'package:attendance/pages/skeleton/history_skeleton.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class HistoryScreen extends StatefulWidget {
  final String id;
  const HistoryScreen({super.key, required this.id});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isThisWeek = true;
  List<dynamic> allAttendance = []; // daily‑grouped data
  bool isLoading = true;
  String? error;
  DateTime? _serverTimeEat;

  static const String _cacheKey = 'history_cache_';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ------------------------------------------------------------
  //  SMART LOADER
  // ------------------------------------------------------------
  Future<void> _loadData() async {
    final todayEatStr = _todayEatDateString();

    // 1. Try cache
    final cached = await _readCache();
    if (cached != null && cached['date'] == todayEatStr) {
      // Cache is from today – use it and skip the network call
      if (mounted) {
        setState(() {
          allAttendance = groupByDay(cached['data'] as List<dynamic>);
          isLoading = false;
        });
      }
      return;
    }

    // 2. Cache missing or stale – fetch fresh data
    await _fetchFreshData();
  }

  // ------------------------------------------------------------
  //  CACHE HELPERS
  // ------------------------------------------------------------
  Future<Map<String, dynamic>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey + widget.id);
      if (json != null) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  Future<void> _writeCache(String date, List<dynamic> rawData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({'date': date, 'data': rawData});
      await prefs.setString(_cacheKey + widget.id, payload);
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  // Today in EAT as "YYYY-MM-DD"
  String _todayEatDateString() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------
  //  DATA FETCHING & GROUPING
  // ------------------------------------------------------------
  Future<void> _fetchFreshData() async {
    try {
      final rawData = await AttendanceService.getAllAttendance(widget.id);
      if (mounted) {
        setState(() {
          allAttendance = groupByDay(rawData);
          isLoading = false;
          error = null;
        });
      }
      // Always update cache with today’s date after a successful fetch
      _writeCache(_todayEatDateString(), rawData);
    } catch (e) {
      if (mounted) {
        if (allAttendance.isEmpty) error = e.toString();
        isLoading = false;
      }
    }
  }

  // Group raw records by EAT date → daily summaries
  List<Map<String, dynamic>> groupByDay(List<dynamic> rawRecords) {
    final Map<String, List<dynamic>> grouped = {};
    for (final record in rawRecords) {
      final checkInUtc = DateTime.parse(record['checkInTime']);
      final eatDate = checkInUtc.add(const Duration(hours: 3));
      final dateKey =
          '${eatDate.year}-${eatDate.month.toString().padLeft(2, '0')}-${eatDate.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    return grouped.entries.map((entry) {
      final records = entry.value;
      final firstCheckIn = DateTime.parse(records.first['checkInTime']);
      DateTime? lastCheckOut;
      for (final r in records) {
        if (r['checkOutTime'] != null) {
          final out = DateTime.parse(r['checkOutTime']);
          if (lastCheckOut == null || out.isAfter(lastCheckOut)) {
            lastCheckOut = out;
          }
        }
      }

      double totalHours = 0;
      for (final r in records) {
        final hours = r['workingHours'];
        if (hours != null)
          totalHours += (hours is int ? hours.toDouble() : hours);
      }

      return {
        'date': entry.key,
        'checkInTime': firstCheckIn.toIso8601String(),
        'checkOutTime': lastCheckOut?.toIso8601String(),
        'workingHours': double.parse(totalHours.toStringAsFixed(2)),
        'isLate': records.any((r) => r['isLate'] == true),
        'numberOfCheckins': records.length,
        'isCheckedIn': records.last['isCheckedIn'] ?? false,
      };
    }).toList()..sort((a, b) => a['date'].compareTo(b['date']));
  }

  // ------------------------------------------------------------
  //  COMPUTED HELPERS
  // ------------------------------------------------------------
  DateTime get currentEat =>
      _serverTimeEat ?? DateTime.now().toUtc().add(const Duration(hours: 3));

  List<dynamic> get filteredAttendance {
    final now = currentEat;
    if (isThisWeek) {
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      return allAttendance.where((record) {
        final dateParts = record['date'].split('-');
        final recDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
        return recDate.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            recDate.isBefore(endOfWeek);
      }).toList();
    } else {
      return allAttendance;
    }
  }

  Map<String, dynamic> get stats {
    final records = filteredAttendance;
    final daysPresent = records.length;
    final totalHours = records.fold<double>(0.0, (sum, r) {
      final hours = r['workingHours'];
      return sum + (hours ?? 0.0);
    });
    final lateDays = records.where((r) => r['isLate'] == true).length;
    return {
      'days': daysPresent.toString(),
      'hours': '${totalHours.toStringAsFixed(2)}h',
      'late': lateDays.toString(),
    };
  }

  // ------------------------------------------------------------
  //  FORMATTING HELPERS
  // ------------------------------------------------------------
  String _formatDate(String dateKey, String checkInIso) {
    final nowEat = currentEat;
    final todayEat = DateTime(nowEat.year, nowEat.month, nowEat.day);
    final recordEat = DateTime.parse(checkInIso).add(const Duration(hours: 3));
    final recordDateEat = DateTime(
      recordEat.year,
      recordEat.month,
      recordEat.day,
    );
    if (recordDateEat == todayEat) return 'Today';
    return DateFormat('MMM d').format(recordEat);
  }

  String _formatDay(String checkInIso) {
    final recordEat = DateTime.parse(checkInIso).add(const Duration(hours: 3));
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

  // ------------------------------------------------------------
  //  BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading && allAttendance.isEmpty) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: const HistorySkeleton(),
      );
    }
    if (error != null && allAttendance.isEmpty) {
      return Center(child: Text('Error: $error'));
    }

    final records = filteredAttendance;
    final stat = stats;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: RefreshIndicator(
          onRefresh: _fetchFreshData,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Text('My History', style: AppTextStyles.heading1),
                        Text(
                          'Your attendance roots',
                          style: AppTextStyles.bodyRegular.copyWith(
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _fetchFreshData,
                      icon: Icon(Icons.refresh),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.cardWhite,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Toggle Buttons (no re‑fetch, just filter)
                Row(
                  children: [
                    _buildToggleBtn('This Week', isThisWeek, () {
                      setState(() => isThisWeek = true);
                    }),
                    const SizedBox(width: 8),
                    _buildToggleBtn('This Month', !isThisWeek, () {
                      setState(() => isThisWeek = false);
                    }),
                  ],
                ),

                const SizedBox(height: 24),

                // Stat Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        stat['days']!,
                        'Days Present',
                        AppColors.cardWhite,
                        AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        stat['hours']!,
                        'Total Hours',
                        AppColors.lightGreen,
                        AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        stat['late']!,
                        'Late Days',
                        AppColors.cardWhite,
                        AppColors.redLate,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                records.isEmpty
                    ? SizedBox(
                        height: screenHeight * 0.5,
                        child: Center(
                          child: Text(
                            'No attendance records for this period',
                            style: AppTextStyles.bodyRegular,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: screenHeight * 0.55,
                        child: ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            final checkInIso = record['checkInTime'] as String;
                            final checkOutIso =
                                record['checkOutTime'] as String?;
                            final workingHours = (record['workingHours'] as num)
                                .toDouble();
                            final isLate = record['isLate'] as bool;
                            final nowEat = currentEat;
                            final checkInUtc = DateTime.parse(checkInIso);
                            final checkInEat = checkInUtc.add(
                              const Duration(hours: 3),
                            );
                            final isToday =
                                checkInEat.year == nowEat.year &&
                                checkInEat.month == nowEat.month &&
                                checkInEat.day == nowEat.day;

                            return _buildTimelineItem(
                              _formatDate(record['date'], checkInIso),
                              _formatDay(checkInIso),
                              _formatTime(checkInUtc),
                              _formatTime(
                                checkOutIso != null
                                    ? DateTime.parse(checkOutIso)
                                    : null,
                              ),
                              _formatDuration(workingHours),
                              isLate: isLate,
                              isToday: isToday,
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  //  WIDGET BUILDERS
  // ------------------------------------------------------------
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
