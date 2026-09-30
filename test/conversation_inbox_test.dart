import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/core/services/conversation_inbox_service.dart';

/// The inbox is what makes a message that arrived while the user was
/// away visible, and what keeps conversations alive across restarts.
/// The server is the source of truth, so parsing its payload is the
/// critical part.
void main() {
  group('ConversationInboxEntry.fromJson', () {
    test('parses a full server row', () {
      final entry = ConversationInboxEntry.fromJson(
        <String, dynamic>{
          'conversation_id': 4,
          'other_id': 2,
          'other_name': 'Babar Business',
          'other_email': 'babarbusiness99@gmail.com',
          'other_picture': 'https://example.com/p.png',
          'other_online': true,
          'last_message': 'hey',
          'last_sender_id': 1,
          'last_at': '2026-09-28T05:26:34.352Z',
          'unread': 4,
        },
      );

      expect(entry.conversationId, 4);
      expect(entry.otherId, 2);
      expect(entry.otherName, 'Babar Business');
      expect(entry.otherOnline, isTrue);
      expect(entry.lastMessage, 'hey');
      expect(entry.lastSenderId, 1);
      expect(entry.lastAt, isNotNull);
      expect(entry.unread, 4);
    });

    test('unread of zero is preserved, not treated as missing', () {
      final entry = ConversationInboxEntry.fromJson(
        <String, dynamic>{
          'conversation_id': 1,
          'other_id': 3,
          'unread': 0,
        },
      );

      expect(entry.unread, 0);
    });

    test('survives a row with no last message', () {
      final entry = ConversationInboxEntry.fromJson(
        <String, dynamic>{
          'conversation_id': 1,
          'other_id': 3,
          'last_message': '',
          'last_at': '',
          'unread': 0,
        },
      );

      expect(entry.lastMessage, '');
      expect(entry.lastAt, isNull);
    });

    test('falls back to a placeholder name', () {
      final entry = ConversationInboxEntry.fromJson(
        <String, dynamic>{'other_id': 7, 'other_name': ''},
      );

      expect(entry.contact.name, isNotEmpty);
    });

    test('exposes a contact keyed by the numeric id', () {
      // The chat list and ChatPage key off contact.id, so it must be
      // the numeric account id as a string, matching what discovery
      // produces.
      final entry = ConversationInboxEntry.fromJson(
        <String, dynamic>{'other_id': 2, 'other_name': 'Bob'},
      );

      expect(entry.contact.id, '2');
      expect(entry.contact.name, 'Bob');
    });

    test('online state is reflected on the contact', () {
      final offline = ConversationInboxEntry.fromJson(
        <String, dynamic>{'other_id': 2, 'other_online': false},
      );
      final online = ConversationInboxEntry.fromJson(
        <String, dynamic>{'other_id': 2, 'other_online': true},
      );

      expect(offline.contact.online, isFalse);
      expect(online.contact.online, isTrue);
    });
  });
}
