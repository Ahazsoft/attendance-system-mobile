import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';

class DigitalLedgerScreen extends StatefulWidget {
  const DigitalLedgerScreen({super.key});

  @override
  State<DigitalLedgerScreen> createState() => _DigitalLedgerScreenState();
}

class _DigitalLedgerScreenState extends State<DigitalLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<Map<String, dynamic>> allRecords;
  late List<Map<String, dynamic>> filteredRecords;

  @override
  void initState() {
    super.initState();

    allRecords = [
      {
        "name": "Sarah Johnson",
        "date": "Mar 8",
        "inTime": "8:47 AM",
        "outTime": "--",
        "hrs": "3.2",
        "icon": Icons.wb_sunny_outlined,
        "color": Colors.orange,
        "isLate": false,
      },
      {
        "name": "Ahmed Ali",
        "date": "Mar 8",
        "inTime": "8:55 AM",
        "outTime": "--",
        "hrs": "2.8",
        "icon": Icons.wb_sunny_outlined,
        "color": Colors.orange,
        "isLate": false,
      },
      {
        "name": "Maya Chen",
        "date": "Mar 8",
        "inTime": "9:12 AM",
        "outTime": "--",
        "hrs": "2.5",
        "icon": Icons.access_time,
        "color": AppColors.redLate,
        "isLate": true,
      },
      {
        "name": "James Okafor",
        "date": "Mar 8",
        "inTime": "8:30 AM",
        "outTime": "12:00 PM",
        "hrs": "3.5",
        "icon": Icons.dark_mode_outlined,
        "color": AppColors.greyText,
        "isLate": false,
      },
      {
        "name": "Daniel Kim",
        "date": "Mar 8",
        "inTime": "8:40 AM",
        "outTime": "--",
        "hrs": "3.1",
        "icon": Icons.wb_sunny_outlined,
        "color": Colors.orange,
        "isLate": false,
      },
      {
        "name": "Amina Hassan",
        "date": "Mar 8",
        "inTime": "9:05 AM",
        "outTime": "--",
        "hrs": "2.4",
        "icon": Icons.access_time,
        "color": AppColors.redLate,
        "isLate": true,
      },
      {
        "name": "Carlos Mendes",
        "date": "Mar 8",
        "inTime": "8:35 AM",
        "outTime": "--",
        "hrs": "3.3",
        "icon": Icons.wb_sunny_outlined,
        "color": Colors.orange,
        "isLate": false,
      },
      {
        "name": "Fatima Noor",
        "date": "Mar 8",
        "inTime": "8:50 AM",
        "outTime": "12:10 PM",
        "hrs": "3.6",
        "icon": Icons.dark_mode_outlined,
        "color": AppColors.greyText,
        "isLate": false,
      },
      {
        "name": "David Miller",
        "date": "Mar 8",
        "inTime": "9:18 AM",
        "outTime": "--",
        "hrs": "2.2",
        "icon": Icons.access_time,
        "color": AppColors.redLate,
        "isLate": true,
      },
      {
        "name": "Lina Park",
        "date": "Mar 8",
        "inTime": "8:42 AM",
        "outTime": "--",
        "hrs": "3.0",
        "icon": Icons.wb_sunny_outlined,
        "color": Colors.orange,
        "isLate": false,
      },
    ];

    filteredRecords = List.from(allRecords);

    _searchController.addListener(_searchEmployees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchEmployees() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredRecords = allRecords.where((record) {
        return record["name"].toLowerCase().contains(query);
      }).toList();
    });
  }

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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Employee List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: filteredRecords.map((record) {
              return _buildAttendanceCard(
                record["name"],
                record["date"],
                record["inTime"],
                record["outTime"],
                record["hrs"],
                record["icon"],
                record["color"],
                isLate: record["isLate"],
              );
            }).toList(),
            // [
            // _buildAttendanceCard(
            //   'Sarah Johnson',
            //   'Mar 8',
            //   '8:47 AM',
            //   '--',
            //   '3.2',
            //   Icons.wb_sunny_outlined,
            //   Colors.orange,
            // ),
            // _buildAttendanceCard(
            //   'Ahmed Ali',
            //   'Mar 8',
            //   '8:55 AM',
            //   '--',
            //   '2.8',
            //   Icons.wb_sunny_outlined,
            //   Colors.orange,
            // ),
            // _buildAttendanceCard(
            //   'Maya Chen',
            //   'Mar 8',
            //   '9:12 AM',
            //   '--',
            //   '2.5',
            //   Icons.access_time,
            //   AppColors.redLate,
            //   isLate: true,
            // ),
            // _buildAttendanceCard(
            //   'James Okafor',
            //   'Mar 8',
            //   '8:30 AM',
            //   '12:00 PM',
            //   '3.5',
            //   Icons.dark_mode_outlined,
            //   AppColors.greyText,
            // ),
            // ],
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
              // Profile Avater
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: CircleAvatar(
                  backgroundColor: AppColors.background,
                  child: Text(
                    name.substring(0, 1),
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
          // const SizedBox(height: 16),
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
