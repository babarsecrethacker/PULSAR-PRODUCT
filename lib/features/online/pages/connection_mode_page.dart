import 'package:flutter/material.dart';

import '../../../core/theme/nova_theme.dart';
import '../../../core/widgets/nova_backdrop.dart';

/// Entry screen for choosing how to connect.
///
/// It is painted on a themed [NovaBackdrop] rather than being
/// transparent, so the light themes actually look light instead of
/// showing the dark starfield behind light text.
class ConnectionModePage extends StatefulWidget {
  final VoidCallback onLanSelected;
  final VoidCallback onOnlineSelected;

  const ConnectionModePage({
    super.key,
    required this.onLanSelected,
    required this.onOnlineSelected,
  });

  @override
  State<ConnectionModePage> createState() => _ConnectionModePageState();
}

class _ConnectionModePageState extends State<ConnectionModePage> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return NovaScreen(
      child: Center(
        child: SingleChildScrollView(
          // The column is intrinsically tall, so a short window has to
          // be allowed to scroll rather than clip.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(NovaSpacing.xl),
              child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                // Scale the decoration down when vertical space is
                // scarce, which is what a window resize needs.
                final bool tight = c.maxHeight < 520;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: tight ? 56 : 72,
                      height: tight ? 56 : 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.12),
                        border: Border.all(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.30),
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: tight ? 26 : 34,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      height: tight
                          ? 14
                          : NovaSpacing.xl,
                    ),
                    Text(
                      'Pulsar Chat',
                      style: (tight
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme
                                  .headlineMedium)
                          ?.copyWith(letterSpacing: -0.5),
                    ),
                    SizedBox(height: NovaSpacing.sm),
                    Text(
                      'Choose how you want to connect',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(
                      height: tight
                          ? 20
                          : NovaSpacing.xxl,
                    ),
                    _ModeButton(
                      icon: Icons.wifi_rounded,
                      title: 'Local / LAN',
                      subtitle: 'Chat with people on this network',
                      onPressed: widget.onLanSelected,
                    ),
                    SizedBox(height: NovaSpacing.md),
                    _ModeButton(
                      icon: Icons.public_rounded,
                      title: 'Online',
                      subtitle: 'Reach friends and family anywhere',
                      onPressed: widget.onOnlineSelected,
                    ),
                  ],
                );
              },
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(NovaRadius.xl),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(NovaRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NovaRadius.xl),
              border: Border.all(color: scheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(NovaSpacing.lg),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(NovaRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: scheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: NovaSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
