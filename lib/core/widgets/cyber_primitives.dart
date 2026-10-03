import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/cyber_theme.dart';

/// Frosted panel: translucent fill, a light-catching top edge and an
/// optional accent bloom. Used for every raised surface so depth reads
/// consistently instead of being invented per screen.
class CyberGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;

  /// Draws the 1px gradient hairline. Off for nested surfaces, where
  /// it just adds noise.
  final bool border;

  /// Accent colour for the bloom and the hairline tint.
  final Color? accent;

  final bool clip;
  final Color? background;

  const CyberGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CyberSpace.lg),
    this.radius = CyberRadius.lg,
    this.opacity = 1,
    this.border = true,
    this.accent,
    this.clip = true,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final Color glow = accent ?? CyberPalette.cyan;

    Widget surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            background ?? Color.lerp(
              CyberPalette.obsidianHigh,
              CyberPalette.glass,
              0.55 * opacity,
            ),
        borderRadius: CyberRadius.r(radius),
        border: border
            ? Border.all(color: CyberPalette.hairline, width: 1)
            : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: glow.withValues(alpha: 0.10),
            blurRadius: 40,
            spreadRadius: -12,
          ),
          const BoxShadow(
            color: Color(0x14FFFFFF),
            blurRadius: 0,
            spreadRadius: 1,
            offset: Offset(0, -0.5),
          ),
        ],
      ),
      child: child,
    );

    if (!clip) {
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: CyberRadius.r(radius)),
        child: ClipRRect(
          borderRadius: CyberRadius.r(radius),
          child: surface,
        ),
      );
    }

    return surface;
  }
}

/// Small status pill with a live dot. The dot breathes while [pulse] is
/// true so the UI shows that a value is updating rather than stale.
class CyberChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool pulse;
  final bool dense;

  const CyberChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.pulse = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: CyberRadius.pillAll,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Dot(color: color, pulse: pulse, size: dense ? 5 : 6),
          SizedBox(width: dense ? 5 : 7),
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 11 : 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: CyberType.label.copyWith(
              color: color,
              fontSize: dense ? 10.5 : 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Breathing dot used for live indicators.
class _Dot extends StatefulWidget {
  final Color color;
  final bool pulse;
  final double size;

  const _Dot({
    required this.color,
    required this.pulse,
    required this.size,
  });

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CyberMotion.pulse,
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.pulse && _c.isAnimating) {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.color.withValues(alpha: 0.55),
            blurRadius: 7,
          ),
        ],
      ),
    );

    if (!widget.pulse) return dot;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: dot,
    );
  }
}

/// Uppercase section header with a leading accent rule.
class CyberSectionHeader extends StatelessWidget {
  final String label;
  final Color accent;
  final Widget? trailing;

  const CyberSectionHeader({
    super.key,
    required this.label,
    this.accent = CyberPalette.cyan,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: CyberSpace.md,
        top: CyberSpace.lg,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: CyberGlow.focus(accent),
            ),
          ),
          const SizedBox(width: CyberSpace.sm),
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: CyberType.overline.copyWith(
                color: CyberPalette.textSecondary,
              ),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Full-screen ambient backdrop: base gradient plus two slow-moving
/// colour fields. `engine` shifts the wash so LAN and Cloud feel like
/// different places.
class CyberBackdrop extends StatefulWidget {
  final Widget child;
  final PulseEngine engine;

  /// Runs the slow drift. Turn off for low-power devices.
  final bool animate;

  const CyberBackdrop({
    super.key,
    required this.child,
    this.engine = PulseEngine.cloud,
    this.animate = true,
  });

  @override
  State<CyberBackdrop> createState() => _CyberBackdropState();
}

class _CyberBackdropState extends State<CyberBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.engine.accent;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Cross-faded outside the decoration: an AnimatedSwitcher cannot be
        // a gradient.
        AnimatedSwitcher(
          duration: CyberMotion.modeShift,
          switchInCurve: CyberMotion.crossfade,
          child: Container(
            key: ValueKey<dynamic>(widget.engine),
            decoration: BoxDecoration(
              gradient: widget.engine == PulseEngine.lan
                  ? CyberGradient.lanAmbient
                  : CyberGradient.cloudAmbient,
            ),
          ),
        ),

        // Two colour fields drifting behind the content. Cheap: one
        // gradient, no per-frame repaint of the tree below.
        AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? _) {
            final double t = _c.value;

            return CustomPaint(
              painter: _FieldPainter(
                phase: widget.animate ? t : 0.35,
                accent: accent,
              ),
            );
          },
        ),

        widget.child,
      ],
    );
  }
}

class _FieldPainter extends CustomPainter {
  final double phase;
  final Color accent;

  _FieldPainter({required this.phase, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final double a = phase * 2 * math.pi;

    void field(
      Offset centre,
      double radius,
      double strength,
      Color color,
    ) {
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: strength),
            color.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: centre, radius: radius),
        );

      canvas.drawCircle(centre, radius, paint);
    }

    field(
      Offset(
        size.width * (0.22 + 0.05 * math.sin(a)),
        size.height * (0.16 + 0.04 * math.cos(a)),
      ),
      size.longestSide * 0.62,
      0.10,
      accent,
    );

    field(
      Offset(
        size.width * (0.84 + 0.04 * math.cos(a * 0.7)),
        size.height * (0.80 + 0.05 * math.sin(a * 0.8)),
      ),
      size.longestSide * 0.55,
      0.07,
      CyberPalette.violet,
    );
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      old.phase != phase || old.accent != accent;
}

/// Thin gradient rule used to separate HUD sections.
class CyberDivider extends StatelessWidget {
  const CyberDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.transparent,
            CyberPalette.hairlineBright,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Animated numeric readout. Counts rather than snapping, so a changing
/// value draws the eye instead of flickering.
class CyberMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final IconData? icon;

  const CyberMetric({
    super.key,
    required this.value,
    required this.label,
    this.accent = CyberPalette.cyan,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CyberGlass(
      radius: CyberRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: CyberSpace.md,
        vertical: CyberSpace.md,
      ),
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 13, color: accent),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CyberType.overline.copyWith(
                    color: CyberPalette.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CyberType.mono.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CyberPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backdrop-filter wrapper, used where true frosting is wanted over a
/// busy area (the chat list over the ambient fields).
class CyberFrosted extends StatelessWidget {
  final Widget child;
  final double sigma;
  final double radius;

  const CyberFrosted({
    super.key,
    required this.child,
    this.sigma = 18,
    this.radius = CyberRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CyberRadius.r(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
        ),
        child: child,
      ),
    );
  }
}