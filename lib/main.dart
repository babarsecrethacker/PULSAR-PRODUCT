import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'core/config/firebase_config.dart';
import 'core/config/online_config.dart';
import 'core/services/websocket_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/app_settings.dart';
import 'core/services/recent_contacts_service.dart';
import 'core/services/single_instance_guard.dart';
import 'core/services/tray_service.dart';
import 'core/services/unread_service.dart';
import 'core/services/window_service.dart';
import 'core/theme/nova_theme.dart';
import 'core/widgets/app_intro.dart';

import 'features/home/pages/home_shell.dart';
import 'features/profile/username_setup_page.dart';
import 'features/online/pages/connection_mode_page.dart';
import 'features/online/pages/online_login_page.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> _registerPulsarProtocol() async {
  if (!Platform.isWindows) return;

  try {
    final appPath = Platform.resolvedExecutable;

    const protocolKey = r'HKCU\Software\Classes\pulsar';
    const commandKey =
        r'HKCU\Software\Classes\pulsar\shell\open\command';

    await Process.run('reg.exe', [
      'ADD',
      protocolKey,
      '/ve',
      '/t',
      'REG_SZ',
      '/d',
      'URL:PULSAR Protocol',
      '/f',
    ]);

    await Process.run('reg.exe', [
      'ADD',
      protocolKey,
      '/v',
      'URL Protocol',
      '/t',
      'REG_SZ',
      '/d',
      '',
      '/f',
    ]);

    await Process.run('reg.exe', [
      'ADD',
      commandKey,
      '/ve',
      '/t',
      'REG_SZ',
      '/d',
      '"$appPath" "%1"',
      '/f',
    ]);

    debugPrint('✅ PULSAR URL protocol registered');
    debugPrint('Executable: $appPath');
  } catch (e) {
    debugPrint('⚠️ PULSAR protocol registration failed: $e');
  }
}

/// Extracts a `pulsar://` deep link from the process arguments, if any.
String? _protocolUriFrom(List<String> args) {
  for (final String arg in args) {
    if (arg.toLowerCase().startsWith('pulsar://')) return arg;
  }
  return null;
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final String? launchUri = _protocolUriFrom(args);

  // A second launch hands focus back to the copy that already owns the
  // tray icon and then quits, rather than dying with no window at all.
  final bool isPrimary = await SingleInstanceGuard.tryAcquire(
    pendingUri: launchUri,
  );

  if (!isPrimary) {
    exit(0);
  }

  // window_manager and tray_manager are desktop-only plugins. Calling
  // them on Android throws MissingPluginException, and because this
  // runs before runApp() the app would never draw a frame - which shows
  // up as a blank white screen rather than an error.
  final bool desktop =
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  if (desktop) {
    await windowManager.ensureInitialized();
  }

  if (!kIsWeb && Platform.isWindows) {
    await _registerPulsarProtocol();

    // A minimum window size keeps the sidebar and conversation list from
    // collapsing into unreadable slivers on small displays.
    await windowManager.setMinimumSize(
      const Size(1024, 680),
    );

    // Closing the window now hides it to the notification area instead
    // of terminating, so the app keeps receiving messages.
    await WindowService.setPreventClose(true);
    await WindowService.listenOnClose(_handleWindowClose);
  }

  await RecentContactsService.instance.load();

  if (desktop) {
    await TrayService.instance.initialize(
      tooltip: 'Pulsar Chat',
    );

    // Raised by a duplicate launch: bring the existing window forward.
    SingleInstanceGuard.onWakeRequest = () {
      TrayService.instance.showWindow();
      TrayService.instance.action.value = TrayAction.open;
    };

    // A duplicate launch that carried a pulsar:// URI (the Google OAuth
    // response) must hand it to this process, otherwise the login ticket
    // is lost and sign-in silently never completes.
    SingleInstanceGuard.onUriRequest = (String uri) {
      TrayService.instance.showWindow();
      NovaAppController.handleExternalUri(uri);
    };
  }

  // This process may itself have been started by the protocol handler.
  if (launchUri != null) {
    NovaAppController.handleExternalUri(launchUri);
  }

  runApp(const NovaApp());
}

