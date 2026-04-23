import 'dart:async';
import 'package:attendance/db/attendance_service.dart';
import 'package:attendance/db/employee_service.dart';
import 'package:attendance/db/settings.dart';
import 'package:attendance/model/user.dart';
import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DigitalLedgerScreen extends StatefulWidget {
  const DigitalLedgerScreen({super.key});

  @override
  State<DigitalLedgerScreen> createState() => _DigitalLedgerScreenState();
}

class _DigitalLedgerScreenState extends State<DigitalLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<User> _users = [];
  List<dynamic> _allAttendance = [];
  List<Map<String, dynamic>> _todayRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];

  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _serverTime;

  Timer? _refreshTimer;
  Timer? _serverTimeTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRecords);
    _loadData();

    // Auto‑refresh every minute to keep "today" accurate
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _loadData(showLoading: false);
    });
    _serverTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _fetchServerTime();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _serverTimeTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerTime() async {
    try {
      final serverTimeUtc = await SettingsService.getServerTime();
      if (mounted) {
        setState(() => _serverTime = serverTimeUtc);
      }
    } catch (e) {
      debugPrint('Failed to fetch server time: $e');
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        EmployeeService.fetchAllUsers(),
        AttendanceService.getAllEmpAttendance(),
        _fetchServerTime(),
      ]);

      final users = results[0] as List<User>;
      final attendance = results[1] as List<dynamic>;

      if (mounted) {
        setState(() {
          _users = users;
          _allAttendance = attendance;
          _isLoading = false;
          _errorMessage = null;
        });
        _buildTodayRecords();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _buildTodayRecords() {
    if (_users.isEmpty || _allAttendance.isEmpty) {
      setState(() {
        _todayRecords = [];
        _filteredRecords = [];
      });
      return;
    }

    // Determine "today" in UTC based on server time
    final now = _serverTime ?? DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    // Build a map of employeeId → User for quick lookup
    final userMap = {for (var u in _users) u.id: u};

    final List<Map<String, dynamic>> records = [];

    for (var att in _allAttendance) {
      final checkInUtc = DateTime.parse(att['checkInTime']);
      // Only include records from today
      if (!(checkInUtc.year == today.year &&
          checkInUtc.month == today.month &&
          checkInUtc.day == today.day)) {
        continue;
      }

      final employeeId = att['employeeId'];
      final user = userMap[employeeId];
      if (user == null) continue; // Should not happen

      final checkOutUtc = att['checkOutTime'] != null
          ? DateTime.parse(att['checkOutTime'])
          : null;

      // Convert to local time for display
      final checkInLocal = checkInUtc.toLocal();
      final checkOutLocal = checkOutUtc?.toLocal();

      final hours = att['workingHours'] != null
          ? (att['workingHours'] as num).toDouble()
          : _calculateWorkingHours(checkInUtc, checkOutUtc ?? now);

      final isCheckedOut = att['checkOutTime'] != null;
      final isLate = att['isLate'] == true;

      // Determine icon and color
      IconData statusIcon;
      Color statusColor;
      if (isCheckedOut) {
        statusIcon = Icons.dark_mode_outlined;
        statusColor = AppColors.greyText;
      } else if (isLate) {
        statusIcon = Icons.access_time;
        statusColor = AppColors.redLate;
      } else {
        statusIcon = Icons.wb_sunny_outlined;
        statusColor = Colors.orange;
      }

      records.add({
        'name': '${user.firstName} ${user.lastName}',
        'date': DateFormat('MMM d').format(checkInLocal),
        'inTime': DateFormat('h:mm a').format(checkInLocal),
        'outTime': isCheckedOut
            ? DateFormat('h:mm a').format(checkOutLocal!)
            : '--',
        'hrs': hours.toStringAsFixed(1),
        'icon': statusIcon,
        'color': statusColor,
        'isLate': isLate,
        'isCheckedOut': isCheckedOut,
      });
    }

    // Sort by check‑in time (most recent first)
    records.sort((a, b) => b['inTime'].compareTo(a['inTime']));

    setState(() {
      _todayRecords = records;
      _filterRecords(); // Apply current search filter
    });
  }

  double _calculateWorkingHours(DateTime start, DateTime end) {
    final diff = end.difference(start);
    return diff.inMinutes / 60.0;
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = List.from(_todayRecords);
      } else {
        _filteredRecords = _todayRecords.where((record) {
          return record['name'].toLowerCase().contains(query);
        }).toList();
      }
    });
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
            Text('Something went wrong', style: AppTextStyles.bodyBold),
            TextButton(
              onPressed: () => _loadData(),
              child: const Text('Retry'),
            ),
          ],
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
              Text('Live', style: AppTextStyles.label),
              const Text('Digital Ledger', style: AppTextStyles.heading1),
              const SizedBox(height: 16),
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search employee...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.greyText,
                  ),
                  filled: true,
                  fillColor: AppColors.cardWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                children: [
                  _buildStatusChip(
                    Icons.wb_sunny_outlined,
                    'Checked In',
                    Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(
                    Icons.dark_mode_outlined,
                    'Checked Out',
                    AppColors.greyText,
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(
                    Icons.access_time,
                    'Late',
                    AppColors.redLate,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Today's summary
              Text(
                'Today · ${_todayRecords.length} records',
                style: AppTextStyles.bodyRegular.copyWith(
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Employee List
        Expanded(
          child: _filteredRecords.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'No activity today'
                        : 'No matching employees',
                    style: AppTextStyles.bodyRegular,
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: _filteredRecords.map((record) {
                    return _buildAttendanceCard(
                      record['name'],
                      record['date'],
                      record['inTime'],
                      record['outTime'],
                      record['hrs'],
                      record['icon'],
                      record['color'],
                      isLate: record['isLate'],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildAttendanceCard(
    String name,
    String date,
    String inTime,
    String outTime,
    String hrs,
    IconData statusIcon,
    Color statusColor, {
    bool isLate = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: AppTextStyles.bodyBold,
                  ),
                ),
              ),
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
                            Text(name, style: AppTextStyles.bodyBold),
                            Text(date, style: AppTextStyles.label),
                          ],
                        ),
                        Icon(statusIcon, color: statusColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeInfo('In: $inTime'),
                        _buildTimeInfo('Out: $outTime'),
                        _buildTimeInfo('Hrs: $hrs'),
                      ],
                    ),
                    if (isLate) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Arrived Late',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.redLate,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String text) => Text(
    text,
    style: AppTextStyles.bodyRegular.copyWith(
      color: AppColors.primaryText.withOpacity(0.7),
    ),
  );
}

// import 'package:attendance/theme/appTheme.dart';
// import 'package:flutter/material.dart';

// class DigitalLedgerScreen extends StatefulWidget {
//   const DigitalLedgerScreen({super.key});

//   @override
//   State<DigitalLedgerScreen> createState() => _DigitalLedgerScreenState();
// }

// class _DigitalLedgerScreenState extends State<DigitalLedgerScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   late List<Map<String, dynamic>> allRecords;
//   late List<Map<String, dynamic>> filteredRecords;

//   @override
//   void initState() {
//     super.initState();

//     allRecords = [
//       {
//         "name": "Sarah Johnson",
//         "date": "Mar 8",
//         "inTime": "8:47 AM",
//         "outTime": "--",
//         "hrs": "3.2",
//         "icon": Icons.wb_sunny_outlined,
//         "color": Colors.orange,
//         "isLate": false,
//       },
//       {
//         "name": "Ahmed Ali",
//         "date": "Mar 8",
//         "inTime": "8:55 AM",
//         "outTime": "--",
//         "hrs": "2.8",
//         "icon": Icons.wb_sunny_outlined,
//         "color": Colors.orange,
//         "isLate": false,
//       },
//       {
//         "name": "Maya Chen",
//         "date": "Mar 8",
//         "inTime": "9:12 AM",
//         "outTime": "--",
//         "hrs": "2.5",
//         "icon": Icons.access_time,
//         "color": AppColors.redLate,
//         "isLate": true,
//       },
//       {
//         "name": "James Okafor",
//         "date": "Mar 8",
//         "inTime": "8:30 AM",
//         "outTime": "12:00 PM",
//         "hrs": "3.5",
//         "icon": Icons.dark_mode_outlined,
//         "color": AppColors.greyText,
//         "isLate": false,
//       },
//       {
//         "name": "Daniel Kim",
//         "date": "Mar 8",
//         "inTime": "8:40 AM",
//         "outTime": "--",
//         "hrs": "3.1",
//         "icon": Icons.wb_sunny_outlined,
//         "color": Colors.orange,
//         "isLate": false,
//       },
//       {
//         "name": "Amina Hassan",
//         "date": "Mar 8",
//         "inTime": "9:05 AM",
//         "outTime": "--",
//         "hrs": "2.4",
//         "icon": Icons.access_time,
//         "color": AppColors.redLate,
//         "isLate": true,
//       },
//       {
//         "name": "Carlos Mendes",
//         "date": "Mar 8",
//         "inTime": "8:35 AM",
//         "outTime": "--",
//         "hrs": "3.3",
//         "icon": Icons.wb_sunny_outlined,
//         "color": Colors.orange,
//         "isLate": false,
//       },
//       {
//         "name": "Fatima Noor",
//         "date": "Mar 8",
//         "inTime": "8:50 AM",
//         "outTime": "12:10 PM",
//         "hrs": "3.6",
//         "icon": Icons.dark_mode_outlined,
//         "color": AppColors.greyText,
//         "isLate": false,
//       },
//       {
//         "name": "David Miller",
//         "date": "Mar 8",
//         "inTime": "9:18 AM",
//         "outTime": "--",
//         "hrs": "2.2",
//         "icon": Icons.access_time,
//         "color": AppColors.redLate,
//         "isLate": true,
//       },
//       {
//         "name": "Lina Park",
//         "date": "Mar 8",
//         "inTime": "8:42 AM",
//         "outTime": "--",
//         "hrs": "3.0",
//         "icon": Icons.wb_sunny_outlined,
//         "color": Colors.orange,
//         "isLate": false,
//       },
//     ];

//     filteredRecords = List.from(allRecords);

//     _searchController.addListener(_searchEmployees);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _searchEmployees() {
//     final query = _searchController.text.toLowerCase();

//     setState(() {
//       filteredRecords = allRecords.where((record) {
//         return record["name"].toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Live', style: AppTextStyles.label),
//               const Text('Digital Ledger', style: AppTextStyles.heading1),
//               const SizedBox(height: 16),

//               // Search Bar
//               TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: 'Search employee...',
//                   prefixIcon: const Icon(
//                     Icons.search,
//                     color: AppColors.greyText,
//                   ),
//                   filled: true,
//                   fillColor: AppColors.cardWhite,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: Colors.black.withOpacity(0.12),
//                     ),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: Colors.black.withOpacity(0.2),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Legend
//               Row(
//                 children: [
//                   _buildStatusChip(
//                     Icons.wb_sunny_outlined,
//                     'Checked In',
//                     Colors.orange,
//                   ),
//                   const SizedBox(width: 12),
//                   _buildStatusChip(
//                     Icons.dark_mode_outlined,
//                     'Checked Out',
//                     AppColors.greyText,
//                   ),
//                   const SizedBox(width: 12),
//                   _buildStatusChip(
//                     Icons.access_time,
//                     'Late',
//                     AppColors.redLate,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Employee List
//         Expanded(
//           child: ListView(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             children: filteredRecords.map((record) {
//               return _buildAttendanceCard(
//                 record["name"],
//                 record["date"],
//                 record["inTime"],
//                 record["outTime"],
//                 record["hrs"],
//                 record["icon"],
//                 record["color"],
//                 isLate: record["isLate"],
//               );
//             }).toList(),
//             // [
//             // _buildAttendanceCard(
//             //   'Sarah Johnson',
//             //   'Mar 8',
//             //   '8:47 AM',
//             //   '--',
//             //   '3.2',
//             //   Icons.wb_sunny_outlined,
//             //   Colors.orange,
//             // ),
//             // _buildAttendanceCard(
//             //   'Ahmed Ali',
//             //   'Mar 8',
//             //   '8:55 AM',
//             //   '--',
//             //   '2.8',
//             //   Icons.wb_sunny_outlined,
//             //   Colors.orange,
//             // ),
//             // _buildAttendanceCard(
//             //   'Maya Chen',
//             //   'Mar 8',
//             //   '9:12 AM',
//             //   '--',
//             //   '2.5',
//             //   Icons.access_time,
//             //   AppColors.redLate,
//             //   isLate: true,
//             // ),
//             // _buildAttendanceCard(
//             //   'James Okafor',
//             //   'Mar 8',
//             //   '8:30 AM',
//             //   '12:00 PM',
//             //   '3.5',
//             //   Icons.dark_mode_outlined,
//             //   AppColors.greyText,
//             // ),
//             // ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusChip(IconData icon, String label, Color color) {
//     return Row(
//       children: [
//         Icon(icon, size: 14, color: color),
//         const SizedBox(width: 4),
//         Text(label, style: AppTextStyles.label.copyWith(fontSize: 11)),
//       ],
//     );
//   }

//   Widget _buildAttendanceCard(
//     String name,
//     String date,
//     String inTime,
//     String outTime,
//     String hrs,
//     IconData statusIcon,
//     Color statusColor, {
//     bool isLate = false,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.cardWhite,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.black.withOpacity(0.03)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Profile Avater
//               Padding(
//                 padding: const EdgeInsets.only(top: 5),
//                 child: CircleAvatar(
//                   backgroundColor: AppColors.background,
//                   child: Text(
//                     name.substring(0, 1),
//                     style: AppTextStyles.bodyBold,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),

//               Expanded(
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(name, style: AppTextStyles.bodyBold),
//                             Text(date, style: AppTextStyles.label),
//                           ],
//                         ),
//                         Icon(statusIcon, color: statusColor, size: 20),
//                       ],
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         _buildTimeInfo('In: $inTime'),
//                         _buildTimeInfo('Out: $outTime'),
//                         _buildTimeInfo('Hrs: $hrs'),
//                       ],
//                     ),
//                     if (isLate) ...[
//                       const SizedBox(height: 12),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: AppColors.lightRed,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             'Arrived Late',
//                             style: AppTextStyles.label.copyWith(
//                               color: AppColors.redLate,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           // const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeInfo(String text) => Text(
//     text,
//     style: AppTextStyles.bodyRegular.copyWith(
//       color: AppColors.primaryText.withOpacity(0.7),
//     ),
//   );
// }
