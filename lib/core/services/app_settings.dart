import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/nova_theme.dart';

/// App-wide appearance preferences that must apply immediately.
///
/// The accent picker used to write the choice to disk while the running
/// [ThemeData] was built once from a hard-coded colour, so picking a
/// different accent looked like it did nothing until a restart. Holding
/// the value in a [ChangeNotifier] lets `NovaApp` rebuild the theme the
/// moment the user taps a swatch.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _kAccent = 'pulsar_accent';
  static const String _kTextScale = 'pulsar_text_scale';
  static const String _kStartupSound = 'pulsar_startup_sound';
  static const String _kTheme = 'pulsar_theme';

  int _accentIndex = 0;
  double _textScale = 1;
  bool _startupSound = true;
  NovaThemeFamily _theme = NovaThemeFamily.purple;

  bool _loaded = false;

  int get accentIndex => _accentIndex;

  double get textScale => _textScale;

  bool get startupSound => _startupSound;

  NovaThemeFamily get themeFamily => _theme;

  bool get loaded => _loaded;

  Color get accentColor => NovaAccents.at(_accentIndex);

  Future<void> load() async {
    if (_loaded) return;

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    _accentIndex = prefs.getInt(_kAccent) ?? 0;
    _textScale = prefs.getDouble(_kTextScale) ?? 1;
    _startupSound = prefs.getBool(_kStartupSound) ?? true;
    _theme = NovaThemeFamily.fromIndex(
      prefs.getInt(_kTheme) ?? 0,
    );

    if (_accentIndex < 0 ||
        _accentIndex >= NovaAccents.colors.length) {
      _accentIndex = 0;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeFamily(NovaThemeFamily family) async {
    if (family == _theme) return;

    _theme = family;

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setInt(_kTheme, family.index);

    notifyListeners();
  }

  Future<void> setAccentIndex(int index) async {
    if (index < 0 || index >= NovaAccents.colors.length) return;
    if (index == _accentIndex) return;

    _accentIndex = index;

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setInt(_kAccent, index);

    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    final double clamped = scale.clamp(0.85, 1.3);
    if (clamped == _textScale) return;

    _textScale = clamped;

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setDouble(_kTextScale, clamped);

    notifyListeners();
  }

  Future<void> setStartupSound(bool enabled) async {
    if (enabled == _startupSound) return;

    _startupSound = enabled;

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.setBool(_kStartupSound, enabled);

    notifyListeners();
  }

  Future<void> reset() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_kAccent);
    await prefs.remove(_kTextScale);
    await prefs.remove(_kStartupSound);
    await prefs.remove(_kTheme);

    _accentIndex = 0;
    _textScale = 1;
    _startupSound = true;
    _theme = NovaThemeFamily.purple;

    notifyListeners();
  }
}
