import 'package:flutter/material.dart';

import '../theme/cyber_theme.dart';
import 'cyber_primitives.dart';

/// LAN Mesh / Cloud Grid mode switch.
///
/// The control morphs between two labelled halves while the ambient
/// backdrop cross-fades behind it, so switching engines reads as
/// changing rooms rather than changing a setting.
class ModeSwitcher extends StatelessWidget {
  final PulseEngine engine;
  final ValueChanged<PulseEngine> onChanged;
  final bool compact;

  const ModeSwitcher({
    super.key,
    required this.engine,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CyberPalette.obsidian.withValues(alpha: 0.72),
        borderRadius: CyberRadius.pillAll,
        border: Border.all(color: CyberPalette.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final PulseEngine option in PulseEngine.values)
            _Half(
              engine: option,
              selected: option == engine,
              compact: compact,
              onTap: () {
                if (option != engine) onChanged(option);
              },
            ),
        ],
      ),
    );
  }
}

class _Half extends StatelessWidget {
  final PulseEngine engine;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _Half({
    required this.engine,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = engine.accent;

    return Semantics(
      button: true,
      selected: selected,
      label: engine.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: CyberMotion.normal,
          curve: CyberMotion.crossfade,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: CyberRadius.pillAll,
            gradient: selected
                ? LinearGradient(
                    colors: <Color>[
                      accent.withValues(alpha: 0.28),
                      accent.withValues(alpha: 0.12),
                    ],
                  )
                : null,
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? CyberGlow.focus(accent)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                engine == PulseEngine.lan
                    ? Icons.lan_rounded
                    : Icons.cloud_rounded,
                size: compact ? 14 : 16,
                color: selected
                    ? accent
                    : CyberPalette.textTertiary,
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                engine.label,
                style: CyberType.label.copyWith(
                  fontSize: compact ? 10.5 : 11.5,
                  color: selected
                      ? accent
                      : CyberPalette.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen page scaffold: ambient backdrop plus optional glass HUD
/// header. Every top-level screen uses this so the background and
/// status treatment never diverge.
class CyberScaffold extends StatelessWidget {
  final Widget child;
  final PulseEngine engine;
  final Widget? header;
  final Widget? footer;
  final bool animate;

  const CyberScaffold({
    super.key,
    required this.child,
    this.engine = PulseEngine.cloud,
    this.header,
    this.footer,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberPalette.voidBlack,
      extendBodyBehindAppBar: true,
      body: CyberBackdrop(
        engine: engine,
        animate: animate,
        child: Column(
          children: <Widget>[
            if (header != null) header!,
            Expanded(child: child),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

/// Status strip used at the top of a screen: engine name, connection
/// chip and an optional trailing readout.
class CyberStatusBar extends StatelessWidget {
  final PulseEngine engine;
  final String? status;
  final Color statusColor;
  final bool live;
  final Widget? trailing;

  const CyberStatusBar({
    super.key,
    required this.engine,
    this.status,
    this.statusColor = CyberPalette.success,
    this.live = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CyberSpace.lg,
          CyberSpace.md,
          CyberSpace.lg,
          CyberSpace.sm,
        ),
        child: Row(
          children: <Widget>[
            CyberChip(
              label: engine.label,
              color: engine.accent,
              icon: engine == PulseEngine.lan
                  ? Icons.lan_rounded
                  : Icons.cloud_rounded,
              pulse: true,
              dense: true,
            ),
            if (status != null) ...<Widget>[
              const SizedBox(width: CyberSpace.sm),
              CyberChip(
                label: status!,
                color: statusColor,
                pulse: live,
                dense: true,
              ),
            ],
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}