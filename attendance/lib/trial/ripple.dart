import "package:flutter/material.dart";

class RippleAnimationScreen extends StatefulWidget {
  @override
  _RippleAnimationScreenState createState() => _RippleAnimationScreenState();
}

class _RippleAnimationScreenState extends State<RippleAnimationScreen>
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
    return Scaffold(
      appBar: AppBar(title: Text("Ripple Animation")),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: RipplePainter(_animation.value),
                  size: Size(200, 200),
                );
              },
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              child: Center(
                child: Text("Ripple", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
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
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
