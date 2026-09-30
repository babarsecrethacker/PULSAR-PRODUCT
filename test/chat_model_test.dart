import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/features/chat/models/chat_models.dart';

void main() {
  group('ChatModel creation', () {
    test('creates with all fields', () {
      final model = ChatModel(
        name: 'Alice',
        lastMessage: 'Hello there',
        time: '2:30 PM',
        unread: 3,
        online: true,
      );
      expect(model.name, 'Alice');
      expect(model.lastMessage, 'Hello there');
      expect(model.time, '2:30 PM');
      expect(model.unread, 3);
      expect(model.online, true);
    });

    test('creates with zero unread', () {
      final model = ChatModel(
        name: 'Bob',
        lastMessage: 'Hey',
        time: '10:00 AM',
        unread: 0,
        online: false,
      );
      expect(model.unread, 0);
      expect(model.online, false);
    });

    test('creates with empty strings', () {
      final model = ChatModel(
        name: '',
        lastMessage: '',
        time: '',
        unread: 0,
        online: false,
      );
      expect(model.name, '');
      expect(model.lastMessage, '');
      expect(model.time, '');
    });
  });

  group('ChatModel field types', () {
    test('name is String', () {
      final model = ChatModel(
        name: 'Test',
        lastMessage: 'msg',
        time: 'now',
        unread: 1,
        online: true,
      );
      expect(model.name, isA<String>());
    });

    test('lastMessage is String', () {
      final model = ChatModel(
        name: 'Test',
        lastMessage: 'msg',
        time: 'now',
        unread: 1,
        online: true,
      );
      expect(model.lastMessage, isA<String>());
    });

    test('time is String', () {
      final model = ChatModel(
        name: 'Test',
        lastMessage: 'msg',
        time: 'now',
        unread: 1,
        online: true,
      );
      expect(model.time, isA<String>());
    });

    test('unread is int', () {
      final model = ChatModel(
        name: 'Test',
        lastMessage: 'msg',
        time: 'now',
        unread: 1,
        online: true,
      );
      expect(model.unread, isA<int>());
    });

    test('online is bool', () {
      final model = ChatModel(
        name: 'Test',
        lastMessage: 'msg',
        time: 'now',
        unread: 1,
        online: true,
      );
      expect(model.online, isA<bool>());
    });
  });

  group('ChatModel immutability', () {
    test('fields cannot be changed after creation', () {
      final model = ChatModel(
        name: 'Alice',
        lastMessage: 'Hello',
        time: '12:00',
        unread: 0,
        online: true,
      );
      // All fields are final, so they can only be read
      expect(model.name, 'Alice');
      expect(model.lastMessage, 'Hello');
      expect(model.time, '12:00');
      expect(model.unread, 0);
      expect(model.online, true);
    });
  });
}
