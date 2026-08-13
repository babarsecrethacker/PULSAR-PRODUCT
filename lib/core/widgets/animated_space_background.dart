import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedSpaceBackground extends StatefulWidget {
  final Widget child;

  const AnimatedSpaceBackground({super.key, required this.child});

  @override
  State<AnimatedSpaceBackground> createState() =>
      _AnimatedSpaceBackgroundState();
}

class _AnimatedSpaceBackgroundState extends State<AnimatedSpaceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final ValueNotifier<double> _paintTime;
  Timer? _paintTimer;

  final Random random = Random();

  final List<_Star> stars = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 140; i++) {
      stars.add(
        _Star(
          x: random.nextDouble(),
          y: random.nextDouble(),
          radius: random.nextDouble() * 2 + .3,
          speed: random.nextDouble() * .00015 + .00003,
          opacity: random.nextDouble() * .6 + .25,
        ),
      );
    }

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 180),
    )..repeat();

    _paintTime = ValueNotifier<double>(controller.value);
    _paintTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _paintTime.value = controller.value;
    });
  }

  @override
  void dispose() {
    _paintTimer?.cancel();
    _paintTime.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _paintTime,
            builder: (context, _, __) => CustomPaint(
              painter: _SpacePainter(stars: stars, time: _paintTime.value),
            ),
          ),
        ),
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class _Star {
  double x;
  double y;
  double radius;
  double speed;
  double opacity;

  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}

class _SpacePainter extends CustomPainter {
  final List<_Star> stars;
  final double time;

  const _SpacePainter({required this.stars, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // ===============================
    // DEEP SPACE BACKGROUND
    // ===============================

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xff01020A),
          Color(0xff030512),
          Color(0xff060A18),
          Color(0xff0B0720),
          Color(0xff02030A),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, background);

    // ===============================
    // LARGE NEBULA
    // ===============================

    _drawNebula(
      canvas,
      Offset(size.width * .18, size.height * .20),
      260,
      Colors.indigo,
      .08,
    );

    _drawNebula(
      canvas,
      Offset(size.width * .82, size.height * .18),
      220,
      Colors.deepPurple,
      .08,
    );

    _drawNebula(
      canvas,
      Offset(size.width * .78, size.height * .80),
      300,
      Colors.blue,
      .06,
    );

    _drawNebula(
      canvas,
      Offset(size.width * .30, size.height * .82),
      260,
      Colors.purple,
      .05,
    );

    // ===============================
    // STARS
    // ===============================

    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];

      final twinkle = (.5 + .5 * sin(time * pi * 2 + i)).abs();

      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity * twinkle);

      canvas.drawCircle(
        Offset(
          star.x * size.width,
          ((star.y + time * star.speed * 10800) % 1.1 - .05) * size.height,
        ),
        star.radius,
        paint,
      );
    }

    // ===============================
    // SHOOTING STARS
    // ===============================

    final shootPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(.15);

    final offset = (time * size.width * 1.4);

    canvas.drawLine(
      Offset(offset % (size.width + 300) - 300, 120),
      Offset(offset % (size.width + 300) - 240, 180),
      shootPaint,
    );

    canvas.drawLine(
      Offset((offset * .7) % (size.width + 400) - 400, size.height * .70),
      Offset((offset * .7) % (size.width + 400) - 340, size.height * .76),
      shootPaint,
    );
  }

  void _drawNebula(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double opacity,
  ) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90)
      ..shader = RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) {
    return true;
  }
}
