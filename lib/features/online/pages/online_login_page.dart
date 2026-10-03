import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/online_config.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/nova_theme.dart';
import '../../../core/widgets/nova_backdrop.dart';

class OnlineLoginPage extends StatefulWidget {
  final Future<void> Function(UserCredential)? onLoginSuccess;

  const OnlineLoginPage({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<OnlineLoginPage> createState() => _OnlineLoginPageState();
}

class _OnlineLoginPageState extends State<OnlineLoginPage> {
  bool loading = false;
  String? error;

  Future<void> signInWithGoogle() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Firebase sign-in only works where a native SDK exists. On
      // desktop `signInWithProvider` is unsupported, so the browser
      // flow is the only option there - which also means the app id in
      // firebase_config.dart being Android-specific is irrelevant on a
      // PC and must not block the desktop.
      final bool nativeSignIn =
          !kIsWeb &&
          (Platform.isAndroid || Platform.isIOS) &&
          FirebaseService().isAvailable;

      if (nativeSignIn) {
        try {
          final credential =
              await FirebaseService().signInWithGoogle();

          if (!mounted) return;

          setState(() {
            loading = false;
          });

          await widget.onLoginSuccess?.call(credential);
          return;
        } catch (e) {
          // Some devices have no working Google Play Services, so
          // Firebase falls back to a browser flow that fails with
          // "missing initial state". The server's own OAuth flow needs
          // no Play Services at all, so fall through to it rather than
          // leaving the user stuck on an opaque Google error page.
          debugPrint(
            'Firebase sign-in unavailable ($e); '
            'falling back to server sign-in',
          );

          if (!mounted) return;

          setState(() {
            loading = true;
          });
        }
      }

      // Browser sign-in through our server.
      final launched = await launchUrl(
        Uri.parse('${OnlineConfig.serverUrl}/auth/google'),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw StateError(
          'Could not open the browser. Open '
          '${OnlineConfig.serverUrl}/auth/google manually.',
        );
      }

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Dart prefixes its exceptions ("Bad state: ...", "Exception: ..."),
      // which reads badly in a user-facing banner.
      String text = e.toString();
      for (final String prefix in <String>[
        'Bad state: ',
        'StateError: ',
        'Exception: ',
        'PlatformException',
      ]) {
        if (text.startsWith(prefix)) {
          text = text.substring(prefix.length);
        }
      }

      setState(() {
        loading = false;
        error = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NovaScreen(
      child: Center(
        child: SingleChildScrollView(
          // The card is intrinsically taller than a short window, so it
          // has to be allowed to scroll rather than overflow.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.public_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Pulsar Online',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Connect with friends and family anywhere.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : signInWithGoogle,
                      icon: const Icon(
                        Icons.account_circle_rounded,
                      ),
                      label: Text(
                        loading
                            ? 'Signing in...'
                            : 'Continue with Google',
                      ),
                    ),
                  ),

                  if (error != null) ...<Widget>[
                    const SizedBox(height: 20),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: NovaColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}