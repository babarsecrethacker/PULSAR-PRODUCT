import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../contacts/models/contact.dart';
import '../theme/cyber_theme.dart';
import 'cyber_primitives.dart';

/// A peer plotted on the radar.
class RadarNode {
  final String id;
  final String name;

  /// Round-trip time in milliseconds, or null while unknown.
  final int? latency;

  final bool isOnline;

  const RadarNode({
    required this.id,
    required this.name,
    this.latency,
    this.isOnline = true,
  });
}

/// "Local Grid Radar" — the LAN discovery view.
///
/// Peers are plotted as nodes on concentric rings around the local node,
/// laid out on a deterministic spiral derived from their id so a peer
/// keeps its position between rebuilds instead of jumping. Proximity
/// encodes ping: a fast peer sits near the centre.
class LanRadar extends StatefulWidget {
  final List<RadarNode> nodes;
  final ValueChanged<RadarNode>? onNodeTap;
  final double size;
  final bool scanning;

  const LanRadar({
    super.key,
    required this.nodes,
    this.onNodeTap,
    this.size = 260,
    this.scanning = true,
  });

  @override
  State<LanRadar> createState() => _LanRadarState();
}

class _LanRadarState extends State<LanRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: CyberMotion.sweep,
  );

  @override
  void initState() {
    super.initState();
    if (widget.scanning) _sweep.repeat();
  }

  @override
  void didUpdateWidget(covariant LanRadar old) {
    super.didUpdateWidget(old);
    if (widget.scanning && !_sweep.isAnimating) {
      _sweep.repeat();
    } else if (!widget.scanning && _sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (BuildContext context, Widget? _) {
          return CustomPaint(
            painter: _RadarPainter(
              phase: widget.scanning ? _sweep.value : 0.2,
              nodes: _layout(),
              scanning: widget.scanning,
            ),
            child: Stack(
              children: <Widget>[
                for (final RadarNode node in widget.nodes)
                  if (_layout().containsKey(node.id))
                    _NodeMarker(
                      key: ValueKey<String>(node.id),
                      node: node,
                      offset: _layout()[node.id]!,
                      onTap: widget.onNodeTap == null
                          ? null
                          : () => widget.onNodeTap!(node),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Deterministic ring + angle per peer, with ping pulling the peer
  /// toward the centre.
  Map<String, Offset> _layout() {
    final Map<String, Offset> out = <String, Offset>{};

    if (widget.nodes.isEmpty) return out;

    final double centre = widget.size / 2;

    for (int i = 0; i < widget.nodes.length; i++) {
      final RadarNode node = widget.nodes[i];

      // Stable hash so a peer keeps its slot between rebuilds.
      final int hash =
          node.id.codeUnits.fold<int>(
                7,
                (int a, int b) => (a * 31 + b) & 0x7fffffff,
              ) %
              360;

      // Three rings; unknown pings sit mid-ring.
      final int ring = switch (node.latency) {
        null => 1,
        < 40 => 0,
        < 90 => 1,
        < 160 => 2,
        _ => 3,
      };

      final double radius = centre * (0.30 + ring * 0.19);
      final double angle = hash * math.pi / 180;

      out[node.id] = Offset(
        centre + radius * math.cos(angle),
        centre + radius * math.sin(angle),
      );
    }

    return out;
  }
}

class _NodeMarker extends StatefulWidget {
  final RadarNode node;
  final Offset offset;
  final VoidCallback? onTap;

  const _NodeMarker({
    super.key,
    required this.node,
    required this.offset,
    this.onTap,
  });

  @override
  State<_NodeMarker> createState() => _NodeMarkerState();
}

class _NodeMarkerState extends State<_NodeMarker> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.node.isOnline
        ? CyberPalette.cyan
        : CyberPalette.textTertiary;

    return Positioned(
      left: widget.offset.dx - 26,
      top: widget.offset.dy - 26,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _hover ? 1.14 : 1,
            duration: CyberMotion.fast,
            curve: CyberMotion.enter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CyberPalette.obsidianHigh,
                    border: Border.all(
                      color: accent,
                      width: 1.4,
                    ),
                    boxShadow: CyberGlow.focus(
                      accent,
                    ),
                  ),
                  child: Text(
                    widget.node.name.isEmpty
                        ? '?'
                        : widget.node.name
                            .substring(0, 1)
                            .toUpperCase(),
                    style: CyberType.label.copyWith(
                      color: accent,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 64),
                  child: Text(
                    widget.node.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CyberType.label.copyWith(
                      fontSize: 9.5,
                      color: CyberPalette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double phase;
  final Map<String, Offset> nodes;
  final bool scanning;

  _RadarPainter({
    required this.phase,
    required this.nodes,
    required this.scanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.shortestSide / 2 - 6;

    // Concentric rings
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = CyberPalette.hairline;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(centre, maxRadius * (i / 3.4), ring);
    }

    // Cross hairs
    final Paint hair = Paint()
      ..strokeWidth = 1
      ..color = CyberPalette.hairline;

    canvas.drawLine(
      Offset(centre.dx - maxRadius, centre.dy),
      Offset(centre.dx + maxRadius, centre.dy),
      hair,
    );
    canvas.drawLine(
      Offset(centre.dx, centre.dy - maxRadius),
      Offset(centre.dx, centre.dy + maxRadius),
      hair,
    );

    // Sweep wedge
    if (scanning) {
      final double angle = phase * 2 * math.pi;

      final Paint sweep = Paint()
        ..shader = SweepGradient(
          startAngle: angle,
          endAngle: angle + math.pi / 3,
          colors: <Color>[
            CyberPalette.cyan.withValues(alpha: 0.28),
            CyberPalette.cyan.withValues(alpha: 0),
          ],
          transform: GradientRotation(angle),
        ).createShader(
          Rect.fromCircle(center: centre, radius: maxRadius),
        );

      canvas.drawCircle(centre, maxRadius, sweep);

      // Leading edge
      final Paint edge = Paint()
        ..strokeWidth = 1.4
        ..color = CyberPalette.cyan.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        centre,
        Offset(
          centre.dx + maxRadius * math.cos(angle),
          centre.dy + maxRadius * math.sin(angle),
        ),
        edge,
      );
    }

    // Local node
    final Paint core = Paint()
      ..color = CyberPalette.violet;

    canvas.drawCircle(centre, 7, core);
    canvas.drawCircle(
      centre,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = CyberPalette.violet.withValues(alpha: 0.6),
    );

    // Halo around each peer so nodes read above the rings.
    for (final Offset p in nodes.values) {
      canvas.drawCircle(
        p,
        20,
        Paint()
          ..color = CyberPalette.cyan.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.phase != phase ||
      old.nodes.length != nodes.length ||
      old.scanning != scanning;
}

/// Builds radar nodes from the contact list the app already tracks.
List<RadarNode> radarNodesFromContacts(
  List<Contact> contacts, {
  Map<String, int>? pings,
}) {
  return contacts
      .map(
        (Contact c) => RadarNode(
          id: c.id,
          name: c.name,
          latency: pings?[c.id],
          isOnline: c.online,
        ),
      )
      .toList();
}