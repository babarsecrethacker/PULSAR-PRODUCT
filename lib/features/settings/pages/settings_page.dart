import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/online_config.dart';
import '../../../core/services/app_settings.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/nova_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ============================================================
  // APP IDENTITY
  // ============================================================

  static const String appName = 'Pulsar Chat';

  // Version and release coordinates live in UpdateService so the tray
  // menu and this page can never report different numbers.
  static String get appVersion => UpdateService.appVersion;

  static String get appBuild => UpdateService.appBuild;

  static String get githubReleasesUrl => UpdateService.releasesUrl;

  bool _checkingForUpdates = false;

  // ============================================================
  // PERSISTED PREFERENCES
  // ============================================================

  static const String _kSound = 'pulsar_sound_enabled';
  static const String _kNotifications = 'pulsar_desktop_notifications';
  static const String _kPreview = 'pulsar_notification_preview';
  static const String _kReadReceipts = 'pulsar_read_receipts';
  static const String _kOnlineStatus = 'pulsar_show_online_status';
  static const String _kTyping = 'pulsar_typing_indicator';
  static const String _kEnterToSend = 'pulsar_enter_to_send';
  static const String _kAutoDownload = 'pulsar_auto_download_media';
  static const String _kAutoMarkRead = 'pulsar_auto_mark_read';
  static const String _kCheckOnStart = 'pulsar_check_update_on_start';
  static const String _kCompact = 'pulsar_compact_mode';
  static const String _kReduceMotion = 'pulsar_reduce_motion';

  // ============================================================
  // STATE
  // ============================================================

  bool _ready = false;

  bool _compact = false;
  bool _reduceMotion = false;

  bool _sound = true;
  bool _notifications = true;
  bool _preview = true;

  bool _readReceipts = true;
  bool _onlineStatus = true;
  bool _typing = true;

  bool _enterToSend = true;
  bool _autoDownload = false;
  bool _autoMarkRead = true;

  bool _checkOnStart = false;

  @override
  void initState() {
    super.initState();

    AppSettings.instance.addListener(_onSettingsChanged);

    _loadPreferences();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    // Accent and text size are applied by the app shell, so mirror the
    // new values into this page's own controls.
    setState(() {});
  }

  // ============================================================
  // LOAD / SAVE
  // ============================================================

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await AppSettings.instance.load();

    if (!mounted) return;

    setState(() {
      _compact = prefs.getBool(_kCompact) ?? false;
      _reduceMotion =
          prefs.getBool(_kReduceMotion) ?? false;
      _sound = prefs.getBool(_kSound) ?? true;
      _notifications =
          prefs.getBool(_kNotifications) ?? true;
      _preview = prefs.getBool(_kPreview) ?? true;
      _readReceipts =
          prefs.getBool(_kReadReceipts) ?? true;
      _onlineStatus =
          prefs.getBool(_kOnlineStatus) ?? true;
      _typing = prefs.getBool(_kTyping) ?? true;
      _enterToSend =
          prefs.getBool(_kEnterToSend) ?? true;
      _autoDownload =
          prefs.getBool(_kAutoDownload) ?? false;
      _autoMarkRead =
          prefs.getBool(_kAutoMarkRead) ?? true;
      _checkOnStart =
          prefs.getBool(_kCheckOnStart) ?? false;
      _ready = true;
    });
  }

  Future<void> _save<T>(
    String key,
    T value,
  ) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  // ============================================================
  // UPDATE CHECK
  // ============================================================

  Future<void> _checkForUpdates() async {
    if (_checkingForUpdates) return;

    setState(() {
      _checkingForUpdates = true;
    });

    // Shared with the tray menu so both entry points behave identically.
    final UpdateResult result = await UpdateService.check();

    if (!mounted) return;

    switch (result) {
      case UpdateAvailable(
        latestVersion: final String latest,
        releaseName: final String name,
        releaseUrl: final String url,
      ):
        _showUpdateAvailable(
          latestVersion: latest,
          releaseName: name,
          releaseUrl: url,
        );

      case AlreadyUpToDate():
        _showMessage(
          'Pulsar Chat is up to date.',
          icon: Icons.verified_outlined,
        );

      case UpdateCheckFailed(message: final String message):
        _showMessage(message, error: true);
    }

    if (!mounted) return;

    setState(() {
      _checkingForUpdates = false;
    });
  }

  Future<void> _openRelease(String url) async {
    final Uri uri = Uri.parse(url);

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      _showMessage(
        'Could not open $url',
        error: true,
      );
    }
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  void _showUpdateAvailable({
    required String latestVersion,
    required String releaseName,
    required String releaseUrl,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return AlertDialog(
          icon: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NovaColors.accent
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(
                NovaRadius.md,
              ),
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: NovaColors.accent,
              size: 24,
            ),
          ),
          title: const Text('Update available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                releaseName,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: NovaSpacing.lg),
              _VersionRow(
                label: 'Installed',
                value: appVersion,
              ),
              const SizedBox(height: NovaSpacing.sm),
              _VersionRow(
                label: 'Available',
                value: latestVersion,
                highlight: true,
              ),
              const SizedBox(height: NovaSpacing.lg),
              Text(
                'A newer build of $appName is '
                'ready to download from GitHub.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _openRelease(releaseUrl);
              },
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 17,
              ),
              label: const Text('View release'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmReset() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.restart_alt_rounded,
            color: NovaColors.warning,
          ),
          title: const Text('Reset settings'),
          content: const Text(
            'All appearance, notification and '
            'chat preferences will return to their '
            'defaults. This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: NovaColors.danger,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    for (final String key in <String>[
      _kCompact,
      _kReduceMotion,
      _kSound,
      _kNotifications,
      _kPreview,
      _kReadReceipts,
      _kOnlineStatus,
      _kTyping,
      _kEnterToSend,
      _kAutoDownload,
      _kAutoMarkRead,
      _kCheckOnStart,
    ]) {
      await prefs.remove(key);
    }

    await AppSettings.instance.reset();
    await _loadPreferences();

    if (!mounted) return;

    _showMessage(
      'Settings restored to defaults.',
      icon: Icons.restart_alt_rounded,
    );
  }

  void _showMessage(
    String message, {
    bool error = false,
    IconData icon = Icons.info_outline_rounded,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: error
                    ? NovaColors.danger
                    : NovaColors.success,
              ),
              const SizedBox(
                width: NovaSpacing.md,
              ),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color:
                            NovaColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: NovaColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 880,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                NovaSpacing.xl,
                NovaSpacing.xxl,
                NovaSpacing.xl,
                NovaSpacing.xxxl,
              ),
              children: <Widget>[
                Text(
                  'Settings',
                  style: theme.textTheme
                      .headlineMedium,
                ),
                const SizedBox(height: NovaSpacing.xs),
                Text(
                  'Customise how $appName looks and '
                  'behaves on this device.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(
                  height: NovaSpacing.xxl,
                ),

                // -------------------------------------------------
                // APPEARANCE
                // -------------------------------------------------
                const _SectionLabel('Appearance'),
                const SizedBox(
                  height: NovaSpacing.md,
                ),
                _Card(
                  children: <Widget>[
                    _InfoRow(
                      icon: Icons.dns_outlined,
                      title: 'Server',
                      value: OnlineConfig.displayAddress,
                    ),
                    const _CardDivider(),
                    _LabeledContent(
                      label: 'Theme',
                      description:
                          'Choose how Pulsar Chat looks. '
                          'Changes apply immediately.',
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: NovaSpacing.md,
                            runSpacing: NovaSpacing.md,
                            children:
                                List<Widget>.generate(
                              NovaThemeFamily.values.length,
                              (int i) => _ThemeSwatch(
                                family: NovaThemeFamily
                                    .values[i],
                                selected: AppSettings
                                        .instance
                                        .themeFamily ==
                                    NovaThemeFamily
                                        .values[i],
                                onTap: () => AppSettings
                                    .instance
                                    .setThemeFamily(
                                  NovaThemeFamily.values[i],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: NovaSpacing.md,
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              final bool isDefault =
                                  AppSettings.instance.accentIndex ==
                                      0;

                              return Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.palette_outlined,
                                    size: 17,
                                    color: NovaColors
                                        .textTertiary,
                                  ),
                                  const SizedBox(
                                    width: NovaSpacing.sm,
                                  ),
                                  Expanded(
                                    child: Text(
                                      isDefault
                                          ? 'Accent colour applies to '
                                              'the violet theme'
                                          : 'Custom accent: '
                                              '${NovaAccents.labelAt(AppSettings.instance.accentIndex)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const _CardDivider(),
                    _LabeledContent(
                      label: 'Accent colour',
                      description: AppSettings.instance.accentIndex == 0
                          ? 'Violet theme only. Other themes use '
                              'their own designed accent.'
                          : 'Used for buttons, links and '
                              'selection highlights.',
                      child: Wrap(
                        spacing: NovaSpacing.md,
                        runSpacing: NovaSpacing.md,
                        children:
                            List<Widget>.generate(
                          NovaAccents.colors.length,
                          (int i) => _AccentSwatch(
                            color: NovaAccents.colors[i],
                            label: NovaAccents.labels[i],
                            selected: AppSettings
                                    .instance
                                    .accentIndex ==
                                i,
                            onTap: () => AppSettings
                                .instance
                                .setAccentIndex(i),
                          ),
                        ),
                      ),
                    ),
                    const _CardDivider(),
                    _LabeledContent(
                      label: 'Text size',
                      description:
                          'Scales text across the whole '
                          'application.',
                      child: Builder(
                        builder: (BuildContext context) {
                          final double scale =
                              AppSettings.instance.textScale;

                          return Row(
                            children: <Widget>[
                              Text(
                                'A',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                              Expanded(
                                child: Slider(
                                  value: scale,
                                  min: 0.85,
                                  max: 1.3,
                                  divisions: 9,
                                  label: '${(scale * 100).round()}%',
                                  onChanged: (double v) =>
                                      AppSettings.instance
                                          .setTextScale(v),
                                ),
                              ),
                              Text(
                                'A',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(
                                width: NovaSpacing.md,
                              ),
                              SizedBox(
                                width: 44,
                                child: Text(
                                  '${(scale * 100).round()}%',
                                  textAlign:
                                      TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.density_small_rounded,
                      title: 'Compact layout',
                      subtitle:
                          'Tighter row heights for denser '
                          'lists.',
                      value: _compact,
                      onChanged: (bool v) {
                        setState(() {
                          _compact = v;
                        });
                        _save(_kCompact, v);
                      },
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.animation_rounded,
                      title: 'Reduce motion',
                      subtitle:
                          'Minimise background animation '
                          'and transitions.',
                      value: _reduceMotion,
                      onChanged: (bool v) {
                        setState(() {
                          _reduceMotion = v;
                        });
                        _save(_kReduceMotion, v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: NovaSpacing.xl),

                // -------------------------------------------------
                // NOTIFICATIONS
                // -------------------------------------------------
                const _SectionLabel('Notifications'),
                const SizedBox(
                  height: NovaSpacing.md,
                ),
                _Card(
                  children: <Widget>[
                    _SwitchRow(
                      icon:
                          Icons.notifications_active_rounded,
                      title: 'Desktop notifications',
                      subtitle:
                          'Show a system notification for new '
                          'messages.',
                      value: _notifications,
                      onChanged: (bool v) {
                        setState(() {
                          _notifications = v;
                        });
                        _save(_kNotifications, v);
                      },
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.volume_up_rounded,
                      title: 'Notification sound',
                      subtitle:
                          'Play a sound when a message '
                          'arrives.',
                      value: _sound,
                      onChanged: _notifications
                          ? (bool v) {
                              setState(() {
                                _sound = v;
                              });
                              _save(_kSound, v);
                            }
                          : null,
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Show message preview',
                      subtitle:
                          'Include message text in '
                          'notifications.',
                      value: _preview,
                      onChanged: _notifications
                          ? (bool v) {
                              setState(() {
                                _preview = v;
                              });
                              _save(_kPreview, v);
                            }
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: NovaSpacing.xl),

                // -------------------------------------------------
                // PRIVACY
                // -------------------------------------------------
                const _SectionLabel('Privacy'),
                const SizedBox(
                  height: NovaSpacing.md,
                ),
                _Card(
                  children: <Widget>[
                    _SwitchRow(
                      icon: Icons.done_all_rounded,
                      title: 'Read receipts',
                      subtitle:
                          'Send delivery and read status '
                          'for your messages.',
                      value: _readReceipts,
                      onChanged: (bool v) {
                        setState(() {
                          _readReceipts = v;
                        });
                        _save(_kReadReceipts, v);
                      },
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.circle_rounded,
                      title: 'Show online status',
                      subtitle:
                          'Let others see when you are '
                          'online.',
                      value: _onlineStatus,
                      onChanged: (bool v) {
                        setState(() {
                          _onlineStatus = v;
                        });
                        _save(_kOnlineStatus, v);
                      },
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.keyboard_rounded,
                      title: 'Typing indicator',
                      subtitle:
                          'Show others when you are typing.',
                      value: _typing,
                      onChanged: (bool v) {
                        setState(() {
                          _typing = v;
                        });
                        _save(_kTyping, v);
                      },
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.graphic_eq_rounded,
                      title: 'Startup sound',
                      subtitle:
                          'Play a soft ambient tone when '
                          '$appName launches.',
                      value: AppSettings.instance.startupSound,
                      onChanged: (bool v) => AppSettings
                          .instance
                          .setStartupSound(v),
                    ),
                  ],
                ),

                const SizedBox(height: NovaSpacing.xl),

                // -------------------------------------------------
                // CHAT
                // -------------------------------------------------
                const _SectionLabel('Chat'),
                const SizedBox(
                  height: NovaSpacing.md,
                ),
                _Card(
                  children: <Widget>[
                    _SwitchRow(
                      icon: Icons.keyboard_return_rounded,
                      title: 'Enter sends message',
                      subtitle:
                          'Use Enter to send instead of a '
                          'new line.',
                      value: _enterToSend,
                      onChanged: (bool v) {
                        setState(() {
                          _enterToSend = v;
                        });
                        _save(_kEnterToSend, v);
                      },
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.download_rounded,
                      title: 'Auto-download media',
                      subtitle:
                          'Download photos and files '
                          'automatically.',
                      value: _autoDownload,
                      onChanged: (bool v) {
                        setState(() {
                          _autoDownload = v;
                        });
                        _save(_kAutoDownload, v);
                      },
                    ),
                    const _CardDivider(),
                    _SwitchRow(
                      icon: Icons.mark_chat_read_rounded,
                      title: 'Mark as read on open',
                      subtitle:
                          'Mark a conversation read as soon '
                          'as you open it.',
                      value: _autoMarkRead,
                      onChanged: (bool v) {
                        setState(() {
                          _autoMarkRead = v;
                        });
                        _save(_kAutoMarkRead, v);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: NovaSpacing.xl),

                // -------------------------------------------------
                // UPDATES
                // -------------------------------------------------
                const _SectionLabel('Updates'),
                const SizedBox(
                  height: NovaSpacing.md,
                ),
                _Card(
                  children: <Widget>[
                    _SwitchRow(
                      icon: Icons.system_update_rounded,
                      title: 'Check on startup',
                      subtitle:
                          'Check GitHub for a newer build when '
                          '$appName launches.',
                      value: _checkOnStart,
                      onChanged: (bool v) {
                        setState(() {
                          _checkOnStart = v;
                        });
                        _save(_kCheckOnStart, v);
                      },
                    ),
                    const _CardDivider(),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: NovaSpacing.lg,
                        vertical: NovaSpacing.sm,
                      ),
                      leading: const _RowIcon(
                        icon: Icons.refresh_rounded,
                      ),
                      title: const Text('Check for updates'),
                      subtitle: const Text(
                        'Look for a newer release on GitHub.',
                      ),
                      trailing: _checkingForUpdates
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color:
                                  NovaColors.textTertiary,
                            ),
                      onTap: _checkingForUpdates
                          ? null
                          : _checkForUpdates,
                    ),
                  ],
                ),

                const SizedBox(height: NovaSpacing.xl),

                // -------------------------------------------------
                // ABOUT
                // -------------------------------------------------
                const _SectionLabel('About'),
                const SizedBox(
                  height: NovaSpacing.md,
                ),
                _Card(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(
                        NovaSpacing.lg,
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 56,
                            height: 56,
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                    NovaRadius.md,
                                  ),
                              border: Border.all(
                                color:
                                    NovaColors.border,
                              ),
                            ),
                            alignment:
                                Alignment.center,
                            child:
                                Image.asset(
                                  'assets/icon/pulsar.png',
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit
                                      .contain,
                                  errorBuilder: (
                                    BuildContext c,
                                    Object e,
                                    StackTrace? s,
                                  ) =>
                                      const Icon(
                                    Icons
                                        .forum_rounded,
                                    color:
                                        NovaColors.accent,
                                  ),
                                ),
                          ),
                          const SizedBox(
                            width:
                                NovaSpacing.lg,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: <Widget>[
                                Text(
                                  appName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme
                                      .titleLarge,
                                ),
                                const SizedBox(
                                  height:
                                      NovaSpacing.xs,
                                ),
                                Text(
                                  'Version $appVersion '
                                  '(build $appBuild)',
                                  style: Theme.of(
                                    context,
                                  ).textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _CardDivider(),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      title: 'Licence',
                      value: 'Copyright (C) 2026',
                    ),
                    const _CardDivider(),
                    _InfoRow(
                      icon: Icons.code_rounded,
                      title: 'Source',
                      value: 'v$appVersion',
                    ),
                    const _CardDivider(),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: NovaSpacing.lg,
                      ),
                      leading: const _RowIcon(
                        icon:
                            Icons.restart_alt_rounded,
                      ),
                      title: const Text(
                        'Reset all settings',
                      ),
                      subtitle: const Text(
                        'Restore every preference to its '
                        'default.',
                      ),
                      onTap: _confirmReset,
                    ),
                    const _CardDivider(),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: NovaSpacing.lg,
                      ),
                      leading: const _RowIcon(
                        icon:
                            Icons.open_in_new_rounded,
                      ),
                      title: const Text('Releases'),
                      subtitle: const Text(
                        'View all published versions.',
                      ),
                      onTap: () => _openRelease(
                        githubReleasesUrl,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: NovaSpacing.xl,
                ),

                Center(
                  child: Text(
                    '$appName · v$appVersion',
                    style:
                        theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUPPORTING WIDGETS
// ============================================================

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: NovaTheme.sectionLabel,
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NovaColors.surfaceRaised,
        borderRadius:
            BorderRadius.circular(NovaRadius.lg),
        border: Border.all(
          color: NovaColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 64),
      child: Divider(height: 1),
    );
  }
}

class _RowIcon extends StatelessWidget {
  final IconData icon;

  const _RowIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: NovaColors.surfaceOverlay,
        borderRadius:
            BorderRadius.circular(NovaRadius.sm),
      ),
      child: Icon(
        icon,
        size: 19,
        color: NovaColors.textSecondary,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NovaSpacing.lg,
        vertical: NovaSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          _RowIcon(icon: icon),
          const SizedBox(width: NovaSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: enabled
                            ? NovaColors.textPrimary
                            : NovaColors.textDisabled,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: enabled
                            ? NovaColors.textTertiary
                            : NovaColors.textDisabled,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NovaSpacing.lg),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NovaSpacing.lg,
        vertical: NovaSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          _RowIcon(icon: icon),
          const SizedBox(width: NovaSpacing.lg),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
          ),
          const SizedBox(width: NovaSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledContent extends StatelessWidget {
  final String label;
  final String description;
  final Widget child;

  const _LabeledContent({
    required this.label,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NovaSpacing.lg),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: NovaSpacing.xs),
          Text(
            description,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
          const SizedBox(height: NovaSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final NovaThemeFamily family;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final NovaThemeSpec spec = NovaTheme.specOf(family);

    return Tooltip(
      message: family.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NovaRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 92,
              height: 62,
              decoration: BoxDecoration(
                color: spec.canvas,
                borderRadius:
                    BorderRadius.circular(NovaRadius.md),
                border: Border.all(
                  color: selected
                      ? spec.accent
                      : Theme.of(context)
                          .colorScheme
                          .outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: <Widget>[
                  // A representative slice of the real theme, so the
                  // choice is obvious without leaving Settings.
                  Positioned(
                    left: 8,
                    top: 8,
                    bottom: 8,
                    width: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: spec.surfaceRaised,
                        borderRadius: BorderRadius.circular(
                          4,
                        ),
                        border: Border.all(
                          color: spec.border,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    right: 8,
                    top: 10,
                    child: _Bar(
                      color: spec.bubbleOther,
                      border: spec.border,
                      widthFactor: 0.85,
                    ),
                  ),
                  Positioned(
                    left: 30,
                    right: 20,
                    top: 24,
                    child: _Bar(
                      color: spec.bubbleOwn,
                      border: Colors.transparent,
                      widthFactor: 0.7,
                    ),
                  ),
                  Positioned(
                    left: 30,
                    right: 8,
                    top: 40,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: spec.accent,
                        borderRadius: BorderRadius.circular(
                          6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 92,
              child: Text(
                family.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(
                      color: selected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                          : Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final Color color;
  final Color border;
  final double widthFactor;

  const _Bar({
    required this.color,
    required this.border,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border),
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          NovaRadius.pill,
        ),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 160),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? NovaColors.textPrimary
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: selected
              ? const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _VersionRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: highlight
              ? theme.textTheme.titleMedium
                    ?.copyWith(
                      color: NovaColors.accent,
                    )
              : theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}
