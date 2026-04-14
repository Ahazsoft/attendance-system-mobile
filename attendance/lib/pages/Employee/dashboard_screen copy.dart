import 'package:attendance/theme/appTheme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  final VoidCallback onScanPressed;
  const EmployeeDashboardScreen({super.key, required this.onScanPressed});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: false);
    _animation = Tween<double>(begin: 0, end: 100).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  const Text('Sarah Johnson', style: AppTextStyles.heading1),
                ],
              ),

              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/women/44.jpg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status Card
          Container(
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Checked In',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),

                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'CheckOut',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Checked in at', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        const Text('8:47 AM', style: AppTextStyles.heading2),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Working for', style: AppTextStyles.label),
                        const SizedBox(height: 4),
                        Text(
                          '3h 12m',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Central Scan Out Button
          Center(
            child: Stack(
              alignment: Alignment.center,

              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: RipplePainter(_animation.value),
                      size: Size(120, 120),
                    );
                  },
                ),
                GestureDetector(
                  onTap: widget.onScanPressed,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryText,
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryText.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.qrCode(),
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SCAN OUT',
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
              _buildSummaryCard('Expected', '8h 00m', PhosphorIconsBold.timer),
              _buildSummaryCard(
                'This Week',
                '24h 30m',
                PhosphorIconsBold.trendUp,
              ),
              _buildSummaryCard(
                'On-time Streak',
                '12 days',
                PhosphorIconsBold.hourglassHigh,
              ),
              _buildSummaryCard(
                'Status',
                'On Time',
                PhosphorIconsBold.presentationChart,
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
