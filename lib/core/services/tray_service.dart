import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tray_manager/tray_manager.dart';

import 'recent_contacts_service.dart';
import 'window_service.dart';

/// What the user asked for from the tray menu.
enum TrayAction {
  open,
  settings,
  checkUpdates,
  openConversation,
  quit,
}

/// Bridges the Windows notification-area icon to the Flutter app.
///
/// The tray owns no UI of its own: it publishes the chosen [TrayAction]
/// and the shell reacts, so navigation stays in one place.
class TrayService with TrayListener {
  TrayService._();

  static final TrayService instance = TrayService._();

  /// The tray plugin only exists on desktop. Every platform channel call
  /// is routed through this so mobile does not raise
  /// MissingPluginException at runtime.
  static bool get isSupported =>
      !kIsWeb &&
      (Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux);

  static const String _kSettings = 'settings';
  static const String _kUpdates = 'updates';
  static const String _kExit = 'exit';
  static const String _kOpen = 'open';
  static const String _kRecentPrefix = 'recent:';

  final ValueNotifier<TrayAction?> action =
      ValueNotifier<TrayAction?>(null);

  /// Id of the conversation requested from the tray, valid only while
  /// [action] is [TrayAction.openConversation].
  final ValueNotifier<String?> requestedContactId =
      ValueNotifier<String?>(null);

  bool _ready = false;
  bool _quitting = false;

  bool get isReady => _ready;

  bool get isQuitting => _quitting;

  /// Creates the tray icon. Windows needs a real file path, so the icon
  /// is written out of the asset bundle to a temp file first - that keeps
  /// it working in both `flutter run` and a packaged build.
  Future<void> initialize({String? tooltip}) async {
    if (_ready) return;

    if (!isSupported) {
      debugPrint(
        'Tray icon is desktop only; skipping on this platform.',
      );
      return;
    }

    try {
      final String iconPath = await _materialiseIcon();

      await TrayManager.instance.setIcon(iconPath);
      await TrayManager.instance.setToolTip(
        tooltip ?? 'Pulsar Chat',
      );

      TrayManager.instance.addListener(this);

      RecentContactsService.instance.addListener(_onRecentsChanged);

      // Must be set before the first refreshMenu: that method bails out
      // when not ready, so setting it afterwards meant setContextMenu
      // was never called and the tray had no menu to show.
      _ready = true;

      await refreshMenu();
    } catch (e) {
      debugPrint('Tray initialisation failed: $e');
    }
  }

  Future<String> _materialiseIcon() async {
    final Directory dir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}pulsar_tray',
    );

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final File file = File(
      '${dir.path}${Platform.pathSeparator}app_icon.ico',
    );

    if (!file.existsSync()) {
      final ByteData data =
          await rootBundle.load('assets/icon/app_icon.ico');

      await file.writeAsBytes(
        data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
        flush: true,
      );
    }

    return file.path;
  }

  void _onRecentsChanged() {
    refreshMenu();
  }

  // -------------------------------------------------------------------
  // MENU
  // -------------------------------------------------------------------

  Future<void> refreshMenu() async {
    if (!_ready || !isSupported) return;

    final List<RecentContact> recents =
        RecentContactsService.instance.contacts;

    final List<MenuItem> items = <MenuItem>[
      MenuItem(
        key: _kOpen,
        label: 'Open Pulsar Chat',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'recent_header',
        label: 'Recent',
        disabled: true,
      ),
    ];

    if (recents.isEmpty) {
      items.add(
        MenuItem(
          key: 'recent_empty',
          label: 'No recent conversations',
          disabled: true,
        ),
      );
    } else {
      for (final RecentContact c in recents) {
        items.add(
          MenuItem(
            key: '$_kRecentPrefix${c.id}',
            label: c.name,
          ),
        );
      }
    }

    items
      ..add(MenuItem.separator())
      ..add(
        MenuItem(
          key: _kSettings,
          label: 'Settings',
        ),
      )
      ..add(
        MenuItem(
          key: _kUpdates,
          label: 'Check for Updates',
        ),
      )
      ..add(MenuItem.separator())
      ..add(
        MenuItem(
          key: _kExit,
          label: 'Exit',
        ),
      );

    try {
      await TrayManager.instance.setContextMenu(
        Menu(items: items),
      );
    } catch (e) {
      debugPrint('Failed to update tray menu: $e');
    }
  }

  // -------------------------------------------------------------------
  // TRAY LISTENER
  // -------------------------------------------------------------------

  @override
  void onTrayIconMouseDown() {}

  /// Windows does not display a tray context menu on its own - the
  /// plugin requires Dart to ask for it explicitly, so the right-click
  /// handler does nothing without this call.
  @override
  void onTrayIconRightMouseDown() {
    if (!_ready) return;

    // No bringAppToFront: that parameter is deprecated, and on Windows
    // the main window must stay behind the menu.
    TrayManager.instance.popUpContextMenu().catchError((Object e) {
      debugPrint('Failed to pop up tray menu: $e');
    });
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayIconMouseUp() {
    // Left click brings the window forward, matching platform
    // expectation for taskbar-style icons.
    showWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final String? key = menuItem.key;
    if (key == null) return;

    if (key == _kExit) {
      quit();
      return;
    }

    if (key == _kOpen) {
      showWindow();
      action.value = TrayAction.open;
      return;
    }

    if (key == _kSettings) {
      // Restore first, otherwise the navigation happens off-screen.
      showWindow();
      action.value = TrayAction.settings;
      return;
    }

    if (key == _kUpdates) {
      showWindow();
      action.value = TrayAction.checkUpdates;
      return;
    }

    if (key.startsWith(_kRecentPrefix)) {
      final String id = key.substring(_kRecentPrefix.length);
      showWindow();
      requestedContactId.value = id;
      action.value = TrayAction.openConversation;
    }
  }

  // -------------------------------------------------------------------
  // WINDOW
  // -------------------------------------------------------------------

  Future<void> showWindow() async {
    if (!isSupported) return;

    // A hidden window and a minimized one need different remedies, and
    // conflating them leaves the app appearing to ignore the click.
    if (await WindowService.isMinimized()) {
      await WindowService.restore();
    }

    if (!await WindowService.isVisible()) {
      await WindowService.show();
    }

    await WindowService.focus();
  }

  /// Hides the window instead of closing it. Returns the value to give
  /// back to the platform close event.
  Future<bool> hideToTray() async {
    if (_quitting) return false;
    await WindowService.hide();
    return true;
  }

  Future<void> quit() async {
    if (_quitting) return;

    _quitting = true;

    RecentContactsService.instance.removeListener(
      _onRecentsChanged,
    );

    try {
      TrayManager.instance.removeListener(this);
      await TrayManager.instance.destroy();
    } catch (e) {
      debugPrint('Tray teardown failed: $e');
    }

    await WindowService.destroy();
  }

  void updateTooltip(String text) {
    // Desktop only. tray_manager has no Android implementation, and a
    // method-channel call there fails at runtime.
    if (!isSupported) return;

    TrayManager.instance.setToolTip(text).catchError(
      (Object _) {},
    );
  }

  void dispose() {
    RecentContactsService.instance.removeListener(
      _onRecentsChanged,
    );
    action.dispose();
    requestedContactId.dispose();
  }
}

/// Builds the tray tooltip, which doubles as a quiet unread indicator.
String trayTooltip({
  required String appName,
  required int unread,
}) {
  if (unread <= 0) return appName;
  if (unread > 99) return '$appName (99+ unread)';
  return '$appName ($unread unread)';
}
