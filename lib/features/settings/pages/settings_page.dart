import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ============================================================
  // PULSAR CHAT APP INFORMATION
  // ============================================================

  static const String appName = 'PULSAR CHAT';
  static const String appVersion = '1.0.0';

  // ============================================================
  // GITHUB UPDATE CONFIGURATION
  // ============================================================
  //
  // IMPORTANT:
  // Change these two values to your REAL GitHub repository.
  //
  // Example:
  // githubOwner = 'PULSARADVTECH';
  // githubRepository = 'pulsar-chat';
  //
  // The repository must have GitHub Releases enabled.
  //

  static const String githubOwner = 'babarsecretcracker';
  static const String githubRepository = 'PULSAR-PRODUCT';

  static const String githubReleasesUrl =
      'https://github.com/$githubOwner/$githubRepository/releases';

  bool _checkingForUpdates = false;

  // ============================================================
  // CHECK FOR GITHUB UPDATE
  // ============================================================

  Future<void> _checkForUpdates() async {
    if (_checkingForUpdates) return;

    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final client = HttpClient();

      final request = await client.getUrl(
        Uri.parse(
          'https://api.github.com/repos/'
          '$githubOwner/$githubRepository/releases/latest',
        ),
      );

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'PULSAR-CHAT',
      );

      final response = await request.close();

      final body = await response.transform(utf8.decoder).join();

      client.close();

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception(
          'GitHub returned HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(body);

      final String latestVersion =
          _cleanVersion(data['tag_name']?.toString() ?? '');

      final String releaseName =
          data['name']?.toString() ?? 'PULSAR CHAT Update';

      final String releaseUrl =
          data['html_url']?.toString() ?? githubReleasesUrl;

      if (latestVersion.isEmpty) {
        throw Exception('GitHub release has no valid version tag.');
      }

      final comparison = _compareVersions(
        latestVersion,
        appVersion,
      );

      if (!mounted) return;

      if (comparison > 0) {
        _showUpdateAvailable(
          latestVersion: latestVersion,
          releaseName: releaseName,
          releaseUrl: releaseUrl,
        );
      } else {
        _showMessage(
          'PULSAR CHAT is up to date.',
        );
      }
    } catch (e) {
  if (!mounted) return;

  String message;

  if (e.toString().contains('SocketException') ||
      e.toString().contains('api.github.com') ||
      e.toString().contains('semaphore timeout') ||
      e.toString().contains('Connection')) {
    message =
        'Could not connect to GitHub.\n'
        'Please check your internet connection and try again.';
  } else if (e.toString().contains('404')) {
    message =
        'Update repository was not found.\n'
        'Please check the GitHub repository settings.';
  } else {
    message = 'Could not check for updates. Please try again.';
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFF3A1515),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      content: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  }

  // ============================================================
  // VERSION HELPERS
  // ============================================================

  String _cleanVersion(String version) {
    var value = version.trim();

    if (value.startsWith('v')) {
      value = value.substring(1);
    }

    return value;
  }

  int _compareVersions(
    String first,
    String second,
  ) {
    final a = _cleanVersion(first)
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    final b = _cleanVersion(second)
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    while (a.length < 3) {
      a.add(0);
    }

    while (b.length < 3) {
      b.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (a[i] > b[i]) return 1;
      if (a[i] < b[i]) return -1;
    }

    return 0;
  }

  // ============================================================
  // OPEN GITHUB RELEASE PAGE
  // ============================================================

  Future<void> _openRelease(String url) async {
    try {
      await Process.start(
        'cmd',
        [
          '/c',
          'start',
          '',
          url,
        ],
        runInShell: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not open the release page.\n\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // UPDATE DIALOG
  // ============================================================

  void _showUpdateAvailable({
    required String latestVersion,
    required String releaseName,
    required String releaseUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                color: Color(0xFF8B83FF),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                releaseName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Current version: $appVersion',
                style: const TextStyle(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Latest version: $latestVersion',
                style: const TextStyle(
                  color: Color(0xFF9C95FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'A newer version of PULSAR CHAT is available.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Later',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _openRelease(releaseUrl);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 18,
              ),
              label: const Text('View Update'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? const Color(0xFF7A2525) : const Color(0xFF242424),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Manage PULSAR CHAT',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // APPLICATION
                // ==================================================

                _sectionTitle('Application'),

                const SizedBox(height: 12),

                _settingsCard(
                  children: [
                    _infoRow(
                      icon: Icons.apps_rounded,
                      title: 'App Name',
                      value: appName,
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.new_releases_outlined,
                      title: 'Version',
                      value: appVersion,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ==================================================
                // UPDATES
                // ==================================================

                _sectionTitle('Updates'),

                const SizedBox(height: 12),

                _settingsCard(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF)
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: Color(0xFF8B83FF),
                        ),
                      ),
                      title: const Text(
                        'Check for Updates',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'Check GitHub for a newer version of PULSAR CHAT.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: _checkingForUpdates
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Color(0xFF6C63FF),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed:
                                  _checkForUpdates,
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF6C63FF),
                                foregroundColor:
                                    Colors.white,
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                              ),
                              label:
                                  const Text('Check'),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ==================================================
                // ABOUT
                // ==================================================

                _sectionTitle('About'),

                const SizedBox(height: 12),

                _settingsCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.public_rounded,
                              color: Color(0xFF8B83FF),
                              size: 32,
                            ),
                          ),

                          const SizedBox(width: 18),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Local messaging for your network.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '© 2026 PULSAR TECH',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white54,
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}