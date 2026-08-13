import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GalaxyBackground extends StatefulWidget {
  final Widget child;

  const GalaxyBackground({super.key, required this.child});

  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final ValueNotifier<double> _paintTime;
  Timer? _paintTimer;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
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
            builder: (context, value, child) =>
                CustomPaint(painter: GalaxyPainter(value)),
          ),
        ),
        RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class GalaxyPainter extends CustomPainter {
  final double progress;

  GalaxyPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .52, size.height * .45);

    //-----------------------------------
    // BIG PURPLE NEBULA
    //-----------------------------------

    final nebula = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xff9D6BFF).withOpacity(.28),
          const Color(0xff5B5FEF).withOpacity(.18),
          const Color(0xff231447).withOpacity(.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 360));

    canvas.drawCircle(center, 360, nebula);

    //-----------------------------------
    // GALAXY CORE
    //-----------------------------------

    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(.95),
          const Color(0xffD8C6FF).withOpacity(.75),
          const Color(0xff8A63FF).withOpacity(.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 90));

    canvas.drawCircle(center, 90, core);

    //-----------------------------------
    // SPIRAL ARMS
    //-----------------------------------

    final armPaint = Paint();

    for (int arm = 0; arm < 4; arm++) {
      for (int i = 0; i < 110; i++) {
        final t = i / 110;

        final angle = arm * pi / 2 + t * pi * 4.5 + progress * pi * .8;

        final radius = t * 220;

        final x = center.dx + cos(angle) * radius;

        final y = center.dy + sin(angle) * radius * .45;

        armPaint.color = Color.lerp(
          const Color(0xff9D6BFF),
          const Color(0xff4F9BFF),
          t,
        )!.withOpacity(.22 * (1 - t));

        canvas.drawCircle(Offset(x, y), 3 - t * 2, armPaint);
      }
    }

    //-----------------------------------
    // FLOATING STARS
    //-----------------------------------

    final random = Random(8);

    final starPaint = Paint();

    for (int i = 0; i < 90; i++) {
      final x = random.nextDouble() * size.width;

      final y = random.nextDouble() * size.height;

      final twinkle = .4 + .6 * sin(progress * pi * 2 + i);

      starPaint.color = Colors.white.withOpacity(twinkle.abs() * .75);

      final r = random.nextDouble() * 2 + .5;

      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    //-----------------------------------
    // GALAXY PARTICLES
    //-----------------------------------

    final particle = Paint();

    for (int i = 0; i < 60; i++) {
      final angle = (i * 12 + progress * 120) * pi / 180;

      final radius = 60 + i * 2.4;

      final x = center.dx + cos(angle) * radius;

      final y = center.dy + sin(angle) * radius * .55;

      particle.color = Colors.white.withOpacity(.18);

      canvas.drawCircle(Offset(x, y), 1.3, particle);
    }

    //-----------------------------------
    // SOFT GLOW
    //-----------------------------------

    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80)
      ..color = const Color(0xff7C4DFF).withOpacity(.15);

    canvas.drawCircle(center, 180, glow);
  }

  @override
  bool shouldRepaint(covariant GalaxyPainter oldDelegate) {
    return true;
  }
}
