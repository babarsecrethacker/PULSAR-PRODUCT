import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/core/models/chat_message.dart';
import 'package:pulsar_chat/core/services/unread_service.dart';

/// The server echoes a sender's own messages back to them, so the unread
/// counter has to recognise them. It previously keyed only on the socket
/// username, which online accounts never set - so every message you sent
/// raised an unread badge on your own conversation.
void main() {
  group('isSelfSender', () {
    test('matches on username for LAN peers', () {
      expect(
        UnreadService.isSelfSender('Babar', username: 'Babar'),
        isTrue,
      );
    });

    test('matches on numeric id for online accounts', () {
      // The case that was broken: an online account is tagged with its
      // numeric id, never its username.
      expect(
        UnreadService.isSelfSender('1', userId: 1),
        isTrue,
      );
    });

    test('matches on Firebase UID', () {
      expect(
        UnreadService.isSelfSender(
          'abc123',
          firebaseUid: 'abc123',
        ),
        isTrue,
      );
    });

    test('does not match somebody else', () {
      expect(
        UnreadService.isSelfSender(
          '2',
          userId: 1,
          username: 'Babar',
          firebaseUid: 'abc',
        ),
        isFalse,
      );
    });

    test('ignores a zero user id rather than matching "0"', () {
      expect(
        UnreadService.isSelfSender('0', userId: 0),
        isFalse,
      );
    });

    test('ignores empty identifiers', () {
      expect(
        UnreadService.isSelfSender(
          'Babar',
          username: '',
          firebaseUid: '',
          userId: 0,
        ),
        isFalse,
      );
    });
  });

  group('ingest', () {
    setUp(() {
      UnreadService.instance.reset();
    });

    tearDown(() {
      UnreadService.instance.reset();
    });

    ChatMessage from(String sender) => ChatMessage(
      id: 'srv_$sender',
      from: sender,
      to: 'other',
      message: 'hello',
      time: DateTime(2026, 9, 28),
    );

    test('counts a message from someone else as unread', () {
      UnreadService.instance.ingest(from('2'));

      expect(UnreadService.instance.totalUnread, 1);
      expect(UnreadService.instance.unreadFor('2'), 1);
    });

    test('stops counting once that conversation is open', () {
      UnreadService.instance.ingest(from('2'));
      expect(UnreadService.instance.totalUnread, 1);

      UnreadService.instance.setActiveContact('2');
      expect(UnreadService.instance.totalUnread, 0);
    });

    test('accumulates separate conversations', () {
      UnreadService.instance.ingest(from('2'));
      UnreadService.instance.ingest(from('2'));
      UnreadService.instance.ingest(from('3'));

      expect(UnreadService.instance.totalUnread, 3);
      expect(UnreadService.instance.unreadFor('2'), 2);
      expect(UnreadService.instance.unreadFor('3'), 1);
    });

    test('ignores a message with no sender', () {
      UnreadService.instance.ingest(from(''));
      expect(UnreadService.instance.totalUnread, 0);
    });
  });
}
