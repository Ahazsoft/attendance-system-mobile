import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  final int id;
  const HistoryScreen({super.key, required this.id});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isThisWeek = true;

  @override
  Widget build(BuildContext context) {
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
                  '5',
                  'Days Present',
                  AppColors.cardWhite,
                  AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '42h',
                  'Total Hours',
                  AppColors.lightGreen,
                  AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '2',
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
            child: ListView(
              children: [
                _buildTimelineItem(
                  'Today',
                  'Fri',
                  '8:47 AM',
                  '--',
                  '3h 12m',
                  isLate: false,
                  isToday: true,
                ),
                _buildTimelineItem(
                  'Mar 7',
                  'Thu',
                  '8:55 AM',
                  '5:30 PM',
                  '8h 35m',
                  isLate: false,
                ),
                _buildTimelineItem(
                  'Mar 6',
                  'Wed',
                  '9:12 AM',
                  '5:15 PM',
                  '6h 03m',
                  isLate: true,
                ),
                _buildTimelineItem(
                  'Mar 5',
                  'Tue',
                  '8:30 AM',
                  '5:45 PM',
                  '9h 15m',
                  isLate: false,
                ),
                _buildTimelineItem(
                  'Mar 4',
                  'Mon',
                  '8:42 AM',
                  '5:00 PM',
                  '8h 18m',
                  isLate: false,
                ),
              ],
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
            : null,
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
