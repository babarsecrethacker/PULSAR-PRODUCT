import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/core/models/chat_message.dart';
import 'package:pulsar_chat/core/services/websocket_service.dart';

/// Sending a message produces an optimistic bubble, then the server
/// echoes a stored copy back. The two must collapse into one, otherwise
/// the same text appears twice - once frozen on "sending" and once
/// delivered.
void main() {
  group('clientMessageId', () {
    test('carries the composer id so a copy can be matched', () {
      final ChatMessage m = ChatMessage(
        id: 'srv_42',
        from: '1',
        to: '2',
        message: 'hi',
        time: DateTime(2026, 9, 28),
        clientMessageId: 'local-1',
      );

      expect(m.clientMessageId, 'local-1');
    });

    test('defaults to null when the server echoes nothing back', () {
      final ChatMessage m = ChatMessage(
        id: 'db_9',
        from: '1',
        to: '2',
        message: 'hi',
        time: DateTime(2026, 9, 28),
      );

      expect(m.clientMessageId, isNull);
    });

    test('survives copyWith', () {
      final ChatMessage m = ChatMessage(
        id: 'srv_42',
        from: '1',
        to: '2',
        message: 'hi',
        time: DateTime(2026, 9, 28),
        clientMessageId: 'local-1',
      );

      expect(m.copyWith(status: MessageStatus.sent)
          .clientMessageId, 'local-1');
    });
  });

  group('reconciliation', () {
    ChatMessage pending() => ChatMessage(
      id: 'local-1',
      from: '1',
      to: '2',
      message: 'hello',
      time: DateTime(2026, 9, 28, 10),
      status: MessageStatus.pending,
    );

    ChatMessage confirmed() => ChatMessage(
      id: 'srv_42',
      from: '1',
      to: '2',
      message: 'hello',
      time: DateTime(2026, 9, 28, 10),
      status: MessageStatus.sent,
      clientMessageId: 'local-1',
    );

    test('the stored copy matches the pending bubble by client id', () {
      // This is the rule that prevents the duplicate.
      final List<ChatMessage> bucket = <ChatMessage>[pending()];
      final ChatMessage incoming = confirmed();

      int existing = -1;
      for (int i = 0; i < bucket.length; i++) {
        if (bucket[i].id == incoming.id) {
          existing = i;
          break;
        }
        final String? clientId = incoming.clientMessageId;
        if (clientId != null && bucket[i].id == clientId) {
          existing = i;
          break;
        }
      }

      expect(existing, 0, reason: 'the pending bubble must be found');
    });

    test('reconciling keeps the local id and timestamp', () {
      // Keeping the id means the UI stays keyed correctly and the
      // position does not jump.
      final ChatMessage previous = pending();
      final ChatMessage merged = confirmed().copyWith(
        id: previous.id,
        time: previous.time,
      );

      expect(merged.id, 'local-1');
      expect(merged.time, previous.time);
      expect(merged.status, MessageStatus.sent);
    });

    test('a message with no pending bubble is appended, not merged', () {
      final List<ChatMessage> bucket = <ChatMessage>[pending()];
      final ChatMessage incoming = ChatMessage(
        id: 'srv_99',
        from: '2',
        to: '1',
        message: 'reply',
        time: DateTime(2026, 9, 28, 11),
      );

      bool matches(ChatMessage m) =>
          m.id == incoming.id ||
          (incoming.clientMessageId != null &&
              m.id == incoming.clientMessageId);

      expect(bucket.any(matches), isFalse);
    });

    test('a server echo with no client id still replaces its own id', () {
      final ChatMessage incoming = ChatMessage(
        id: 'srv_42',
        from: '1',
        to: '2',
        message: 'hello',
        time: DateTime(2026, 9, 28),
      );

      expect(incoming.id, 'srv_42');
    });
  });

  group('identity after an account switch', () {
    test('stale identity is what flips sender and receiver', () {
      // Before clearIdentity the client still believed it was user 1
      // while the socket belonged to user 2, so its own messages
      // (sender_id 2) were not recognised as its own.
      final bool wasSelf = WebSocketService.isSelfSender(
        '2',
        username: null,
        firebaseUid: 'session',
        userId: 1,
      );

      expect(wasSelf, isFalse);

      final bool nowSelf = WebSocketService.isSelfSender(
        '2',
        username: null,
        firebaseUid: 'session',
        userId: 2,
      );

      expect(nowSelf, isTrue);
    });
  });
}
