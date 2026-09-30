import 'dart:io';

import 'package:window_manager/window_manager.dart';

/// Thin, mockable wrapper over [WindowManager].
///
/// Tray and window behaviour is easy to get subtly wrong (especially the
/// minimize/restore ordering that stops a window being restored behind
/// the taskbar), so all of it is funnelled through this one place.
class WindowService {
  const WindowService._();

  static Future<bool> isMinimized() async {
    if (!Platform.isWindows && !Platform.isMacOS &&
        !Platform.isLinux) {
      return false;
    }
    return windowManager.isMinimized();
  }

  static Future<bool> isVisible() async {
    if (!Platform.isWindows && !Platform.isMacOS &&
        !Platform.isLinux) {
      return true;
    }
    return windowManager.isVisible();
  }

  static Future<void> restore() async {
    if (!await windowManager.isVisible()) {
      await windowManager.show();
    }
    await windowManager.restore();
  }

  static Future<void> show() => windowManager.show();

  static Future<void> hide() => windowManager.hide();

  static Future<void> focus() => windowManager.focus();

  static Future<void> setPreventClose(bool prevent) =>
      windowManager.setPreventClose(prevent);

  /// Registers the close interception used for close-to-tray.
  static Future<void> listenOnClose(
    Future<bool> Function() handler,
  ) async {
    windowManager.addListener(_CloseInterceptor(handler));
  }

  /// Releases the whole window; call this only on a real exit.
  static Future<void> destroy() async {
    // Bypass the prevent-close guard, otherwise the window manager
    // refuses to quit and the process lingers.
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}

class _CloseInterceptor extends WindowListener {
  _CloseInterceptor(this._handler);

  final Future<bool> Function() _handler;

  @override
  void onWindowClose() {
    _handler();
  }
}
