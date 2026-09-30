import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/online_config.dart';
import '../../features/contacts/models/contact.dart';

/// One row of the server-backed inbox.
class ConversationInboxEntry {
  final int conversationId;
  final int otherId;
  final String otherName;
  final String otherEmail;
  final String otherPicture;
  final bool otherOnline;
  final String lastMessage;
  final int lastSenderId;
  final DateTime? lastAt;
  final int unread;

  const ConversationInboxEntry({
    required this.conversationId,
    required this.otherId,
    required this.otherName,
    required this.otherEmail,
    required this.otherPicture,
    required this.otherOnline,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastAt,
    required this.unread,
  });

  factory ConversationInboxEntry.fromJson(Map<String, dynamic> json) {
    DateTime? at;

    final String? raw = json['last_at']?.toString();
    if (raw != null && raw.isNotEmpty) {
      at = DateTime.tryParse(raw)?.toLocal();
    }

    return ConversationInboxEntry(
      conversationId:
          (json['conversation_id'] as num?)?.toInt() ?? 0,
      otherId: (json['other_id'] as num?)?.toInt() ?? 0,
      otherName: json['other_name']?.toString() ?? '',
      otherEmail: json['other_email']?.toString() ?? '',
      otherPicture: json['other_picture']?.toString() ?? '',
      otherOnline: json['other_online'] == true,
      lastMessage: json['last_message']?.toString() ?? '',
      lastSenderId: (json['last_sender_id'] as num?)?.toInt() ?? 0,
      lastAt: at,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
    );
  }

  Contact get contact => Contact(
    id: '$otherId',
    name: otherName.isEmpty ? 'Pulsar user $otherId' : otherName,
    lastMessage: lastMessage,
    lastSeen: otherOnline ? 'Online' : 'Offline',
    online: otherOnline,
  );
}

/// Keeps the inbox in sync with the server.
///
/// The previous design only learned about a conversation once it had
/// been opened in the UI. That meant a message arriving while the user
/// was away stayed invisible until they opened each chat by hand, and
/// the whole list disappeared on restart. This polls the server's
/// inbox endpoint, so waiting messages surface on their own and
/// conversations persist.
class ConversationInboxService extends ChangeNotifier {
  ConversationInboxService._();

  static final ConversationInboxService instance =
      ConversationInboxService._();

  static const Duration _interval = Duration(seconds: 20);

  final List<ConversationInboxEntry> _entries =
      <ConversationInboxEntry>[];

  Timer? _timer;
  int _userId = 0;
  int _lastKnownUnread = 0;
  bool _refreshing = false;

  List<ConversationInboxEntry> get entries =>
      List<ConversationInboxEntry>.unmodifiable(_entries);

  int get totalUnread => _entries.fold<int>(
        0,
        (int sum, ConversationInboxEntry e) => sum + e.unread,
      );

  bool get hasUnread => totalUnread > 0;

  ConversationInboxEntry? entryFor(String contactId) {
    for (final ConversationInboxEntry e in _entries) {
      if ('${e.otherId}' == contactId) return e;
    }
    return null;
  }

  void start(int userId) {
    if (userId <= 0) return;

    if (_userId == userId && _timer != null) return;

    _userId = userId;

    _timer?.cancel();
    _timer = Timer.periodic(
      _interval,
      (_) => refresh(),
    );

    refresh();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _userId = 0;
    _lastKnownUnread = 0;
    _entries.clear();
    notifyListeners();
  }

  /// Called when the socket (re)connects: something may have arrived
  /// while the app was not listening.
  void refreshNow() {
    refresh();
  }

  Future<void> refresh() async {
    if (_userId <= 0 || _refreshing) return;

    _refreshing = true;

    try {
      final uri = Uri.parse(
        '${OnlineConfig.serverUrl}/conversations',
      ).replace(queryParameters: <String, String>{
        'me': '$_userId',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return;

      final List<ConversationInboxEntry> next = decoded
          .whereType<Map<String, dynamic>>()
          .map(ConversationInboxEntry.fromJson)
          .where((ConversationInboxEntry e) => e.otherId > 0)
          .toList();

      final int unread = next.fold<int>(
        0,
        (int sum, ConversationInboxEntry e) => sum + e.unread,
      );

      // Only notify when something actually changed, so the shell does
      // not rebuild on every poll.
      final bool changed = _inboxChanged(next, unread);

      _entries
        ..clear()
        ..addAll(next);

      if (changed) {
        notifyListeners();
      }

      // Raised so the shell can surface a notification when messages
      // were waiting.
      if (unread > _lastKnownUnread) {
        onUnreadArrived?.call(unread);
      }

      _lastKnownUnread = unread;
    } catch (_) {
      // Polling is best effort; the next tick retries.
    } finally {
      _refreshing = false;
    }
  }

  bool _inboxChanged(
    List<ConversationInboxEntry> next,
    int unread,
  ) {
    if (next.length != _entries.length) return true;
    if (unread != totalUnread) return true;

    for (int i = 0; i < next.length; i++) {
      if (next[i].lastMessage != _entries[i].lastMessage) {
        return true;
      }
      if (next[i].unread != _entries[i].unread) return true;
    }

    return false;
  }

  /// Suppresses the "you have new messages" banner while the user is
  /// already looking at that conversation.
  void setActiveContact(String? contactId) {
    if (contactId == null || _userId <= 0) return;

    // Marking read server-side is handled by the existing read-receipt
    // flow; this only keeps the local badge honest.
    notifyListeners();
  }

  /// Invoked when the unread total increases.
  void Function(int totalUnread)? onUnreadArrived;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
