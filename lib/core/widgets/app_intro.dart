import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../services/app_settings.dart';
import '../theme/nova_theme.dart';
import 'nova_backdrop.dart';

/// Brand intro shown on every launch.
///
/// Holds the mark and tagline for a moment, then cross-fades into
/// [child]. It is intentionally not a "first run only" screen: a short
/// branded hold on every start is what makes a desktop app feel
/// deliberate rather than like a web page that loaded.
class AppIntro extends StatefulWidget {
  final Widget child;
  final Duration hold;
  final Duration fade;

  const AppIntro({
    super.key,
    required this.child,
    this.hold = const Duration(milliseconds: 1900),
    this.fade = const Duration(milliseconds: 420),
  });

  @override
  State<AppIntro> createState() => _AppIntroState();
}

class _AppIntroState extends State<AppIntro> {
  final AudioPlayer _player = AudioPlayer();

  bool _visible = true;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      NovaTheme.overlayStyle,
    );

    _playAmbient();

    Future<void>.delayed(widget.hold, () {
      if (!mounted) return;
      setState(() => _visible = false);
    });
  }

  /// A short, low ambient swell under the splash. Purely decorative, so
  /// every failure path is swallowed rather than allowed to interfere
  /// with startup.
  Future<void> _playAmbient() async {
    try {
      await AppSettings.instance.load();

      if (!AppSettings.instance.startupSound) return;

      await _player.setAsset(
        'assets/audio/pulsar_intro.wav',
      );
      await _player.setVolume(0.5);
      await _player.play();
    } catch (_) {
      // Ignore: no audio device, missing asset, decoder error.
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // A real themed wallpaper rather than a hard-coded white
          // panel, so the launch screen belongs to whichever theme the
          // user picked instead of always being light.
          const NovaBackdrop(dense: true),

          AnimatedOpacity(
            opacity: _visible ? 0 : 1,
            duration: widget.fade,
            curve: Curves.easeInOut,
            child: widget.child,
          ),

          IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: widget.fade,
              curve: Curves.easeInOut,
              child: const _IntroContent(),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NovaSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 104,
              height: 104,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius:
                    BorderRadius.circular(NovaRadius.xl),
                border: Border.all(
                  color: scheme.outlineVariant,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/icon/pulsar.png',
                width: 68,
                height: 68,
                fit: BoxFit.contain,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stack,
                ) {
                  return Icon(
                    Icons.forum_rounded,
                    size: 38,
                    color: scheme.primary,
                  );
                },
              ),
            ),

            const SizedBox(height: NovaSpacing.xl),

            Text(
              'Pulsar Chat',
              style: text.headlineMedium?.copyWith(
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: NovaSpacing.sm),

            Text(
              'Private messaging for your network',
              style: text.bodyMedium,
            ),

            const SizedBox(height: NovaSpacing.xxxl),

            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(NovaRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor:
                      scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    scheme.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: NovaSpacing.lg),

            Text(
              'Starting up',
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant
                    .withValues(alpha: 0.75),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
