import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LanServerDiscovery {
  static const int discoveryPort = 8081;

  static const String discoveryRequest =
      'PULSAR_DISCOVER_V1';

  static const String discoveryResponsePrefix =
      'PULSAR_SERVER_V1:';

  static const Duration attemptTimeout =
      Duration(milliseconds: 900);

  static const int attempts = 5;

  static Future<String> findServer() async {
    print('📡 PULSAR: starting LAN discovery...');

    for (int attempt = 1; attempt <= attempts; attempt++) {
      print(
        '📡 PULSAR: discovery attempt '
        '$attempt/$attempts',
      );

      try {
        final result = await _discoverOnce();

        if (result != null) {
          print(
            '✅ PULSAR server discovered at $result',
          );

          return result;
        }
      } catch (e) {
        print(
          '⚠️ Discovery attempt failed: $e',
        );
      }

      if (attempt < attempts) {
        await Future.delayed(
          const Duration(milliseconds: 250),
        );
      }
    }

    throw Exception(
      'No PULSAR server was found on the LAN.',
    );
  }

  static Future<String?> _discoverOnce() async {
    RawDatagramSocket? socket;
    StreamSubscription<RawSocketEvent>? subscription;
    Timer? timer;

    final completer =
        Completer<String?>();

    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: false,
      );

      socket.broadcastEnabled = true;

      print(
        '📡 Discovery socket opened on '
        '${socket.address.address}:${socket.port}',
      );

      final request = utf8.encode(
        discoveryRequest,
      );

      // Listen BEFORE sending so we cannot miss
      // an immediate server response.
      subscription = socket.listen(
        (event) {
          if (event != RawSocketEvent.read) {
            return;
          }

          while (true) {
            final datagram = socket?.receive();

            if (datagram == null) {
              break;
            }

            final message = utf8.decode(
              datagram.data,
              allowMalformed: true,
            ).trim();

            print(
              '📡 Discovery response from '
              '${datagram.address.address}: '
              '$message',
            );

            if (!message.startsWith(
              discoveryResponsePrefix,
            )) {
              continue;
            }

            final portText = message.substring(
              discoveryResponsePrefix.length,
            );

            final port =
                int.tryParse(portText);

            if (port == null) {
              continue;
            }

            if (!completer.isCompleted) {
              completer.complete(
                '${datagram.address.address}:$port',
              );
            }

            return;
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      // --------------------------------------------------
      // 1. Normal LAN broadcast
      // --------------------------------------------------

      _send(
        socket,
        request,
        InternetAddress('255.255.255.255'),
      );

      print(
        '📡 Sent broadcast → 255.255.255.255:$discoveryPort',
      );

      // --------------------------------------------------
      // 2. Directed subnet broadcasts
      // --------------------------------------------------

      final interfaces =
          await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final ipv4 = address.address;

          if (!_isUsableIPv4(ipv4)) {
            continue;
          }

          final broadcast =
              _calculateBroadcastAddress(
            ipv4,
            address.rawAddress,
          );

          if (broadcast == null) {
            continue;
          }

          print(
            '📡 Interface ${interface.name}: '
            '$ipv4 → broadcast $broadcast',
          );

          _send(
            socket,
            request,
            InternetAddress(broadcast),
          );
        }
      }

      // --------------------------------------------------
      // Wait for server response
      // --------------------------------------------------

      timer = Timer(
        attemptTimeout,
        () {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      return await completer.future;
    } finally {
      timer?.cancel();
      await subscription?.cancel();
      socket?.close();
    }
  }

  static void _send(
    RawDatagramSocket socket,
    List<int> data,
    InternetAddress address,
  ) {
    try {
      socket.send(
        data,
        address,
        discoveryPort,
      );
    } catch (e) {
      print(
        '⚠️ Could not send discovery to '
        '${address.address}: $e',
      );
    }
  }

  static bool _isUsableIPv4(
    String ip,
  ) {
    if (ip == '127.0.0.1') {
      return false;
    }

    if (ip.startsWith('169.254.')) {
      return false;
    }

    return true;
  }

  static String? _calculateBroadcastAddress(
    String ip,
    List<int> rawAddress,
  ) {
    if (rawAddress.length != 4) {
      return null;
    }

    // Dart's NetworkInterface.Address does not
    // directly expose the subnet mask on all
    // supported platforms. For common Windows
    // home LANs, derive the broadcast using
    // the interface's likely private subnet.
    //
    // 192.168.x.x → /24
    // 10.x.x.x    → /24
    // 172.16-31   → /24
    //
    // The normal 255.255.255.0 home LAN case
    // is what PULSAR uses here.

    final parts = ip.split('.');

    if (parts.length != 4) {
      return null;
    }

    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    final c = int.tryParse(parts[2]);

    if (a == null || b == null || c == null) {
      return null;
    }

    if (a == 192 && b == 168) {
      return '$a.$b.$c.255';
    }

    if (a == 10) {
      return '$a.$b.$c.255';
    }

    if (a == 172 && b >= 16 && b <= 31) {
      return '$a.$b.$c.255';
    }

    return null;
  }
}