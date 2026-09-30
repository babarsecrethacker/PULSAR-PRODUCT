import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A conversation the user has opened recently.
class RecentContact {
  final String id;
  final String name;

  const RecentContact({required this.id, required this.name});

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'id': id, 'name': name};

  static RecentContact? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    final String? id = raw['id']?.toString();
    final String? name = raw['name']?.toString();

    if (id == null || id.isEmpty) return null;

    return RecentContact(
      id: id,
      name: (name == null || name.isEmpty) ? id : name,
    );
  }
}

/// Remembers the most recently opened conversations so the tray menu can
/// offer one-click access to them.
class RecentContactsService extends ChangeNotifier {
  RecentContactsService._();

  static final RecentContactsService instance =
      RecentContactsService._();

  /// How many entries the tray menu shows.
  static const int maxEntries = 5;

  static const String _kKey = 'pulsar_recent_contacts';

  final List<RecentContact> _contacts = [];

  List<RecentContact> get contacts =>
      List<RecentContact>.unmodifiable(_contacts);

  Future<void> load() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String? raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _contacts
        ..clear()
        ..addAll(
          decoded
              .map(RecentContact.fromJson)
              .whereType<RecentContact>(),
        );
    } catch (_) {
      // Corrupt payload: start from an empty list rather than crash.
      _contacts.clear();
    }
  }

  /// Records [id]/[name] as the most recent conversation, moving it to
  /// the top of the list if it was already present.
  Future<void> record(String id, String name) async {
    if (id.isEmpty) return;

    _contacts.removeWhere((RecentContact c) => c.id == id);

    _contacts.insert(
      0,
      RecentContact(
        id: id,
        name: name.isEmpty ? id : name,
      ),
    );

    if (_contacts.length > maxEntries) {
      _contacts.removeRange(maxEntries, _contacts.length);
    }

    notifyListeners();

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _kKey,
      jsonEncode(
        _contacts
            .map((RecentContact c) => c.toJson())
            .toList(),
      ),
    );
  }

  Future<void> clear() async {
    _contacts.clear();
    notifyListeners();

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}
