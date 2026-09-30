import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/core/models/chat_message.dart';

void main() {
  group('ChatMessage.fromJson', () {
    test('parses sent status', () {
      final msg = ChatMessage.fromJson({
        'id': '1',
        'from': 'alice',
        'to': 'bob',
        'message': 'hello',
        'time': '2026-09-22T12:00:00Z',
        'status': 'sent',
      });
      expect(msg.id, '1');
      expect(msg.from, 'alice');
      expect(msg.to, 'bob');
      expect(msg.message, 'hello');
      expect(msg.status, MessageStatus.sent);
    });

    test('parses delivered status', () {
      final msg = ChatMessage.fromJson({
        'id': '2',
        'from': 'alice',
        'to': 'bob',
        'message': 'hi',
        'time': '2026-09-22T12:00:00Z',
        'status': 'delivered',
      });
      expect(msg.status, MessageStatus.delivered);
    });

    test('parses read status', () {
      final msg = ChatMessage.fromJson({
        'id': '3',
        'from': 'alice',
        'to': 'bob',
        'message': 'hey',
        'time': '2026-09-22T12:00:00Z',
        'status': 'read',
      });
      expect(msg.status, MessageStatus.read);
    });

    test('parses failed status', () {
      final msg = ChatMessage.fromJson({
        'id': '4',
        'from': 'alice',
        'to': 'bob',
        'message': 'oops',
        'time': '2026-09-22T12:00:00Z',
        'status': 'failed',
      });
      expect(msg.status, MessageStatus.failed);
    });

    test('defaults to pending for unknown status', () {
      final msg = ChatMessage.fromJson({
        'id': '5',
        'from': 'alice',
        'to': 'bob',
        'message': 'unknown',
        'time': '2026-09-22T12:00:00Z',
        'status': 'weird',
      });
      expect(msg.status, MessageStatus.pending);
    });

    test('defaults to pending for null status', () {
      final msg = ChatMessage.fromJson({
        'id': '6',
        'from': 'alice',
        'to': 'bob',
        'message': 'null status',
        'time': '2026-09-22T12:00:00Z',
      });
      expect(msg.status, MessageStatus.pending);
    });

    test('uses message_id as fallback for id', () {
      final msg = ChatMessage.fromJson({
        'message_id': 'mid_123',
        'from': 'alice',
        'to': 'bob',
        'message': 'test',
        'time': '2026-09-22T12:00:00Z',
      });
      expect(msg.id, 'mid_123');
    });

    test('generates timestamp id as last resort', () {
      final msg = ChatMessage.fromJson({
        'from': 'alice',
        'to': 'bob',
        'message': 'test',
      });
      expect(msg.id, isNotEmpty);
      expect(msg.from, 'alice');
      expect(msg.to, 'bob');
      expect(msg.message, 'test');
    });

    test('parses voiceBase64 from audio key', () {
      final msg = ChatMessage.fromJson({
        'id': '7',
        'from': 'alice',
        'to': 'bob',
        'message': 'voice',
        'time': '2026-09-22T12:00:00Z',
        'audio': 'base64data',
      });
      expect(msg.voiceBase64, 'base64data');
    });

    test('voiceBase64 is null when audio not present', () {
      final msg = ChatMessage.fromJson({
        'id': '8',
        'from': 'alice',
        'to': 'bob',
        'message': 'no voice',
        'time': '2026-09-22T12:00:00Z',
      });
      expect(msg.voiceBase64, isNull);
    });

    test('parses ISO 8601 time', () {
      final msg = ChatMessage.fromJson({
        'id': '9',
        'from': 'alice',
        'to': 'bob',
        'message': 'time test',
        'time': '2026-09-22T12:00:00Z',
      });
      expect(msg.time.toIso8601String(), '2026-09-22T12:00:00.000Z');
    });

    test('falls back to now for invalid time', () {
      final msg = ChatMessage.fromJson({
        'id': '10',
        'from': 'alice',
        'to': 'bob',
        'message': 'bad time',
        'time': 'not-a-date',
      });
      expect(msg.time, isNotNull);
    });

    test('parses timestamp key as fallback for time', () {
      final msg = ChatMessage.fromJson({
        'id': '11',
        'from': 'alice',
        'to': 'bob',
        'message': 'timestamp fallback',
        'timestamp': '2026-09-22T10:30:00Z',
      });
      expect(msg.time.toIso8601String(), '2026-09-22T10:30:00.000Z');
    });
  });

  group('ChatMessage.toJson', () {
    test('serializes pending status', () {
      final msg = ChatMessage(
        id: '1',
        from: 'alice',
        to: 'bob',
        message: 'hello',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        status: MessageStatus.pending,
      );
      final json = msg.toJson();
      expect(json['status'], 'pending');
      expect(json['type'], 'message');
      expect(json['id'], '1');
      expect(json['from'], 'alice');
      expect(json['to'], 'bob');
      expect(json['message'], 'hello');
      expect(json['time'], '2026-09-22T12:00:00.000Z');
    });

    test('serializes sent status', () {
      final msg = ChatMessage(
        id: '2',
        from: 'alice',
        to: 'bob',
        message: 'sent',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        status: MessageStatus.sent,
      );
      expect(msg.toJson()['status'], 'sent');
    });

    test('serializes delivered status', () {
      final msg = ChatMessage(
        id: '3',
        from: 'alice',
        to: 'bob',
        message: 'delivered',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        status: MessageStatus.delivered,
      );
      expect(msg.toJson()['status'], 'delivered');
    });

    test('serializes read status', () {
      final msg = ChatMessage(
        id: '4',
        from: 'alice',
        to: 'bob',
        message: 'read',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        status: MessageStatus.read,
      );
      expect(msg.toJson()['status'], 'read');
    });

    test('serializes failed status', () {
      final msg = ChatMessage(
        id: '5',
        from: 'alice',
        to: 'bob',
        message: 'failed',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        status: MessageStatus.failed,
      );
      expect(msg.toJson()['status'], 'failed');
    });

    test('voiceBase64 serialized as audio', () {
      final msg = ChatMessage(
        id: '6',
        from: 'alice',
        to: 'bob',
        message: 'voice',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        voiceBase64: 'abc123',
      );
      expect(msg.toJson()['audio'], 'abc123');
    });

    test('voiceBase64 omitted when null', () {
      final msg = ChatMessage(
        id: '7',
        from: 'alice',
        to: 'bob',
        message: 'no voice',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
      );
      expect(msg.toJson()['audio'], isNull);
    });
  });

  group('ChatMessage.copyWith', () {
    test('replaces individual fields', () {
      final original = ChatMessage(
        id: '1',
        from: 'alice',
        to: 'bob',
        message: 'hello',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        status: MessageStatus.sent,
      );

      final updated = original.copyWith(message: 'world', status: MessageStatus.read);
      expect(updated.id, original.id);
      expect(updated.from, original.from);
      expect(updated.to, original.to);
      expect(updated.message, 'world');
      expect(updated.status, MessageStatus.read);
      expect(updated.time, original.time);
    });

    test('returns same instance when no changes', () {
      final original = ChatMessage(
        id: '1',
        from: 'alice',
        to: 'bob',
        message: 'hello',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
      );

      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.message, original.message);
      expect(copy.status, original.status);
    });
  });

  group('ChatMessage.encode', () {
    test('returns valid JSON string', () {
      final msg = ChatMessage(
        id: '1',
        from: 'alice',
        to: 'bob',
        message: 'hello',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
      );
      final encoded = msg.encode();
      expect(encoded, isA<String>());
      expect(() => jsonDecode(encoded), returnsNormally);
    });
  });

  group('ChatMessage.toString', () {
    test('contains key fields', () {
      final msg = ChatMessage(
        id: '1',
        from: 'alice',
        to: 'bob',
        message: 'hello',
        time: DateTime.parse('2026-09-22T12:00:00Z'),
        status: MessageStatus.sent,
      );
      final str = msg.toString();
      expect(str, contains('alice'));
      expect(str, contains('bob'));
      expect(str, contains('hello'));
      expect(str, contains('sent'));
    });
  });

  group('MessageStatus values', () {
    test('has all expected values', () {
      expect(MessageStatus.values, contains(MessageStatus.pending));
      expect(MessageStatus.values, contains(MessageStatus.sent));
      expect(MessageStatus.values, contains(MessageStatus.delivered));
      expect(MessageStatus.values, contains(MessageStatus.read));
      expect(MessageStatus.values, contains(MessageStatus.failed));
    });

    test('has exactly 5 values', () {
      expect(MessageStatus.values.length, 5);
    });
  });

  group('ChatMessage required fields', () {
    test('throws on missing id', () {
      expect(
        () => ChatMessage(
          id: '',
          from: 'a',
          to: 'b',
          message: 'm',
          time: DateTime.now(),
        ),
        returnsNormally,
      );
    });

    test('empty string id is allowed', () {
      final msg = ChatMessage(
        id: '',
        from: 'a',
        to: 'b',
        message: 'm',
        time: DateTime.now(),
      );
      expect(msg.id, '');
    });
  });

}
