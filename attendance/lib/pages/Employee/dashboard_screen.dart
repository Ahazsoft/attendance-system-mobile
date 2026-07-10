import 'dart:async';
import 'dart:convert';
import 'package:attendance/service/attendance_service.dart';
import 'package:attendance/service/employee_service.dart';
import 'package:attendance/service/settings.dart';
import 'package:attendance/model/user.dart';
import 'package:attendance/pages/skeleton/dashboard_skeleton.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onProfilePressed;
  final String id;
  const EmployeeDashboardScreen({
    super.key,
    required this.onScanPressed,
    required this.onProfilePressed,
    required this.id,
  });

  @override
  State<EmployeeDashboardScreen> createState() =>
      EmployeeDashboardScreenState();
}

class EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Map<String, dynamic>? _todayData;
  Timer? _statsTimer;
  String _workingFor = "0h 0m";
  DateTime? _serverTime;
  DateTime? _serverTimeEat;
  Timer? _serverTimeTimer;
  int _maxCheckins = 3;

  String? fullName;
  String? imageUrl;
  bool _isLoading = true;
  bool isInsideGeofence = false; // only updated at checkout
  String? _errorMessage;

  double centerLat = 8.986273300000001;
  double centerLng = 38.788376000000000;
  double allowedRadius = 150;

  // Cache helpers
  static const String _cacheKeyPrefix = 'dashboard_cache_';
  String get _cacheKey => _cacheKeyPrefix + widget.id;

  String _todayEatDateString() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json != null) return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Dashboard cache read error: $e');
    }
    return null;
  }

  Future<void> _writeCache({
    required User user,
    required Map<String, dynamic> todayData,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'date': _todayEatDateString(),
        'user': user.fullName,
        'userImageUrl': user.imageUrl ?? '',
        'todayData': todayData,
        'settings': settings,
      });
      await prefs.setString(_cacheKey, payload);
    } catch (e) {
      debugPrint('Dashboard cache write error: $e');
    }
  }

  /// Wrap async actions with timing log.
  Future<T> _timeAction<T>(String name, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    try {
      final result = await action();
      sw.stop();
      debugPrint(
        'DashboardPage computation: $name : ${sw.elapsedMilliseconds}ms',
      );
      return result;
    } catch (e) {
      sw.stop();
      debugPrint(
        'DashboardPage computation: $name : failed after ${sw.elapsedMilliseconds}ms',
      );
      rethrow;
    }
  }

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
    _loadData(); // cache-first initial load

    _statsTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) _calculateWorkingTime();
    });
    _serverTimeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchServerTime(); // always fetch server time separately
    });
  }

  // ---------------------------------------------------------------------------
  // Data loading – cache-first then server
  // ---------------------------------------------------------------------------
  Future<void> _loadData() async {
    final cached = await _readCache();
    if (cached != null && cached['date'] == _todayEatDateString()) {
      try {
        setState(() {
          fullName = cached['user'];
          imageUrl = cached['userImageUrl'];
          _todayData = cached['todayData'] as Map<String, dynamic>;
          final settings = cached['settings'] as Map<String, dynamic>;
          allowedRadius = (settings['radius'] as num?)?.toDouble() ?? 150;
          _maxCheckins = (settings['NumberofCheckin'] as num?)?.toInt() ?? 3;
          centerLat =
              double.tryParse(settings['gpsLatitude']?.toString() ?? '') ??
              8.986202255702445;
          centerLng =
              double.tryParse(settings['gpsLongitude']?.toString() ?? '') ??
              38.78797835605372;
          _isLoading = false;
          _errorMessage = null;
        });
        _calculateWorkingTime();
        _fetchServerTime();
        return;
      } catch (e) {
        debugPrint('Cache parse failed, will refresh: $e');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_cacheKey);
      }
    }
    await _forceRefresh();
  }

  /// Always fetches fresh data from server and overwrites cache.
  Future<void> _forceRefresh() async {
    final totalSw = Stopwatch()..start();
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        _timeAction(
          'fetchUserById',
          () => EmployeeService.fetchUserById(widget.id),
        ),
        _timeAction(
          'getTodayStatus',
          () => AttendanceService.getTodayStatus(widget.id),
        ),
        _timeAction('fetchServerTime', () => _fetchServerTimeValue()),
        _timeAction('loadSettings', () => _loadSettingsFromServerValue()),
      ]);

      final user = results[0] as User;
      final todayData = results[1] as Map<String, dynamic>;
      final serverTimeUtc = results[2] as DateTime?;
      final settings = results[3] as Map<String, dynamic>;

      setState(() {
        _todayData = todayData;
        if (serverTimeUtc != null) {
          _serverTime = serverTimeUtc;
          _serverTimeEat = serverTimeUtc.add(const Duration(hours: 3));
        }
        allowedRadius = (settings['radius'] as num?)?.toDouble() ?? 150;
        _maxCheckins = (settings['NumberofCheckin'] as num?)?.toInt() ?? 3;
        centerLat =
            double.tryParse(settings['gpsLatitude']?.toString() ?? '') ??
            8.986202255702445;
        centerLng =
            double.tryParse(settings['gpsLongitude']?.toString() ?? '') ??
            38.78797835605372;
        _isLoading = false;
        _errorMessage = null;
      });

      _calculateWorkingTime();
      _writeCache(user: user, todayData: todayData, settings: settings);
    } catch (e) {
      debugPrint("Dashboard force refresh error: $e");
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } finally {
      totalSw.stop();
      debugPrint(
        'DashboardPage: force refresh total: ${totalSw.elapsedMilliseconds}ms',
      );
    }
  }

  /// Public method to be called after check‑in/check‑out actions.
  void forceRefresh() {
    _forceRefresh();
  }

  // ---------------------------------------------------------------------------
  // Isolated data-fetching helpers
  // ---------------------------------------------------------------------------
  Future<DateTime?> _fetchServerTimeValue() async {
    try {
      return await SettingsService.getServerTime();
    } catch (e) {
      debugPrint('Failed to fetch server time: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadSettingsFromServerValue() async {
    try {
      return await SettingsService.getSettings();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      // Return default settings if fetch fails
      return {
        'radius': 150,
        'NumberofCheckin': 3,
        'gpsLatitude': '8.986202255702445',
        'gpsLongitude': '38.78797835605372',
      };
    }
  }

  Future<void> _fetchServerTime() async {
    final time = await _fetchServerTimeValue();
    if (mounted && time != null) {
      setState(() {
        _serverTime = time;
        _serverTimeEat = time.add(const Duration(hours: 3));
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers for attendance data
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> get _todayAttendances {
    final data = _todayData?['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Map<String, dynamic>? get _activeAttendance {
    for (var entry in _todayAttendances) {
      if (entry['isCheckedIn'] == true) return entry;
    }
    return null;
  }

  Map<String, dynamic>? get _inActiveAttendance =>
      _activeAttendance; // alias, kept for clarity

  int get _todayCheckinCount => _todayAttendances.length;

  bool get _canCheckIn =>
      _activeAttendance == null && _todayCheckinCount < _maxCheckins;

  // ---------------------------------------------------------------------------
  // Geolocation (only called at checkout time)
  // ---------------------------------------------------------------------------
  Future<bool> _checkLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      double distance = Geolocator.distanceBetween(
        centerLat,
        centerLng,
        position.latitude,
        position.longitude,
      );
      return distance <= allowedRadius;
    } catch (e) {
      debugPrint('Location check failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Working time calculation
  // ---------------------------------------------------------------------------
  void _calculateWorkingTime() {
    final sw = Stopwatch()..start();
    if (_todayData?['status'] != 'checked_in' || _serverTime == null) {
      setState(() => _workingFor = "0h 0m");
      sw.stop();
      debugPrint(
        '_calculateWorkingTime (no data): ${sw.elapsedMilliseconds}ms',
      );
      return;
    }

    final attendances = _todayAttendances;
    if (attendances.isEmpty) {
      setState(() => _workingFor = "0h 0m");
      sw.stop();
      debugPrint('_calculateWorkingTime (empty): ${sw.elapsedMilliseconds}ms');
      return;
    }

    double totalMinutes = 0;
    final nowUtc = _serverTime!;

    for (var att in attendances) {
      final checkIn = DateTime.tryParse(att['checkInTime'] ?? '');
      final checkOut = DateTime.tryParse(att['checkOutTime'] ?? '');
      if (checkIn == null) continue;

      if (checkOut != null) {
        if (att['workingHours'] != null) {
          totalMinutes += (att['workingHours'] as num).toDouble() * 60;
        } else {
          final diff = checkOut.difference(checkIn);
          if (!diff.isNegative) totalMinutes += diff.inMinutes;
        }
      } else {
        final diff = nowUtc.difference(checkIn);
        if (!diff.isNegative) totalMinutes += diff.inMinutes;
      }
    }

    final hours = totalMinutes ~/ 60;
    final minutes = (totalMinutes % 60).round();
    setState(() {
      _workingFor = "${hours}h ${minutes}m";
    });
    sw.stop();
    debugPrint(
      '_calculateWorkingTime (${attendances.length} records): ${sw.elapsedMilliseconds}ms',
    );
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------
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

  String get greeting {
    final now = _serverTimeEat ?? DateTime.now();
    final hour = now.hour;
    if (hour >= 6 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ---------------------------------------------------------------------------
  // Checkout dialog
  // ---------------------------------------------------------------------------
  void _showCheckoutDialog() {
    final active = _inActiveAttendance;
    if (active == null || active['isCheckedIn'] != true) return;

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
                Text("Check Out", style: AppTextStyles.heading2),
                const SizedBox(height: 8),
                Text(
                  "Are you ready to check out?",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyRegular,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            final attendanceId = active['id'];
                            await _timeAction(
                              'checkOut',
                              () => AttendanceService.checkOut(attendanceId),
                            );
                            await _forceRefresh();
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

  // ---------------------------------------------------------------------------
  // Check-in/out tap handler (with on‑demand location for checkout)
  // ---------------------------------------------------------------------------
  Future<void> _handleCheckInOutTap() async {
    final active = _inActiveAttendance;
    final isCheckedIn = active != null;

    if (isCheckedIn) {
      // Only now check geofence
      final inside = await _timeAction('locationCheck', _checkLocation);
      if (!mounted) return;
      if (inside) {
        _showCheckoutDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You're outside the office range. Go back and try again.",
            ),
            backgroundColor: AppColors.redLate,
          ),
        );
      }
    } else if (_canCheckIn) {
      widget.onScanPressed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You've reached the daily limit ($_maxCheckins check-ins).",
          ),
          backgroundColor: AppColors.redLate,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: const EmployeeDashboardSkeleton(),
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
            TextButton(onPressed: _forceRefresh, child: const Text("Retry")),
          ],
        ),
      );
    }

    final attendances = _todayAttendances;
    final active = _inActiveAttendance;
    final bool hasCheckedIn = _todayData?['status'] == "checked_in";
    final bool isCheckedIn = active != null;

    final String checkInTimeDisplay = hasCheckedIn && attendances.isNotEmpty
        ? (attendances.first['checkInTime'] != null
              ? DateFormat.jm().format(
                  DateTime.parse(attendances.first['checkInTime']).toLocal(),
                )
              : "--:--")
        : "--:--";

    final String checkOutTimeDisplay = hasCheckedIn && attendances.isNotEmpty
        ? (attendances.last['checkOutTime'] != null
              ? DateFormat.jm().format(
                  DateTime.parse(attendances.last['checkOutTime']).toLocal(),
                )
              : "--:--")
        : "--:--";

    final String statusText = isCheckedIn ? "Checked In" : "Checked Out";
    final Color statusColor = isCheckedIn
        ? AppColors.primaryGreen
        : AppColors.redLate;

    return RefreshIndicator(
      onRefresh: _forceRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
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
                        greeting,
                        style: AppTextStyles.bodyRegular.copyWith(fontSize: 18),
                      ),
                      Text(fullName ?? "User", style: AppTextStyles.heading1),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onProfilePressed,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                          ? NetworkImage(imageUrl!)
                          : null,
                      child: imageUrl == null || imageUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryText.withOpacity(0.2),
                  ),
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
                  children: [
                    Text(
                      getFormattedDate(),
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 15),
                    ),
                    Text(
                      getFormattedTime(),
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: RipplePainter(
                            _animation.value,
                            hasCheckedIn,
                          ),
                          size: const Size(210, 210),
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: _handleCheckInOutTap,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: isCheckedIn
                              ? Colors.redAccent
                              : _canCheckIn
                              ? AppColors.primaryText
                              : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isCheckedIn
                                          ? Colors.redAccent
                                          : _canCheckIn
                                          ? AppColors.primaryText
                                          : Colors.grey)
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
                              isCheckedIn ? Icons.logout : Icons.login,
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
                            Text(
                              '$_todayCheckinCount / $_maxCheckins',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "TODAY'S SUMMARY",
                style: AppTextStyles.label.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
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
                    Icons.timer,
                  ),
                  _buildSummaryCard(
                    'Working for',
                    _workingFor,
                    Icons.hourglass_bottom_outlined,
                  ),
                  _buildSummaryCard(
                    'Check Out Time',
                    checkOutTimeDisplay,
                    Icons.timer,
                  ),
                  _buildSummaryCard(
                    'Status',
                    statusText,
                    Icons.switch_account_sharp,
                    textColor: statusColor,
                  ),
                ],
              ),
            ],
          ),
        ),
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
}

class RipplePainter extends CustomPainter {
  final double radius;
  final bool checkedIn;
  RipplePainter(this.radius, this.checkedIn);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = checkedIn
          ? AppColors.redLate.withOpacity(0.5)
          : AppColors.primaryText.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
