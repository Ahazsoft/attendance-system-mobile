import 'dart:async';
import 'package:attendance/db/attendance_service.dart';
import 'package:attendance/db/employee_service.dart';
import 'package:attendance/db/settings.dart';
import 'package:attendance/model/user.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import "package:intl/intl.dart";

class EmployeeDashboardScreen extends StatefulWidget {
  final VoidCallback onScanPressed;
  final int id;
  const EmployeeDashboardScreen({
    super.key,
    required this.onScanPressed,
    required this.id,
  });

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Map<String, dynamic>? _todayData;
  Timer? _statsTimer;
  String _workingFor = "0h 0m";
  DateTime? _serverTime;
  DateTime? _serverTimeEat;
  Timer? _serverTimeTimer;
  // Data State Variables
  User? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    _statsTimer?.cancel();
    _serverTimeTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _refreshAllData();
    _statsTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) _calculateWorkingTime();
    });
    // Refresh server time every minute to keep display accurate
    _serverTimeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchServerTime();
    });
  }

  Future<void> _refreshAllData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch all required data points in parallel
      final results = await Future.wait([
        EmployeeService.fetchUserById(widget.id),
        AttendanceService.getTodayStatus(widget.id),
        AttendanceService.getAllAttendance(widget.id),
        _fetchServerTime(),
      ]);

      setState(() {
        _userData = results[0] as User;
        _todayData = results[1] as Map<String, dynamic>;
        _isLoading = false;
        _errorMessage = null;
      });

      _calculateWorkingTime();
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
      // Silently fail – fallback to local time is handled in getters
      debugPrint('Failed to fetch server time: $e');
    }
  }

  void _calculateWorkingTime() {
    if (_todayData?['status'] == 'checked_in' &&
        _todayData?['data'] != null &&
        _serverTime != null) {
      // 1. Parse check-in as UTC
      final DateTime checkInUtc = DateTime.parse(
        _todayData!['data']['checkInTime'],
      );

      // 2. Ensure server time is UTC (CRITICAL)
      final DateTime currentUtc = _serverTime!;

      // 3. Compute difference in UTC
      final Duration diff = currentUtc.difference(checkInUtc);

      // 4. Prevent negative duration (clock sync issues / edge cases)
      if (diff.isNegative) {
        debugPrint('Negative duration detected. Skipping...');
        return;
      }

      debugPrint('Check-in (UTC): $checkInUtc');
      debugPrint('Current (UTC): $currentUtc');
      debugPrint('Working duration: ${diff.inHours}h ${diff.inMinutes % 60}m');

      setState(() {
        _workingFor = "${diff.inHours}h ${diff.inMinutes % 60}m";
      });
    } else {
      setState(() => _workingFor = "0h 0m");
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: false);
    _animation = Tween<double>(begin: 0, end: 100).animate(_controller);
  }

  String getFormattedDate() {
    final now = _serverTime ?? DateTime.now();
    return DateFormat("E, MMM, d, yyyy").format(now);
  }

  String getFormattedTime() {
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

    // Logic for Summary Data
    final bool hasCheckedIn = _todayData?['status'] == "checked_in";
    final bool isCheckedIn =
        (_todayData?['data']?['isCheckedIn'] ?? false) == true;
    final bool isWeekend = _todayData?['isWeekend'] ?? false;

    final String checkInTimeDisplay = hasCheckedIn
        ? _todayData!['data']['checkInTime'] != null
              ? DateFormat.jm().format(
                  DateTime.parse(_todayData!['data']['checkInTime']).toLocal(),
                )
              : "--:--"
        : "--:--";

    final String checkOutTimeDisplay = hasCheckedIn
        ? _todayData!['data']['checkOutTime'] != null
              ? DateFormat.jm().format(
                  DateTime.parse(_todayData!['data']['checkOutTime']).toLocal(),
                )
              : "--:--"
        : "--:--";

    final String statusText = isWeekend
        ? "Weekend"
        : (isCheckedIn ? "Checked In" : "Checked Out");
    final Color statusColor = isWeekend
        ? Colors.blue
        : (isCheckedIn ? AppColors.primaryGreen : AppColors.redLate);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: AppTextStyles.bodyRegular.copyWith(fontSize: 16),
                  ),
                  Text(
                    "${_userData?.firstName ?? "User"} ${_userData?.lastName ?? ""}",
                    style: AppTextStyles.heading1,
                  ),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  _userData?.imageUrl ??
                      "https://randomuser.me/api/portraits/men/20.jpg",
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(getFormattedDate()), Text(getFormattedTime())],
            ),
          ),

          const SizedBox(height: 40),
          const Spacer(),

          // Central Scan Button
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: RipplePainter(_animation.value),
                      size: const Size(210, 210),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    if (isCheckedIn) {
                      _showCheckoutDialog();
                    } else {
                      widget.onScanPressed();
                    }
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: isCheckedIn
                          ? Colors.redAccent
                          : AppColors.primaryText,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isCheckedIn
                                      ? Colors.redAccent
                                      : AppColors.primaryText)
                                  .withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCheckedIn
                              ? PhosphorIcons.signOut()
                              : PhosphorIcons.qrCode(),
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          const SizedBox(height: 40),

          Text(
            "TODAY'S SUMMARY",
            style: AppTextStyles.label.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),

          // Summary Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard(
                'Check In Time',
                checkInTimeDisplay,
                PhosphorIconsBold.timer,
              ),
              _buildSummaryCard(
                'Working for',
                _workingFor,
                PhosphorIconsBold.hourglassHigh,
              ),
              _buildSummaryCard(
                'Check Out Time',
                checkOutTimeDisplay,
                PhosphorIconsBold.timer,
              ),
              _buildSummaryCard(
                'Status',
                statusText,
                PhosphorIconsBold.presentationChart,
                textColor: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon, {
    Color bgColor = AppColors.cardWhite,
    Color textColor = AppColors.primaryText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryText.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: textColor == AppColors.primaryText
                    ? AppColors.greyText
                    : textColor,
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(
              color: textColor,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text("Check Out", style: AppTextStyles.heading2),

                const SizedBox(height: 8),

                // Message
                Text(
                  "Are you ready to check out?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyRegular,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // Confirm Checkout
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          try {
                            final attendanceId = _todayData?['data']?['id'];

                            if (attendanceId == null) {
                              throw Exception("Attendance ID not found");
                            }

                            await AttendanceService.checkOut(attendanceId);

                            // Refresh all data after checkout
                            await _refreshAllData();
                          } catch (e) {
                            debugPrint("Checkout error: $e");

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Checkout failed")),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Check Out",
                          style: TextStyle(color: AppColors.background),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: AppColors.primaryText),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //
}

class RipplePainter extends CustomPainter {
  final double radius;
  RipplePainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppColors.primaryText.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
