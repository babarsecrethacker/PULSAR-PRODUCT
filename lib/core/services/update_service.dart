import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Outcome of a release check.
sealed class UpdateResult {
  const UpdateResult();
}

class UpdateAvailable extends UpdateResult {
  final String latestVersion;
  final String releaseName;
  final String releaseUrl;

  const UpdateAvailable({
    required this.latestVersion,
    required this.releaseName,
    required this.releaseUrl,
  });
}

class AlreadyUpToDate extends UpdateResult {
  const AlreadyUpToDate();
}

class UpdateCheckFailed extends UpdateResult {
  final String message;

  const UpdateCheckFailed(this.message);
}

/// Checks GitHub Releases for a newer build.
///
/// Extracted from the settings page so the tray menu and the settings
/// screen share one implementation (and one place to fix the version
/// comparison) instead of duplicating the HTTP call.
class UpdateService {
  static const String appVersion = '1.0.2';
  static const String appBuild = '2';

  static const String githubOwner = 'babarsecrethacker';
  static const String githubRepository = 'PULSAR-PRODUCT';

  static const String releasesUrl =
      'https://github.com/$githubOwner/$githubRepository/releases';

  static bool _busy = false;

  /// Guards against two concurrent checks (for example the tray item
  /// pressed while the settings page is already checking).
  static bool get isChecking => _busy;

  static Future<UpdateResult> check() async {
    if (_busy) {
      return const UpdateCheckFailed(
        'An update check is already running.',
      );
    }

    _busy = true;

    final HttpClient client = HttpClient();

    try {
      final HttpClientRequest request =
          await client.getUrl(
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
        'PulsarChat',
      );

      final HttpClientResponse response =
          await request.close();

      final String body = await response
          .transform(utf8.decoder)
          .join();

      if (response.statusCode == 404) {
        return const UpdateCheckFailed(
          'Update repository not found.\n'
          'Check the GitHub repository settings.',
        );
      }

      if (response.statusCode != 200) {
        return UpdateCheckFailed(
          'GitHub returned HTTP ${response.statusCode}.',
        );
      }

      final Object? data = jsonDecode(body);

      if (data is! Map<String, dynamic>) {
        return const UpdateCheckFailed(
          'Unexpected response from GitHub.',
        );
      }

      final String latest = cleanVersion(
        data['tag_name']?.toString() ?? '',
      );

      if (latest.isEmpty) {
        return const UpdateCheckFailed(
          'The latest release has no version tag.',
        );
      }

      if (compareVersions(latest, appVersion) > 0) {
        return UpdateAvailable(
          latestVersion: latest,
          releaseName: data['name']?.toString() ??
              'Pulsar Chat $latest',
          releaseUrl:
              data['html_url']?.toString() ?? releasesUrl,
        );
      }

      return const AlreadyUpToDate();
    } on SocketException {
      return const UpdateCheckFailed(
        'Could not reach GitHub.\n'
        'Check your internet connection.',
      );
    } on HttpException {
      return const UpdateCheckFailed(
        'Could not reach GitHub.\n'
        'Check your internet connection.',
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return UpdateCheckFailed(
        'Could not check for updates.\n$e',
      );
    } finally {
      _busy = false;
      client.close();
    }
  }

  static String cleanVersion(String version) {
    String value = version.trim();

    if (value.toLowerCase().startsWith('v')) {
      value = value.substring(1);
    }

    return value.trim();
  }

  static int compareVersions(String first, String second) {
    final List<int> a = cleanVersion(first)
        .split('.')
        .map((String e) => int.tryParse(e) ?? 0)
        .toList();

    final List<int> b = cleanVersion(second)
        .split('.')
        .map((String e) => int.tryParse(e) ?? 0)
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
}
