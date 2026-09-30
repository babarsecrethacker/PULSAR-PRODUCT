import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'websocket_service.dart';

/// Tracks genuinely unread conversations in real time.
///
/// The sidebar previously rendered a hard-coded `3` badge, which looked
/// like a permanent notification but never reflected anything. This
/// listens to the real WebSocket message stream instead, so the count
/// only ever reflects messages that actually arrived and have not been
/// opened yet.
class UnreadService extends ChangeNotifier {
  UnreadService._();

  static final UnreadService instance = UnreadService._();

  final Map<String, int> _unreadByContact = <String, int>{};

  /// Conversation currently on screen. Messages for this contact never
  /// count as unread.
  String? _activeContactId;

  StreamSubscription<ChatMessage>? _subscription;

  /// Newest message per contact, used to render conversation previews.
  final Map<String, ChatMessage> _latestByContact =
      <String, ChatMessage>{};

  bool _started = false;

  int get totalUnread => _unreadByContact.values.fold<int>(
        0,
        (int sum, int value) => sum + value,
      );

  bool get hasUnread => totalUnread > 0;

  int unreadFor(String contactId) =>
      _unreadByContact[contactId] ?? 0;

  ChatMessage? latestFor(String contactId) =>
      _latestByContact[contactId];

  /// Idempotent, so it is safe to call from every rebuild path.
  void start() {
    if (_started) return;
    _started = true;

    _subscription = WebSocketService()
        .messageStream
        .listen(_onMessage);
  }

  void _onMessage(ChatMessage message) {
    ingest(message);
  }

  /// Counts [message] as unread unless it is one of ours.
  ///
  /// Exposed rather than private so the counting rules can be tested
  /// directly.
  void ingest(ChatMessage message) {
    final String sender = message.from;
    if (sender.isEmpty) return;

    final String? me = WebSocketService().myUsername;
    final String? uid = WebSocketService().myFirebaseUid;
    final int? id = WebSocketService().myUserId;

    if (isSelfSender(
      sender,
      username: me,
      firebaseUid: uid,
      userId: id,
    )) {
      return;
    }
    _latestByContact[sender] = message;

    if (_activeContactId == sender) {
      // Reading the conversation: drop it out of the badge.
      _unreadByContact.remove(sender);
    } else {
      _unreadByContact.update(
        sender,
        (int value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    notifyListeners();
  }

  /// Whether [sender] identifies this client.
  ///
  /// The server echoes a sender's own messages back to them, and it tags
  /// online senders with a numeric account id, so a username check alone
  /// is not enough - which is how sent messages ended up raising an
  /// unread badge on the sender's own conversation.
  static bool isSelfSender(
    String sender, {
    String? username,
    String? firebaseUid,
    int? userId,
  }) {
    // Single definition lives with the transport that produces these
    // messages, so conversation filing and unread counting can never
    // disagree about who "me" is.
    return WebSocketService.isSelfSender(
      sender,
      username: username,
      firebaseUid: firebaseUid,
      userId: userId,
    );
  }

  /// Marks [contactId] as read because it is now on screen.
  void setActiveContact(String? contactId) {
    if (_activeContactId == contactId) return;

    _activeContactId = contactId;

    if (contactId != null &&
        _unreadByContact.containsKey(contactId)) {
      _unreadByContact.remove(contactId);
      notifyListeners();
    }
  }

  void markAllRead() {
    if (_unreadByContact.isEmpty) return;

    _unreadByContact.clear();
    notifyListeners();
  }

  void reset() {
    _unreadByContact.clear();
    _latestByContact.clear();
    _activeContactId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
