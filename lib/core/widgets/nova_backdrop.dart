import 'package:flutter/material.dart';

import '../theme/nova_theme.dart';

/// A soft, theme-aware wallpaper for the app's entry screens.
///
/// These screens used to be `Colors.transparent`, which meant the dark
/// animated starfield showed through behind light-themed text. That is
/// why the mode-selection, login and username screens stayed dark even
/// in a light theme. Painting a real background derived from the active
/// theme fixes that and gives the entry screens a deliberate look
/// instead of whatever happened to be behind them.
class NovaBackdrop extends StatelessWidget {
  final Widget? child;
  final bool dense;

  const NovaBackdrop({
    super.key,
    this.child,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool light = theme.brightness == Brightness.light;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: light
              ? <Color>[
                  scheme.surface,
                  Color.lerp(
                    scheme.surface,
                    scheme.primary,
                    0.07,
                  )!,
                  Color.lerp(
                    scheme.surface,
                    scheme.primary,
                    0.03,
                  )!,
                ]
              : <Color>[
                  scheme.surface,
                  Color.lerp(
                    scheme.surface,
                    scheme.primary,
                    0.10,
                  )!,
                  scheme.surfaceContainerHighest,
                ],
        ),
      ),
      child: CustomPaint(
        painter: _BackdropPainter(
          accent: scheme.primary,
          isLight: light,
          dense: dense,
        ),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final Color accent;
  final bool isLight;
  final bool dense;

  _BackdropPainter({
    required this.accent,
    required this.isLight,
    required this.dense,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Two soft radial washes give the screen depth without competing
    // with the content on top of it.
    final double strength = isLight ? 0.10 : 0.18;

    _wash(
      canvas,
      size,
      center: Offset(size.width * 0.18, size.height * 0.12),
      radius: size.longestSide * 0.75,
      color: accent.withValues(alpha: strength),
    );

    _wash(
      canvas,
      size,
      center: Offset(size.width * 0.92, size.height * 0.78),
      radius: size.longestSide * 0.62,
      color: accent.withValues(alpha: strength * 0.6),
    );

    _drawTexture(canvas, size);
  }

  void _wash(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    if (radius <= 0) return;

    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, paint);
  }

  /// A faint dot grid, so large empty areas are not completely flat.
  void _drawTexture(Canvas canvas, Size size) {
    const double spacing = 34;

    final Paint paint = Paint()
      ..color = (isLight ? const Color(0xFF0B1B3A) : Colors.white)
          .withValues(alpha: isLight ? 0.05 : 0.05)
      ..style = PaintingStyle.fill;

    final double radius = dense ? 1.1 : 0.9;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        // A gentle diagonal stagger avoids a rigid grid.
        final double offset = y.toInt().isEven
            ? 0
            : spacing / 2;
        canvas.drawCircle(
          Offset(x + offset, y),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) {
    return old.accent != accent ||
        old.isLight != isLight ||
        old.dense != dense;
  }
}

/// Convenience: a themed [Scaffold] background for the entry screens.
class NovaScreen extends StatelessWidget {
  final Widget child;
  final bool dense;

  const NovaScreen({
    super.key,
    required this.child,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NovaBackdrop(
        dense: dense,
        child: SafeArea(child: child),
      ),
    );
  }
}
