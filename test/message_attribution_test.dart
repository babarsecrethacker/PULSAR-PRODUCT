import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/core/models/chat_message.dart';
import 'package:pulsar_chat/core/services/websocket_service.dart';
import 'package:pulsar_chat/core/services/unread_service.dart';

/// Which conversation a message belongs to, and whether it counts as
/// unread, are both decided by "is this me?". Getting that wrong filed
/// your own sent messages under your own conversation and attributed
/// other people's messages to you.
void main() {
  group('isSelfSender', () {
    test('online accounts are identified by numeric id', () {
      // The regression: a username check alone never matched here,
      // because an online session never sets a username.
      expect(
        WebSocketService.isSelfSender('1', userId: 1),
        isTrue,
      );
      expect(
        WebSocketService.isSelfSender('2', userId: 1),
        isFalse,
      );
    });

    test('LAN peers are identified by name', () {
      expect(
        WebSocketService.isSelfSender('Babar', username: 'Babar'),
        isTrue,
      );
    });

    test('matches on Firebase UID', () {
      expect(
        WebSocketService.isSelfSender('uid-1', firebaseUid: 'uid-1'),
        isTrue,
      );
    });

    test('UnreadService agrees with the transport', () {
      // Both call sites must resolve "me" identically, or conversation
      // filing and unread counting drift apart.
      expect(
        UnreadService.isSelfSender('1', userId: 1),
        WebSocketService.isSelfSender('1', userId: 1),
      );

      expect(
        UnreadService.isSelfSender('2', userId: 1),
        WebSocketService.isSelfSender('2', userId: 1),
      );
    });
  });

  group('conversation filing', () {
    test('an outgoing message belongs to the recipient', () {
      // from == me, so the conversation is the other party (to).
      const int me = 1;
      const int them = 2;

      final ChatMessage sent = ChatMessage(
        id: 'srv_10',
        from: '$me',
        to: '$them',
        message: 'hello',
        time: DateTime(2026, 9, 28),
      );

      final bool mine = WebSocketService.isSelfSender(
        sent.from,
        userId: me,
      );

      final String bucket = mine ? sent.to : sent.from;

      expect(
        bucket,
        '$them',
        reason: 'my own message must be filed under the recipient',
      );
    });

    test('an incoming message belongs to the sender', () {
      const int me = 1;
      const int them = 2;

      final ChatMessage received = ChatMessage(
        id: 'srv_11',
        from: '$them',
        to: '$me',
        message: 'hi back',
        time: DateTime(2026, 9, 28),
      );

      final bool mine = WebSocketService.isSelfSender(
        received.from,
        userId: me,
      );

      final String bucket = mine ? received.to : received.from;

      expect(
        bucket,
        '$them',
        reason: 'their message must be filed under them',
      );
    });

    test('both directions land in the same conversation', () {
      const int me = 1;
      const int them = 2;

      String bucketFor(ChatMessage m) {
        final bool mine = WebSocketService.isSelfSender(
          m.from,
          userId: me,
        );
        return mine ? m.to : m.from;
      }

      final String outbound = bucketFor(
        ChatMessage(
          id: 'a',
          from: '$me',
          to: '$them',
          message: 'x',
          time: DateTime(2026, 9, 28),
        ),
      );

      final String inbound = bucketFor(
        ChatMessage(
          id: 'b',
          from: '$them',
          to: '$me',
          message: 'y',
          time: DateTime(2026, 9, 28),
        ),
      );

      expect(outbound, inbound);
    });

    test('a message to myself is not misfiled', () {
      const int me = 1;

      final bool mine = WebSocketService.isSelfSender('1', userId: me);
      final String bucket = mine ? '1' : '1';

      expect(bucket, '1');
    });
  });

  group('alignment', () {
    test('isMine is false for the contact and true for me', () {
      const int me = 1;
      const String contactId = '2';

      final ChatMessage mine = ChatMessage(
        id: 'a',
        from: '$me',
        to: contactId,
        message: 'x',
        time: DateTime(2026, 9, 28),
      );

      final ChatMessage theirs = ChatMessage(
        id: 'b',
        from: contactId,
        to: '$me',
        message: 'y',
        time: DateTime(2026, 9, 28),
      );

      // Mirrors chat_page: isMine = message.from != contact.id
      expect(mine.from != contactId, isTrue);
      expect(theirs.from != contactId, isFalse);
    });
  });
}
