/// Where the client looks for the Pulsar server.
///
/// The address is a compile-time constant so one source tree can produce
/// a build for a phone and a build for the desktop. It is overridable
/// without editing this file:
///
///   flutter build apk --release \
///     --dart-define=PULSAR_SERVER=http://192.168.6.104:8090
///
/// The default is the development machine's LAN address rather than
/// localhost, because `localhost` on a phone means the phone itself and
/// nothing would ever connect. The desktop app still works against the
/// same value, since the address resolves back to this machine.
class OnlineConfig {
  static const String serverUrl = String.fromEnvironment(
    'PULSAR_SERVER',
    defaultValue: 'http://192.168.6.104:8090',
  );

  /// Derived from [serverUrl] so the socket can never end up pointing
  /// somewhere else than the HTTP API.
  static String get websocketUrl =>
      serverUrl.replaceFirst(RegExp(r'^http'), 'ws') + '/ws';

  /// Shown in Settings so it is obvious which server a build talks to.
  static String get displayAddress =>
      serverUrl.replaceFirst(RegExp(r'^https?://'), '');
}