/// Returns true when the close was consumed and the window should stay
/// open (hidden to tray); false lets the window actually close.
Future<bool> _handleWindowClose() async {
  return TrayService.instance.hideToTray();
}

class NovaApp extends StatefulWidget {
  const NovaApp({super.key});

  @override
  State<NovaApp> createState() => _NovaAppState();
}

/// Carries a deep link from `main()` to the widget that knows how to
/// handle it.
///
/// The URI can arrive before `runApp` (this process was itself started
/// by the protocol handler) or long after (a second copy forwarded it),
/// so the value is parked until the state registers a handler.
class NovaAppController {
  const NovaAppController._();

  static String? _pendingUri;
  static void Function(String uri)? _handler;

  static void handleExternalUri(String uri) {
    final void Function(String uri)? handler = _handler;

    if (handler == null) {
      _pendingUri = uri;
      return;
    }

    handler(uri);
  }

  static void _register(void Function(String uri) handler) {
    _handler = handler;

    final String? pending = _pendingUri;

    if (pending != null) {
      _pendingUri = null;
      handler(pending);
    }
  }
}

class _NovaAppState extends State<NovaApp> {
  String? username;
  String? email;
  String? firebaseUid;
  String? sessionToken;
  int? currentUserId;

  bool? isOnline;
  bool onlineLoggedIn = false;
  bool sessionLoaded = false;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _appLinksSubscription;

  /// Pending tray request, consumed by the shell on its next build.
  TrayAction? _trayAction;

  /// Conversation id requested from the tray, if any.
  String? _trayContactId;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    AppSettings.instance.addListener(_onSettingsChanged);
    AppSettings.instance.load();

    TrayService.instance.action.addListener(_onTrayAction);

    // Take delivery of any deep link that arrived before the tree was
    // built, and keep listening for ones forwarded later.
    NovaAppController._register((String uri) {
      _handleLoginCallback(Uri.parse(uri));
    });

