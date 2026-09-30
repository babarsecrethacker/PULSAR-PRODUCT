import 'dart:async';
import 'dart:io';

/// Guards against a second copy of the app starting.
///
/// This matters specifically because of the tray icon: Windows gives a
/// second process its own notification-area slot, and the tray plugin's
/// hidden window cannot be created twice, so a duplicate launch used to
/// die silently with no window and no explanation. Now the duplicate
/// detects the primary, asks it to come forward, and exits quietly.
///
/// A named mutex would be the textbook approach, but the `win32`
/// bindings available here do not expose `CreateMutex`/`OpenEvent`, so
/// this uses a process check plus a flag file for the wake-up signal.
class SingleInstanceGuard {
  const SingleInstanceGuard._();

  static Timer? _poll;

  /// Returns true when this process is the primary and should continue
  /// starting up. Returns false when another copy already owns the tray,
  /// in which case [pendingUri] is forwarded to it and the caller must
  /// exit.
  static Future<bool> tryAcquire({
    String? pendingUri,
  }) async {
    if (!Platform.isWindows) return true;

    final int others = await _countOtherInstances();

    if (others == 0) {
      _startWatchingForWakeRequests();
      return true;
    }

    // Ask the copy that is already running to surface its window, and
    // pass along any protocol URI it was launched with.
    await _signalPrimary(pendingUri);

    return false;
  }

  /// Number of live copies of this executable, excluding this process.
  static Future<int> _countOtherInstances() async {
    final String exe = Platform.resolvedExecutable;
    final String name =
        exe.split(Platform.pathSeparator).last.toLowerCase();

    try {
      final ProcessResult result = await Process.run(
        'tasklist',
        <String>['/FI', 'IMAGENAME eq $name', '/NH', '/FO', 'CSV'],
        runInShell: true,
      );

      if (result.exitCode != 0) return 0;

      final List<String> lines = (result.stdout as String)
          .split(RegExp(r'\r?\n'))
          .where((String l) => l.trim().isNotEmpty)
          .toList();

      // Everything is this app, so any live line other than us is a
      // duplicate.
      return (lines.length - 1).clamp(0, 999);
    } catch (_) {
      // If the check cannot run, let the app start rather than trapping
      // the user out of their own application.
      return 0;
    }
  }

  static File get _flagFile {
    final String base = Platform.environment['LOCALAPPDATA'] ??
        Directory.systemTemp.path;

    return File(
      '$base${Platform.pathSeparator}PulsarChat'
      '${Platform.pathSeparator}second-instance.flag',
    );
  }

  /// Hands a payload to the copy that already owns the tray.
  ///
  /// This matters for more than just raising the window. Windows
  /// activates a custom protocol by starting a *new* process with the
  /// URI in argv, so a running app would otherwise never see its own
  /// `pulsar://auth/callback?ticket=...` login response. Discarding that
  /// process silently breaks Google sign-in completely.
  static Future<void> _signalPrimary([String? payload]) async {
    try {
      final File flag = _flagFile;

      if (!flag.parent.existsSync()) {
        flag.parent.createSync(recursive: true);
      }

      flag.writeAsStringSync(
        payload ?? '',
        flush: true,
      );
    } catch (_) {
      // Best effort only.
    }
  }

  /// Watches for a second launch asking us to come forward.
  static void _startWatchingForWakeRequests() {
    _poll?.cancel();

    _poll = Timer.periodic(
      const Duration(milliseconds: 600),
      (Timer _) => _checkWakeRequest(),
    );
  }

  static void _checkWakeRequest() {
    try {
      final File flag = _flagFile;

      if (!flag.existsSync()) return;

      // Remove it first so a rapid second launch is not swallowed.
      final String payload = flag.readAsStringSync().trim();
      flag.deleteSync();

      if (payload.isNotEmpty) {
        onUriRequest?.call(payload);
      }

      onWakeRequest?.call();
    } catch (_) {
      // Ignore: the next tick will retry.
    }
  }

  /// Invoked when another copy of the app was launched.
  static void Function()? onWakeRequest;

  /// Invoked with a protocol URI a second copy was launched with.
  static void Function(String uri)? onUriRequest;

  static void dispose() {
    _poll?.cancel();
    _poll = null;
  }
}
