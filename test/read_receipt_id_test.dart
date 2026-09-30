import 'package:flutter_test/flutter_test.dart';
import 'package:pulsar_chat/core/services/websocket_service.dart';

/// A read receipt can only mark a row read by its numeric id or the
/// client id it was sent with. Stored ids are prefixed ("db_42",
/// "srv_42"), so the number has to be recovered from them - otherwise
/// old messages are counted as unread forever.
void main() {
  group('read receipt id', () {
    test('recovers the number from a stored db_ id', () {
      expect(WebSocketService.numericMessageIdForTest('db_42'), 42);
    });

    test('recovers the number from a stored srv_ id', () {
      expect(WebSocketService.numericMessageIdForTest('srv_118'), 118);
    });

    test('accepts a bare number', () {
      expect(WebSocketService.numericMessageIdForTest('42'), 42);
    });

    test('returns null for a local id with no row number', () {
      // A message still pending on the server has nothing to mark.
      expect(WebSocketService.numericMessageIdForTest('local-1'), isNull);
    });

    test('returns null for a trailing separator', () {
      expect(WebSocketService.numericMessageIdForTest('db_'), isNull);
    });

    test('handles a non-numeric suffix', () {
      expect(
        WebSocketService.numericMessageIdForTest('local-abc'),
        isNull,
      );
    });

    test('only takes the last segment', () {
      // Guards against matching a prefix and reading the wrong row.
      expect(
        WebSocketService.numericMessageIdForTest('db_1_99'),
        99,
      );
    });
  });
}