    _initializeApp();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    // Rebuild so the new accent and text scale are picked up by
    // MaterialApp immediately.
    setState(() {});
  }

  /// A tray menu item was chosen. The shell owns navigation, so the
  /// request is forwarded down rather than handled here.
  void _onTrayAction() {
    _trayAction = TrayService.instance.action.value;
    TrayService.instance.action.value = null;
  }

  Future<void> _initializeApp() async {
    await _initializeFirebase();

    await _loadSavedSession();

    if (!mounted) return;

    await _listenForLoginCallback();

    if (!mounted) return;

    await _checkFirebaseAuthState();
  }

  Future<void> _initializeFirebase() async {
    final bool configured =
        !FirebaseConfig.apiKey.startsWith('YOUR_') &&
        !FirebaseConfig.appId.startsWith('YOUR_') &&
        FirebaseConfig.messagingSenderId.isNotEmpty;

    var ready = false;

    try {
      // Android throws a PlatformException (not a FirebaseException) when
      // google-services.json is absent, which previously fell straight
      // past the explicit-options path and left Firebase unusable.
      await Firebase.initializeApp();
      ready = true;
    } catch (e) {
      if (!configured) {
        debugPrint(
          'Firebase options are not configured; skipping.',
        );
        return;
      }
    }

    if (!ready && configured) {
      try {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: FirebaseConfig.apiKey,
            appId: FirebaseConfig.appId,
            messagingSenderId: FirebaseConfig.messagingSenderId,
            projectId: FirebaseConfig.projectId,
            authDomain: FirebaseConfig.authDomain,
            databaseURL: FirebaseConfig.databaseURL,
            storageBucket: FirebaseConfig.storageBucket,
          ),
        );
        debugPrint('Firebase initialised with explicit options.');
        ready = true;
      } catch (e) {
        debugPrint('⚠️ Firebase initialisation skipped: $e');
      }
    }

    if (!ready) return;

    // The app being initialised is not enough: FirebaseService.initialize
    // is what wires up messaging, the database and the permission
    // prompts, and it is what flips isAvailable. Without it every
    // Firebase feature stayed switched off - including the sign-in path
    // the login page chooses.
    await FirebaseService().initialize();
  }

  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString('pulsar_mode');
    final savedUsername =
        prefs.getString('pulsar_username');
    final savedEmail =
        prefs.getString('pulsar_email');
    final savedUserId =
        prefs.getInt('pulsar_user_id');
    final savedFirebaseUid =
        prefs.getString('pulsar_firebase_uid');
    final savedSessionToken =
        prefs.getString('pulsar_session_token');

    final savedOnlineLogin =
        prefs.getBool('pulsar_online_logged_in') ??
            false;

    // A session stored before the server issued reusable session tokens
    // has nothing to authenticate the WebSocket with. Restoring it
    // produced a permanently offline "logged in" state that only a
    // logout could clear, so it is treated as needing sign-in again.
    final bool sessionCanConnect =
        savedSessionToken != null &&
        savedSessionToken!.isNotEmpty;

    final bool needsReauth =
        savedMode == 'online' &&
        savedOnlineLogin &&
        !sessionCanConnect;

    if (!mounted) return;

    setState(() {
      username = savedUsername;
      email = savedEmail;
      currentUserId = savedUserId;
      firebaseUid = savedFirebaseUid;
      sessionToken = savedSessionToken;

      if (savedMode == 'online' &&
          savedOnlineLogin &&
          !needsReauth) {
        isOnline = true;
        onlineLoggedIn = true;
      } else if (savedMode == 'lan') {
        isOnline = false;
        onlineLoggedIn = false;
      } else if (needsReauth) {
        // Keep online mode selected, but require sign-in again.
        isOnline = true;
        onlineLoggedIn = false;
      } else {
        isOnline = null;
        onlineLoggedIn = false;
      }

      sessionLoaded = true;
    });

    if (needsReauth) {
      debugPrint(
        '⚠️ Stored online session has no credential; '
        'signing in again is required.',
      );

      await prefs.remove('pulsar_online_logged_in');
      return;
    }

    if (savedMode == 'lan' &&
        savedUsername != null &&
        savedUsername.isNotEmpty) {
      // Not awaited: restoring a session must not block startup, and a
      // failure here is handled inside connect().
      unawaited(connectLan(savedUsername));
    }

    // Re-open the online socket on startup. Without this the app
    // restored a "logged in" session but stayed permanently offline.
    if (savedMode == 'online' &&
        savedOnlineLogin &&
        savedUserId != null) {
      await _connectOnlineSocket(
        userId: savedUserId,
        sessionToken: savedSessionToken,
      );
    }
  }

  Future<void> _checkFirebaseAuthState() async {
    if (!FirebaseService().isAvailable) return;

    try {
      final firebaseUser = FirebaseService().currentUser;
      if (firebaseUser != null) {
        await _exchangeFirebaseTokenAndLogin(firebaseUser);
      }
    } catch (e) {
      debugPrint('❌ Firebase auth state check failed: $e');
    }
  }

  Future<void> _exchangeFirebaseTokenAndLogin(User user) async {
    try {
      final idToken = await user.getIdToken();

      final response = await http.post(
        Uri.parse('${OnlineConfig.serverUrl}/auth/firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Firebase login failed: ${response.statusCode}',
        );
        return;
      }

      final data = jsonDecode(response.body);
      final name = data['name']?.toString().trim();
      final returnedEmail = data['email']?.toString().trim();
      final userId = data['user_id'] as int?;
      final firebaseUid =
          data['firebase_uid']?.toString();

      if (name != null && name.isNotEmpty && userId != null && firebaseUid != null) {
        final prefs = await SharedPreferences.getInstance();

        final issuedToken =
            data['session_token']?.toString();

        if (issuedToken != null && issuedToken.isNotEmpty) {
          await prefs.setString(
            'pulsar_session_token',
            issuedToken,
          );
        }

        await prefs.setString('pulsar_mode', 'online');
        await prefs.setString('pulsar_username', name);
        if (returnedEmail != null && returnedEmail.isNotEmpty) {
          await prefs.setString('pulsar_email', returnedEmail);
        }
        await prefs.setBool('pulsar_online_logged_in', true);
        await prefs.setInt('pulsar_user_id', userId);
        await prefs.setString('pulsar_firebase_uid', firebaseUid);

        await FirebaseService().saveUserProfile(
          userId: userId,
          name: name,
          email: returnedEmail ?? '',
        );

        // Register FCM token
        await FirebaseService().registerFCMToken();

        if (!mounted) return;

        setState(() {
          username = name;
          email = returnedEmail;
          currentUserId = userId;
          this.firebaseUid = firebaseUid;
          this.sessionToken = issuedToken ?? sessionToken;
          isOnline = true;
          onlineLoggedIn = true;
          sessionLoaded = true;
        });

        // Connect WebSocket with firebase_uid
        WebSocketService().connectWithFirebaseUid(
          firebaseUid: firebaseUid,
          userId: userId,
          // The session token issued at login is what authenticates
          // the socket. Without it the server treats the client as an
          // anonymous LAN peer with id 0, and its messages cannot be
          // saved - which is why they stayed stuck on "pending".
          sessionToken: issuedToken ?? sessionToken,
        );

        // Start listening to Firebase presence
        FirebaseService().startPresenceListener(userId);
      }
    } catch (e) {
      debugPrint('❌ Firebase token exchange failed: $e');
    }
  }

  Future<void> _listenForLoginCallback() async {
    try {
      final initialUri =
          await _appLinks.getInitialLink();

      if (initialUri != null) {
        await _handleLoginCallback(initialUri);
      }
    } catch (e) {
      debugPrint(
        'Initial PULSAR link error: $e',
      );
    }

    _appLinksSubscription =
        _appLinks.uriLinkStream.listen(
      (uri) {
        _handleLoginCallback(uri);
      },
      onError: (error) {
        debugPrint(
          'PULSAR link error: $error',
        );
      },
    );
  }

  Future<void> switchMode() async {
    final prefs = await SharedPreferences.getInstance();

    // Disconnect current LAN connection.
    WebSocketService().disconnect();

    // Clear the saved login/session.
    await prefs.remove('pulsar_mode');
    await prefs.remove('pulsar_username');
    await prefs.remove('pulsar_email');
    await prefs.remove('pulsar_online_logged_in');
    await prefs.remove('pulsar_user_id');
    await prefs.remove('pulsar_firebase_uid');
    await prefs.remove('pulsar_session_token');

    // Tear down live listeners before leaving online mode, otherwise the
    // presence stream and socket keep pushing state into a page that is
    // being replaced - which is what produced the visible glitch when
    // switching modes.
    FirebaseService().stopPresenceListener();
    UnreadService.instance.reset();
    RecentContactsService.instance.clear();

    if (!mounted) return;

    setState(() {
      username = null;
      email = null;
      currentUserId = null;
      firebaseUid = null;
      sessionToken = null;
      isOnline = null;
      onlineLoggedIn = false;
      sessionLoaded = true;
    });
  }

  Future<void> _handleLoginCallback(Uri uri) async {
    debugPrint(
      'PULSAR callback received: $uri',
    );

    if (uri.scheme != 'pulsar') return;
    if (uri.host != 'auth') return;
    if (uri.path != '/callback') return;

    final ticket =
        uri.queryParameters['ticket'];

    if (ticket == null || ticket.isEmpty) {
      debugPrint(
        '❌ Missing login ticket',
      );
      return;
    }

    try {
      final client = HttpClient();

      final request = await client.getUrl(
        Uri.parse(
          '${OnlineConfig.serverUrl}/auth/google/exchange'
          '?ticket=${Uri.encodeComponent(ticket)}',
        ),
      );

      final response = await request.close();

      final body =
          await response
              .transform(utf8.decoder)
              .join();

      client.close();

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Login exchange failed: '
          '${response.statusCode}',
        );
        debugPrint(body);
        return;
      }

      final data = jsonDecode(body);

      final name =
          data['name']?.toString().trim();

      final returnedEmail =
          data['email']?.toString().trim();

      // Reusable credential for the WebSocket. The login ticket is
      // single-use, so without this the socket upgrade has nothing to
      // authenticate with and messaging silently fails.
      final sessionToken =
          data['session_token']?.toString().trim();

      if (name == null || name.isEmpty) {
        debugPrint(
          '❌ Google account has no name',
        );
        return;
      }

      debugPrint(
        '================================',
      );
      debugPrint(
        '✅ PULSAR ONLINE LOGIN SUCCESS',
      );
      debugPrint('Name: $name');
      debugPrint('Email: $returnedEmail');
      debugPrint(
        '================================',
      );

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'pulsar_mode',
        'online',
      );

      await prefs.setString(
        'pulsar_username',
        name,
      );

      if (returnedEmail != null &&
          returnedEmail.isNotEmpty) {
        await prefs.setString(
          'pulsar_email',
          returnedEmail,
        );
      }

      await prefs.setBool(
        'pulsar_online_logged_in',
        true,
      );

      // The server resolves this during the exchange; the HTTP lookup
      // below is only a fallback for older servers.
      int? userId = (data['user_id'] as num?)?.toInt();

      if (userId == null || userId <= 0) {
        if (returnedEmail != null && returnedEmail.isNotEmpty) {
          try {
            final response = await http.get(
              Uri.parse(
                '${OnlineConfig.serverUrl}/users'
                '?q=${Uri.encodeComponent(returnedEmail)}',
              ),
            );
            if (response.statusCode == 200) {
              final users = jsonDecode(response.body)['users'];
              if (users is List) {
                for (final user in users) {
                  if (user is Map &&
                      user['email']
                              ?.toString()
                              .toLowerCase() ==
                          returnedEmail.toLowerCase()) {
                    userId = (user['id'] as num?)?.toInt();
                    break;
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ Failed to fetch user ID: $e');
          }
        }
      }

      if (userId != null) {
        await prefs.setInt('pulsar_user_id', userId);
      }

      if (sessionToken != null && sessionToken.isNotEmpty) {
        await prefs.setString(
          'pulsar_session_token',
          sessionToken,
        );
      }

      if (!mounted) return;

      setState(() {
        username = name;
        email = returnedEmail;
        currentUserId = userId;
        isOnline = true;
        onlineLoggedIn = true;
        sessionLoaded = true;
      });

      // The OAuth path used to finish here without opening a socket, so
      // the app looked signed in but could not send or receive anything.
      if (userId != null) {
        await _connectOnlineSocket(
          userId: userId,
          sessionToken: sessionToken,
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Login callback error: $e',
      );
    }
  }

  /// Opens the online WebSocket with whichever credential is available.
  ///
  /// A Firebase UID is NOT required. Google-OAuth accounts never get one
  /// (it is only ever written by the Firebase login endpoint), and
  /// bailing out here is what left every OAuth user permanently unable
  /// to connect or send. The session token is a complete credential on
  /// its own, so an empty uid is sent as a placeholder and the server
  /// authenticates on the session.
  Future<void> _connectOnlineSocket({
    required int userId,
    String? sessionToken,
  }) async {
    final String uid =
        (firebaseUid != null && firebaseUid!.isNotEmpty)
            ? firebaseUid!
            : 'session';

    try {
      await WebSocketService().connectWithFirebaseUid(
        firebaseUid: uid,
        userId: userId,
        sessionToken: sessionToken,
      );
    } catch (e) {
      debugPrint('❌ Online socket connection failed: $e');

      // Do not leave the UI claiming to be online when the socket
      // could not be opened; the retry logic in WebSocketService takes
      // it from here.
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _appLinksSubscription?.cancel();
    AppSettings.instance.removeListener(_onSettingsChanged);
    FirebaseService().dispose();
    super.dispose();
  }

  Future<void> connectLan(String name) async {
    debugPrint(
      '===== LAN CONNECT CALLED =====',
    );
    debugPrint('Username: $name');

    // Awaited so a failure reaches the caller. It used to be fire and
    // forget, so a failure left the naming screen stuck on "connecting".
    await WebSocketService().connect(
      username: name,
    );
  }

  void selectLan() {
    setState(() {
      isOnline = false;
      onlineLoggedIn = false;
    });
  }

  void selectOnline() {
    setState(() {
      isOnline = true;
    });
  }

  Future<void> completeLanSetup(
    String name,
  ) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'pulsar_mode',
      'lan',
    );

    await prefs.setString(
      'pulsar_username',
      cleanName,
    );

    await prefs.setBool(
      'pulsar_online_logged_in',
      false,
    );

    await connectLan(cleanName);

    if (!mounted) return;

    setState(() {
      username = cleanName;
      isOnline = false;
      onlineLoggedIn = false;
      sessionLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = AppSettings.instance;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pulsar Chat',
      // One ThemeData per family. The accent picker only applies to the
      // original violet theme: the other three have designed accents
      // (notably WhatsApp's green) that an override would undo.
      theme: NovaTheme.build(
        family: settings.themeFamily,
        accent: settings.themeFamily == NovaThemeFamily.purple
            ? settings.accentColor
            : null,
      ),
      builder: (BuildContext context, Widget? child) {
        // Apply the user's text size preference across the whole tree.
        final MediaQueryData data = MediaQuery.of(context);

        return MediaQuery(
          data: data.copyWith(
            textScaler: TextScaler.linear(
              settings.textScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AppIntro(
        child: Builder(
          builder: (BuildContext context) => _buildStartup(),
        ),
      ),
    );
  }

  Widget _buildStartup() {
    if (!sessionLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // MODE SELECTION
    if (isOnline == null) {
      return ConnectionModePage(
        onLanSelected: selectLan,
        onOnlineSelected: selectOnline,
      );
    }

    // ONLINE MODE
    if (isOnline == true) {
      if (!onlineLoggedIn) {
        return OnlineLoginPage(
          onLoginSuccess: _onFirebaseLoginSuccess,
        );
      }

      return HomeShell(
        username: username ?? 'User',
        currentUserId: currentUserId ?? 0,
        onSwitchMode: switchMode,
        trayAction: _trayAction,
        trayContactId: _trayContactId,
        onTrayActionHandled: _clearTrayAction,
      );
    }

    // LAN MODE
    if (username == null ||
        username!.isEmpty) {
      return UsernameSetupPage(
        onComplete: completeLanSetup,
      );
    }

    return HomeShell(
      username: username!,
      currentUserId: 0,
      onSwitchMode: switchMode,
      trayAction: _trayAction,
      trayContactId: _trayContactId,
      onTrayActionHandled: _clearTrayAction,
    );
  }

  void _clearTrayAction() {
    _trayAction = null;
    _trayContactId = null;
  }

  Future<void> _onFirebaseLoginSuccess(
    UserCredential credential,
  ) async {
    await _exchangeFirebaseTokenAndLogin(credential.user!);
  }
}
