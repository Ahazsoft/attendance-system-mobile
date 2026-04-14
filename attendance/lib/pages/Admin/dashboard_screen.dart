import 'package:flutter/material.dart';
import 'package:attendance/theme/appTheme.dart'; // Adjust import path as needed
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.greyText,
            ),
          ),
          const Text('Forest Overview', style: AppTextStyles.heading1),
          const SizedBox(height: 24),

          // 1. Stats Grid
          _buildStatsGrid(),
          const SizedBox(height: 24),

          // 2. Weekly Presence Chart
          _buildWeeklyPresenceCard(),
          const SizedBox(height: 24),

          // 3. Punctuality Breakdown
          _buildPunctualityCard(ontime: 72, late: 18, absent: 10),
          const SizedBox(height: 24),

          // 4. Team Hours Trend Placeholder
          _buildTrendCard(),

          const SizedBox(height: 24), // Bottom padding
        ],
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
                value: '8/10',
                icon: PhosphorIconsBold.users,
                iconColor: AppColors.primaryGreen,
                bgColor: AppColors.lightGreen,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: _buildStatCard(
                title: 'Week Attendance',
                value: '92%',
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
                value: '8.2h',
                icon: PhosphorIconsBold.clock,
                iconColor: Colors.orange,
                bgColor: AppColors.cardWhite,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: _buildStatCard(
                title: 'Late Today',
                value: '2',
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
      width: double.infinity,
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
    final weeklyPresence = [7, 9, 6, 8, 5];

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
                maxY: 10,

                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 2,
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
                      interval: 2,
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
                  weeklyPresence.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyPresence[index].toDouble(),
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

  Widget _buildPunctualityCard({
    required double ontime,
    required double late,
    required double absent,
  }) {
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
              // Placeholder for a donut chart
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,

                    sections: [
                      PieChartSectionData(
                        value: ontime,
                        color: AppColors.primaryGreen,
                        title: "${ontime.toStringAsFixed(0)}%",
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: late,
                        color: AppColors.redLate,
                        title: "${late.toStringAsFixed(0)}%",
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: absent,
                        color: AppColors.greyText,
                        title: "${absent.toStringAsFixed(0)}%",
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
              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('On Time', '72%', AppColors.primaryGreen),
                    const SizedBox(height: 12),
                    _buildLegendItem('Late', '18%', AppColors.redLate),
                    const SizedBox(height: 12),
                    _buildLegendItem('Absent', '10%', AppColors.greyText),
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
                  horizontalInterval: 2,
                  verticalInterval: 1,
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
                      interval: 2,
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
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Mon');
                          case 1:
                            return const Text('Tue');
                          case 2:
                            return const Text('Wed');
                          case 3:
                            return const Text('Thu');
                          case 4:
                            return const Text('Fri');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(show: false),

                minX: 0,
                maxX: 4,
                minY: 0,
                maxY: 10,

                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 7),
                      FlSpot(1, 8),
                      FlSpot(2, 6),
                      FlSpot(3, 9),
                      FlSpot(4, 7),
                    ],

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

  // keep the closing } away
}
