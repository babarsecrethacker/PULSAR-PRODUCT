import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message.dart';
import '../../features/call/services/rtc_service.dart';
import '../config/online_config.dart';
import 'lan_server_discovery.dart';
import 'firebase_service.dart';

class WebSocketService {
  WebSocketService._();

  static final WebSocketService _instance =
      WebSocketService._();

  factory WebSocketService() => _instance;

  WebSocketChannel? _channel;

  /// Observable connection state.
  ///
  /// `isConnected` is a plain getter, so a widget that reads it during
  /// build never learns that the socket came up afterwards. The chat
  /// header therefore sat on "not connected" indefinitely even though
  /// the app was online, which is what made it look like a fresh launch
  /// always required a new sign-in.
  final ValueNotifier<bool> connectionState =
      ValueNotifier<bool>(false);

  /// Observable for "a new message arrived", so counts and the tray can
  /// react without polling.
  final ValueNotifier<int> messageCount = ValueNotifier<int>(0);

  bool get isConnected => _connected;

  /// Single writer for connection state, so [connectionState] can never
  /// drift from the real flag.
  set _setConnected(bool value) {
    if (_connected == value) return;

    _connected = value;
    connectionState.value = value;
  }

  bool _connected = false;

  String? _myFirebaseUid;
  int? _myUserId;
  String? _myUsername;

  List<String> _cachedUsers = [];

  /// LAN display name -> routing identity, from the server roster.
  Map<String, int> _lanIdsByName = <String, int>{};

  /// The routing id for a LAN contact, or null if unknown.
  int? lanIdFor(String name) => _lanIdsByName[name];

  /// Identity assigned by the server on registration (LAN peers only).
  int? _myLanId;

  int? get myLanId => _myLanId;

  List<String> get cachedUsers =>
      List.unmodifiable(_cachedUsers);

  /// The name this client connected as, used to tell incoming messages
  /// apart from the ones we sent ourselves.
  String? get myUsername => _myUsername;

  /// The identifiers this client is known by, used to recognise our own
  /// echoed messages. Online accounts appear as a numeric id, so the
  /// Firebase UID and username are not sufficient on their own.
  String? get myFirebaseUid => _myFirebaseUid;

  int? get myUserId => _myUserId;

  // ---------------------------------------------------------
  // CALL SESSION STATE
  // ---------------------------------------------------------

  final Map<String, String> _callIds = {};

  String? get activeCallId =>
      _activeCallId;

  String? get activeCallPeer =>
      _activeCallPeer;

  String? _activeCallId;
  String? _activeCallPeer;

  String _createCallId() {
    final timestamp =
        DateTime.now().microsecondsSinceEpoch;

    final user =
        _myFirebaseUid ?? "unknown";

    return "call_${timestamp}_$user";
  }

  void _setCall(
    String peer,
    String callId,
  ) {
    _callIds[peer] = callId;

    _activeCallPeer = peer;
    _activeCallId = callId;

    print(
      "ðŸ“ž Active call: $callId "
      "with $peer",
    );
  }

  String? _getCallId(
    String peer,
  ) {
    return _callIds[peer];
  }

  void _clearCall(
    String peer, {
    String? callId,
  }) {
    final existing =
        _callIds[peer];

    if (callId != null &&
        existing != callId) {
      return;
    }

    _callIds.remove(peer);

    if (_activeCallPeer == peer &&
        (callId == null ||
            _activeCallId == callId)) {
      _activeCallPeer = null;
      _activeCallId = null;
    }

    print(
      "ðŸ“ž Cleared call with $peer",
    );
  }

  // ---------------------------------------------------------
  // MESSAGE STORAGE
  // ---------------------------------------------------------

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages =>
      List.unmodifiable(_messages);

  // ---------------------------------------------------------
  // MESSAGE STATUS STREAM
  // ---------------------------------------------------------

  final _messageStatusController =
      StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messageStatusStream =>
      _messageStatusController.stream;

  // ---------------------------------------------------------
  // CONVERSATION STORAGE
  // ---------------------------------------------------------

  final Map<String, List<ChatMessage>>
      _conversationStorage = {};

  final StreamController<
      Map<String, List<ChatMessage>>>
      _conversationsController =
      StreamController.broadcast();

  Stream<Map<String, List<ChatMessage>>>
      get conversations =>
          _conversationsController.stream;

  /// Merges server-side history into the in-memory conversation.
  ///
  /// The socket only ever carries live traffic, so anything sent while
  /// the other party was offline - or before an app restart - would
  /// otherwise never appear. History is keyed by id and merged, so live
  /// messages already received are not duplicated.
  void mergeHistory(
    String contactId,
    List<ChatMessage> history,
  ) {
    if (history.isEmpty) return;

    final List<ChatMessage> existing =
        _conversationStorage[contactId] ?? <ChatMessage>[];

    final Map<String, ChatMessage> byId = <String, ChatMessage>{
      for (final ChatMessage m in existing) m.id: m,
    };

    for (final ChatMessage m in history) {
      // A live copy is newer than the stored one; keep it.
      byId.putIfAbsent(m.id, () => m);
    }

    final List<ChatMessage> merged = byId.values.toList()
      ..sort(
        (ChatMessage a, ChatMessage b) =>
            a.time.compareTo(b.time),
      );

    _conversationStorage[contactId] = merged;

    if (!_conversationsController.isClosed) {
      _conversationsController.add(
        Map<String, List<ChatMessage>>.unmodifiable(
          _conversationStorage,
        ),
      );
    }
  }

  List<ChatMessage> conversationWith(
    String username,
  ) {
    return _conversationStorage[username] ??
        [];
  }

  // ---------------------------------------------------------
  // STREAM CONTROLLERS
  // ---------------------------------------------------------

  final _usersController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get users =>
      _usersController.stream;

  final _messageController =
      StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messageStream =>
      _messageController.stream;

  // ---------------------------------------------------------
  // CALL STREAMS
  // ---------------------------------------------------------

  final _incomingFiles =
      StreamController<
          Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>>
      get incomingFiles =>
          _incomingFiles.stream;

  final _incomingCalls =
      StreamController<String>.broadcast();

  Stream<String> get incomingCalls =>
      _incomingCalls.stream;

  final _callAccepted =
      StreamController<String>.broadcast();

  Stream<String> get callAccepted =>
      _callAccepted.stream;

  final _callRejected =
      StreamController<String>.broadcast();

  Stream<String> get callRejected =>
      _callRejected.stream;

  final _callEnded =
      StreamController<String>.broadcast();

  Stream<String> get callEnded =>
      _callEnded.stream;

  // ---------------------------------------------------------
  // CONNECT
  // ---------------------------------------------------------

  Future<void> connect({
    required String username,
  }) async {
    if (_connected) {
      return;
    }

    _myUsername = username;

    print("==============================");
    print("PULSAR WebSocket");
    print("Username: $username");
    print("==============================");

    try {
      // LAN discovery depends on UDP broadcast, which Android and some
      // Wi-Fi access points block outright. When that happens, fall
      // back to the configured server rather than leaving the user
      // stuck on the naming screen.
      String serverAddress;

      try {
        serverAddress = await LanServerDiscovery.findServer();
        print(
          "🛰 PULSAR server found at $serverAddress",
        );
      } catch (e) {
        print(
          "⚠️ LAN discovery failed ($e); using the configured server.",
        );

        final Uri configured = Uri.parse(
          OnlineConfig.serverUrl,
        );
        serverAddress =
            '${configured.host}:${configured.port}';
      }

      _channel =
          WebSocketChannel.connect(
        Uri.parse(
          "ws://$serverAddress/ws",
        ),
      );

      _setConnected = true;

      print(
        "âœ… Connected to PULSAR Server",
      );

      _channel!.sink.add(
        jsonEncode({
          "type": "register",
          "username": username,
        }),
      );

      print(
        "âœ… Register sent",
      );

      _listen();
    } catch (e) {
      _setConnected = false;
      _channel = null;

      print(
        "âŒ PULSAR LAN connection failed: $e",
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------
  // CONNECT WITH FIREBASE UID (Online Mode)
  // ---------------------------------------------------------

  /// Best-effort LAN lookup, used when the configured host is
  /// unreachable.
  static String? _lastServerAddress;

  Future<String?> _discoverServerAddress() async {
    if (_lastServerAddress != null) {
      return _lastServerAddress;
    }

    try {
      return await LanServerDiscovery.findServer();
    } catch (_) {
      return null;
    }
  }

  Future<void> connectWithFirebaseUid({
    required String firebaseUid,
    required int userId,
    String? firebaseToken,
    String? sessionToken,
  }) async {
    if (_connected) {
      return;
    }

    _myFirebaseUid = firebaseUid;
    _myUserId = userId;

    // Retained so a dropped connection can be re-established on its own.
    _lastUid = firebaseUid;
    _lastUserId = userId;
    _lastSessionToken = sessionToken;

    print("==============================");
    print("PULSAR Online WebSocket");
    print("Firebase UID: $firebaseUid");
    print("User ID: $userId");
    print("Has session token: ${sessionToken != null}");
    print("==============================");

    try {
      final uri = Uri.parse(OnlineConfig.websocketUrl);
      final queryParams = <String, String>{
        'firebase_uid': firebaseUid,
      };

      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        queryParams['firebase_token'] = firebaseToken;
      }

      // Google-OAuth users have no Firebase ID token, so the session
      // credential issued at login is what authenticates the socket.
      if (sessionToken != null && sessionToken.isNotEmpty) {
        queryParams['session_token'] = sessionToken;
      }

      final channel = WebSocketChannel.connect(
        uri.replace(queryParameters: queryParams),
      );

      _channel = channel;

      // Wait for the handshake to actually succeed before reporting the
      // socket as connected. Previously this flag was set immediately,
      // so a rejected upgrade (which surfaces as an error on the stream)
      // still looked like a healthy connection and the UI gave no hint
      // that messages could not be sent.
      try {
        await channel.ready;
      } catch (e) {
        // The configured address may be stale: a DHCP change on the
        // host moves the server, and a baked-in IP then points nowhere.
        // Fall back to discovery so the app still finds it.
        final String? discovered =
            await _discoverServerAddress();

        if (discovered == null) {
          _setConnected = false;
          _channel = null;
          print('❌ PULSAR Online handshake failed: $e');
          rethrow;
        }

        print(
          '⚠️ ${OnlineConfig.displayAddress} unreachable ($e); '
          'using discovered $discovered',
        );

        _channel = WebSocketChannel.connect(
          Uri.parse('ws://$discovered/ws'),
        );

        await _channel!.ready;

        _lastServerAddress = discovered;
      }

      _setConnected = true;
      _reconnectAttempts = 0;

      print(
        "âœ… Connected to PULSAR Online Server",
      );

      final fcmToken = await FirebaseService().getFCMToken();
      if (fcmToken != null) {
        sendRaw({
          "type": "register_fcm_token",
          "text": fcmToken,
        });
      }

      _listen();

      // Anything typed while the socket was down goes out now.
      _flushOutbox();
    } catch (e) {
      _setConnected = false;
      _channel = null;

      print(
        "âŒ PULSAR Online connection failed: $e",
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------
  // LISTEN
  // ---------------------------------------------------------

  /// Maps a server packet onto a [ChatMessage].
  ///
  /// The server nests the message object and identifies the parties by
  /// numeric id, whereas [ChatMessage.fromJson] expects flat fields.
  /// Feeding one into the other silently produced empty `from`/`to` and
  /// a stringified map as the body, which is why a client's own messages
  /// were indistinguishable from incoming ones - and therefore counted
  /// as unread.
  ChatMessage? _messageFromPacket(Map<String, dynamic> packet) {
    final Object? raw = packet['message'];

    final Map<String, dynamic> body = raw is Map
        ? Map<String, dynamic>.from(raw)
        : packet;

    final Object? senderId = body['sender_id'];
    final Object? receiverId = body['receiver_id'];
    final Object? text = body['text'] ?? body['message'];

    if (senderId is! num) return null;

    return ChatMessage(
      // Prefixed so a live id can never collide with a stored one.
      id: 'srv_${body['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      // The numeric id is what contact.id holds for online users, which
      // is what makes left/right alignment and unread counts correct.
      from: senderId.toInt().toString(),
      to: receiverId is num
          ? receiverId.toInt().toString()
          : '',
      message: text?.toString() ?? '',
      time: _parseTime(body['created_at']),
      status: _statusFromWire(body['status']?.toString()),
      // A voice note carries its clip alongside the caption.
      voiceBase64: body['audio']?.toString(),
      // The id the composer minted, so the local "sending" bubble can be
      // reconciled with the stored copy instead of duplicated.
      clientMessageId: body['firebase_message_id']?.toString(),
    );
  }

  DateTime _parseTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  MessageStatus _statusFromWire(String? status) {
    switch (status) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.pending;
    }
  }

  void _listen() {
    _channel!.stream.listen(
      (data) async {
        print(
          "â¬‡ Received: $data",
        );

        try {
          final packet =
              jsonDecode(
            data.toString(),
          );

          switch (packet["type"]) {
            // --------------------------------
            // USERS
            // --------------------------------

            case "users":
              final list =
                  List<String>.from(
                packet["users"] ?? [],
              );

              _cachedUsers = list;

              // Routing identities, so a LAN contact can actually be
              // addressed when sending.
              final Map<String, int> ids = <String, int>{};

              final Object? rawIds = packet['ids'];
              if (rawIds is Map) {
                for (final MapEntry<Object?, Object?> entry
                    in rawIds.entries) {
                  final Object? value = entry.value;
                  if (entry.key is String && value is num) {
                    ids[entry.key! as String] = value.toInt();
                  }
                }
              }

              _lanIdsByName = ids;

              _usersController.add(
                _cachedUsers,
              );

              break;

            // --------------------------------
            // REGISTERED
            //
            // The server assigns our routing identity here. It has to
            // be remembered: without it the client cannot recognise its
            // own echoed messages, so every message it sent raised an
            // unread badge and a notification popup.
            // --------------------------------

            case "registered":
              final Object? assigned = packet['id'];
              if (assigned is num) {
                _myUserId = assigned.toInt();
                _myLanId = assigned.toInt();
              }
              break;

            // --------------------------------
            // MESSAGE
            // --------------------------------

            case "message":
              final msg = _messageFromPacket(packet);

              if (msg != null) {
                _storeMessage(msg);

                print(
                  "ðŸ’¬ ${msg.from} -> "
                  "${msg.to}: ${msg.message}",
                );
              }

              break;

            // --------------------------------
            // MESSAGE STATUS
            // --------------------------------

            case "message_status":
              // Parsed with the same nested-aware mapper as a message
              // frame. Using ChatMessage.fromJson here read a null id,
              // invented a random one, and therefore never matched the
              // bubble it was meant to update - which is why sent
              // messages stayed stuck on "sending".
              final statusMsg = _messageFromPacket(packet);

              if (statusMsg != null) {
                _updateMessageStatus(
                  statusMsg.copyWith(
                    status: _statusFromWire(
                      packet['status']?.toString(),
                    ),
                  ),
                );

                print(
                  "Message status: ${statusMsg.id} -> "
                  "${packet['status']}",
                );
              }

              break;

            // --------------------------------
            // VOICE
            // --------------------------------

            case "voice":
              final msg =
                  ChatMessage.fromJson(
                packet,
              );

              _storeMessage(msg);

              print(
                "ðŸŽ¤ Voice message from "
                "${msg.from}",
              );

              break;

            // --------------------------------
            // CALL REQUEST
            // --------------------------------

            case "call_request":
              final from =
                  packet["from"]?.toString();

              final callId =
                  packet["callId"]?.toString();

              if (from != null &&
                  callId != null &&
                  callId.isNotEmpty) {
                _setCall(
                  from,
                  callId,
                );

                _incomingCalls.add(
                  from,
                );

                print(
                  "ðŸ“ž Incoming NEW call "
                  "$callId from $from",
                );
              }

              break;

            // --------------------------------
            // CALL ACCEPT
            // --------------------------------

            case "call_accept":
  final from =
      packet["from"]?.toString();

  final callId =
      packet["callId"]?.toString();

  if (from == null ||
      callId == null) {
    break;
  }

  final known =
      _getCallId(from);

  if (known != callId) {
    print(
      "âš ï¸ Ignoring stale call_accept "
      "$callId",
    );
    break;
  }

  _callAccepted.add(from);

  print(
    "ðŸ“ž Call accepted: $callId",
  );

  // NOW, and only now, start RTC.
  await RTCService().initialize();

  RTCService().setRemoteUser(from);

  final offer =
      await RTCService().createOffer();

  sendOffer(
    from,
    offer,
  );

  break;
            // --------------------------------
            // CALL REJECT
            // --------------------------------

            case "call_reject":
              final from =
                  packet["from"]?.toString();

              final callId =
                  packet["callId"]?.toString();

              if (from != null &&
                  callId != null) {
                final known =
                    _getCallId(from);

                if (known == callId) {
                  _callRejected.add(
                    from,
                  );

                  _clearCall(
                    from,
                    callId: callId,
                  );

                  await RTCService().close();

                  print(
                    "ðŸ“ž Call rejected: "
                    "$callId",
                  );
                }
              }

              break;

            // --------------------------------
            // CALL END
            // --------------------------------

            case "call_end":
              await _handleCallEnded(
                packet,
              );

              break;

            // --------------------------------
            // SERVER-FORCED CALL END
            // --------------------------------

            case "call_ended":
              await _handleCallEnded(
                packet,
              );

              break;

            // --------------------------------
            // FILE
            // --------------------------------

            case "file_offer":
              _incomingFiles.add(
                packet,
              );

              break;

            // --------------------------------
            // RTC OFFER
            // --------------------------------

            case "offer":
  final from =
      packet["from"]?.toString();

  final callId =
      packet["callId"]?.toString();

  if (from == null ||
      callId == null) {
    break;
  }

  final known =
      _getCallId(from);

  if (known != callId) {
    print(
      "âš ï¸ Ignoring stale offer "
      "$callId",
    );
    break;
  }

  // The recipient must already have
  // accepted the call.
  //
  // If RTC isn't active, do NOT
  // silently start it from an offer.
  // The callId is already validated above.
// The recipient can initialize RTC here
// because receiving a valid offer means
// the caller has received our ACCEPT.
if (RTCService().peerConnection == null) {
  await RTCService().initialize();
}

RTCService().setRemoteUser(from);

  await RTCService()
      .setRemoteDescription(
    packet["sdp"],
  );

  final answer =
      await RTCService().createAnswer();

  sendAnswer(
    from,
    answer,
  );

  break;
            // --------------------------------
            // RTC ANSWER
            // --------------------------------

            case "answer":
              final from =
                  packet["from"]?.toString();

              final callId =
                  packet["callId"]?.toString();

              if (from == null ||
                  callId == null) {
                break;
              }

              final known =
                  _getCallId(from);

              if (known != callId) {
                print(
                  "âš ï¸ Ignoring stale answer "
                  "$callId",
                );

                break;
              }

              await RTCService()
                  .setRemoteDescription(
                packet["sdp"],
              );

              break;

            // --------------------------------
            // ICE CANDIDATE
            // --------------------------------

            case "candidate":
              final from =
                  packet["from"]?.toString();

              final callId =
                  packet["callId"]?.toString();

              if (from == null ||
                  callId == null) {
                break;
              }

              final known =
                  _getCallId(from);

              if (known != callId) {
                print(
                  "âš ï¸ Ignoring stale candidate "
                  "$callId",
                );

                break;
              }

              await RTCService()
                  .addCandidate(
                packet["candidate"],
              );

              break;
          }
        } catch (e) {
          print(
            "WebSocket parse error: $e",
          );
        }
      },

      onDone: () async {
        _setConnected = false;

        // The WebSocket died.
        // The RTC call must die too.
        _callIds.clear();
        _activeCallId = null;
        _activeCallPeer = null;

        await RTCService().close();

        print(
          "ðŸ“´ PULSAR WebSocket disconnected",
        );

        _scheduleReconnect();
      },

      onError: (error) {
        print(
          "WebSocket error: $error",
        );
      },
    );
  }

  // ---------------------------------------------------------
  // RECONNECT
  // ---------------------------------------------------------

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Credentials for the current mode, retained so the socket can be
  /// re-established without the UI having to re-drive a login.
  String? _lastUid;
  int? _lastUserId;
  String? _lastSessionToken;

  /// Retries the connection with backoff.
  ///
  /// The socket authenticates against the database, so a transient
  /// network or DNS blip - which is exactly what the Supabase host has
  /// been doing - used to leave the client permanently offline with no
  /// way back other than restarting the app.
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    // LAN mode has nothing to reconnect with.
    if (_lastUid == null && _lastSessionToken == null) return;

    if (_reconnectAttempts >= 8) {
      print('âš ï¸ Giving up on reconnect after 8 attempts');
      return;
    }

    _reconnectAttempts++;

    // 1s, 2s, 4s ... capped at 20s.
    final int seconds = 1 << (_reconnectAttempts - 1).clamp(0, 4);
    final Duration wait = Duration(
      seconds: seconds.clamp(1, 20),
    );

    print(
      'ðŸ”„ Reconnecting in ${wait.inSeconds}s '
      '(attempt $_reconnectAttempts)',
    );

    _reconnectTimer = Timer(wait, () {
      _reconnectTimer = null;
      unawaited(_attemptReconnect());
    });
  }

  Future<void> _attemptReconnect() async {
    try {
      _setConnected = false;

      await connectWithFirebaseUid(
        firebaseUid: _lastUid ?? 'session',
        userId: _lastUserId ?? 0,
        sessionToken: _lastSessionToken,
      );

      _reconnectAttempts = 0;
      print('âœ… Reconnected');
    } catch (e) {
      print('âŒ Reconnect failed: $e');
      _scheduleReconnect();
    }
  }

  // ---------------------------------------------------------
  // CALL END HANDLER
  // ---------------------------------------------------------

  Future<void> _handleCallEnded(
    Map<String, dynamic> packet,
  ) async {
    final from =
        packet["from"]?.toString();

    final callId =
        packet["callId"]?.toString();

    if (from == null) {
      return;
    }

    final known =
        _getCallId(from);

    // Ignore old sessions.
    if (callId != null &&
        known != null &&
        known != callId) {
      print(
        "âš ï¸ Ignoring stale call end "
        "$callId",
      );

      return;
    }

    print(
      "ðŸ“´ Call ended by $from "
      "session=$callId",
    );

    _clearCall(
      from,
      callId: callId,
    );

    await RTCService().close();

    _callEnded.add(
      from,
    );
  }

  // ---------------------------------------------------------
  // STORE MESSAGE
  // ---------------------------------------------------------

  void _storeMessage(
    ChatMessage incoming,
  ) {
    // A conversation is filed under the OTHER participant. Comparing
    // only against _myUsername was wrong for online accounts, which
    // are identified by a numeric id and never set _myUsername - so
    // every message you sent was filed under your own conversation
    // instead of the one you were talking in.
    final String otherUser = isSelfSender(
      incoming.from,
      username: _myUsername,
      firebaseUid: _myFirebaseUid,
      userId: _myUserId,
    )
        ? incoming.to
        : incoming.from;

    if (otherUser.isEmpty) return;

    _conversationStorage.putIfAbsent(
      otherUser,
      () => [],
    );

    final List<ChatMessage> bucket =
        _conversationStorage[otherUser]!;

    // The server echoes a message back to its sender, and a confirmed
    // copy supersedes the optimistic one. Both cases must replace the
    // existing entry rather than append, or the same text appears
    // twice - once frozen on "sending" and once delivered.
    final int existing = _findExisting(
      bucket,
      incoming,
    );

    if (existing >= 0) {
      final ChatMessage previous = bucket[existing];

      bucket[existing] = incoming.copyWith(
        // Keep the optimistic id and timestamp so the bubble stays put
        // and any UI keyed on it keeps working.
        id: previous.id,
        time: previous.time,
        status: incoming.status == MessageStatus.pending
            ? previous.status
            : incoming.status,
      );
    } else {
      bucket.add(incoming);
    }

    // Mirror the same decision into the flat log.
    _messages
      ..removeWhere(
        (ChatMessage m) =>
            m.id == incoming.id ||
            (incoming.clientMessageId != null &&
                m.id == incoming.clientMessageId),
      )
      ..add(bucket[existing >= 0 ? existing : bucket.length - 1]);

    bucket.sort(
      (ChatMessage a, ChatMessage b) =>
          a.time.compareTo(b.time),
    );

    _conversationsController.add(
      _conversationStorage,
    );
    _messageController.add(
      incoming,
    );
  }

  /// Index of an entry [incoming] supersedes, or -1.
  int _findExisting(
    List<ChatMessage> bucket,
    ChatMessage incoming,
  ) {
    for (int i = 0; i < bucket.length; i++) {
      if (bucket[i].id == incoming.id) return i;

      final String? clientId = incoming.clientMessageId;
      if (clientId != null && bucket[i].id == clientId) return i;
    }

    return -1;
  }

  /// Whether [sender] identifies this client.
  ///
  /// The server echoes a sender's own messages back to them, and tags
  /// online senders with a numeric account id, so a username check
  /// alone is not sufficient.
  static bool isSelfSender(
    String sender, {
    String? username,
    String? firebaseUid,
    int? userId,
  }) {
    if (username != null && username.isNotEmpty && sender == username) {
      return true;
    }

    if (firebaseUid != null &&
        firebaseUid.isNotEmpty &&
        sender == firebaseUid) {
      return true;
    }

    if (userId != null && userId > 0 && sender == '$userId') {
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------
  // UPDATE MESSAGE STATUS
  // ---------------------------------------------------------

  void _updateMessageStatus(
    ChatMessage statusMsg,
  ) {
    // Match on the client's original id when the server echoed it back,
    // otherwise on the stored id.
    final String? clientId = statusMsg.clientMessageId;

    // Match on the id the composer generated. The optimistic bubble can
    // carry it either as its own id or as clientMessageId depending on
    // which code path built it, so both are checked.
    bool matches(ChatMessage m) =>
        (clientId != null &&
            clientId.isNotEmpty &&
            (m.id == clientId || m.clientMessageId == clientId)) ||
        m.id == statusMsg.id;

    for (int i = 0; i < _messages.length; i++) {
      if (!matches(_messages[i])) continue;

      _messages[i] =
          _messages[i].copyWith(status: statusMsg.status);
      break;
    }

    // The conversation is filed under the OTHER participant, decided
    // with the same identity rule used everywhere else.
    final String otherUser = isSelfSender(
      statusMsg.from,
      username: _myUsername,
      firebaseUid: _myFirebaseUid,
      userId: _myUserId,
    )
        ? statusMsg.to
        : statusMsg.from;

    final List<ChatMessage>? bucket =
        _conversationStorage[otherUser];

    if (bucket != null) {
      for (int i = 0; i < bucket.length; i++) {
        if (!matches(bucket[i])) continue;

        bucket[i] = bucket[i].copyWith(status: statusMsg.status);
        break;
      }

      _conversationsController.add(_conversationStorage);
    }

    // Emit status update
    _messageStatusController.add(statusMsg);
  }

  // ---------------------------------------------------------
  // SEND RAW
  // ---------------------------------------------------------

  /// Messages composed while the socket is down.
  ///
  /// Without this, `sendRaw` dropped the frame on the floor and the UI
  /// cleared the composer, so pressing send appeared to do nothing and
  /// the text was gone for good.
  final List<Map<String, dynamic>> _outbox = [];

  int get outboxLength => _outbox.length;

  void sendRaw(
    Map<String, dynamic> data,
  ) {
    if (!_connected) {
      // Only chat messages are worth replaying. Control frames such as
      // the FCM registration are cheap to re-issue or simply stale.
      if (data['type'] == 'message') {
        _outbox.add(data);
        print(
          "ðŸ“¥ Queued message while offline (${_outbox.length} pending)",
        );
      } else {
        print(
          "âš ï¸ Cannot send ${data['type']}: WebSocket disconnected",
        );
      }

      return;
    }

    _channel?.sink.add(
      jsonEncode(data),
    );
  }

  /// Replays anything composed while the connection was down.
  void _flushOutbox() {
    if (_outbox.isEmpty) return;

    print(
      "ðŸ“¤ Flushing ${_outbox.length} queued message(s)",
    );

    final List<Map<String, dynamic>> pending =
        List<Map<String, dynamic>>.from(_outbox);

    _outbox.clear();

    for (final Map<String, dynamic> data in pending) {
      _channel?.sink.add(jsonEncode(data));
    }
  }

  // ---------------------------------------------------------
  // CHAT
  // ---------------------------------------------------------

  void sendMessage(
    ChatMessage message,
  ) {
    sendRaw(
      message.toJson(),
    );
  }

  void send({
    required String to,
    required String message,
    String? toFirebaseUid,
  }) {
    final messageId = DateTime.now().microsecondsSinceEpoch.toString();
    final fromId = _myFirebaseUid ?? _myUsername!;
    final target = toFirebaseUid ?? to;

    // A LAN contact is identified by its display name, but the server
    // routes by the numeric identity from the roster. Without this the
    // name was sent, the server could not resolve it, and every LAN
    // message failed with "no rows in result set".
    final int? targetUserId = toFirebaseUid == null
        ? (int.tryParse(to) ?? _lanIdsByName[to])
        : null;

    final chat = ChatMessage(
      id: messageId,
      from: fromId,
      to: target,
      message: message,
      time: DateTime.now(),
      status: MessageStatus.pending,
      // Carried explicitly so the server's stored copy can be matched to
      // this bubble without relying on id formats.
      clientMessageId: messageId,
    );

    _storeMessage(chat);

    final Map<String, dynamic> payload =
        chat.toJson()..addAll({"message_id": messageId});

    if (targetUserId != null) {
      payload['to_id'] = targetUserId;
    }

    print(
      "📤 send to='$to' to_id=$targetUserId from='$fromId' id=$messageId",
    );

    if (toFirebaseUid != null) {
      payload['to'] = toFirebaseUid;
    }

    sendRaw(payload);
  }

  void sendByFirebaseUid({
    required String toFirebaseUid,
    required String message,
    int? toUserId,
  }) {
    final messageId = DateTime.now().microsecondsSinceEpoch.toString();
    final fromFirebaseUid = _myFirebaseUid!;
    final chat = ChatMessage(
      id: messageId,
      from: fromFirebaseUid,
      to: toFirebaseUid,
      message: message,
      time: DateTime.now(),
      status: MessageStatus.pending,
    );

    _storeMessage(chat);

    final payload = <String, dynamic>{
      ...chat.toJson(),
      "message_id": messageId,
    };
    if (toUserId != null) {
      payload["to_id"] = toUserId;
    }
    sendRaw(payload);
  }

  // ---------------------------------------------------------
  // CALL FUNCTIONS
  // ---------------------------------------------------------

  void callUser(String peer) {
    final callId = _createCallId();

    _setCall(
      peer,
      callId,
    );

    sendRaw({
      "type": "call_request",
      "callId": callId,
      "from": _callIdentity,
      "to": peer,
    });
  }

Future<void> acceptCall(
  String peer,
) async {
  final callId =
      _getCallId(peer);

  if (callId == null) {
    print(
      "âš ï¸ No active incoming call",
    );
    return;
  }

  sendRaw({
    "type": "call_accept",
    "callId": callId,
    "from": _callIdentity,
    "to": peer,
  });

  print(
    "ðŸ“ž Accepted call $callId",
  );
}

void rejectCall(
    String peer,
  ) {
    final callId =
        _getCallId(peer);

    if (callId == null) {
      return;
    }

    sendRaw({
      "type": "call_reject",
      "callId": callId,
      "from": _callIdentity,
      "to": peer,
    });

    _clearCall(
      peer,
      callId: callId,
    );

    print(
      "ðŸ“ž Rejected call $callId",
    );
  }

  void endCall(
    String peer,
  ) {
    final callId =
        _getCallId(peer);

    if (callId == null) {
      return;
    }

    sendRaw({
      "type": "call_end",
      "callId": callId,
      "from": _callIdentity,
      "to": peer,
    });

    _clearCall(
      peer,
      callId: callId,
    );

    print(
      "ðŸ“´ Ended call $callId",
    );
  }

  // ---------------------------------------------------------
  // RTC SIGNALS
  // ---------------------------------------------------------

  /// Identity carried in call signalling frames.
  ///
  /// It must match what the receiver looks the call up with
  /// (`_getCallId(from)`). These frames were sending the Firebase UID
  /// instead of the account id the call was registered under, so no
  /// lookup ever matched and every offer was dropped as "stale" - the
  /// microphone opened but no audio was ever negotiated.
  /// Resolves a call identity back to a display name.
  ///
  /// Call frames carry a numeric account id so both sides can look the
  /// call up, which meant the call screen rendered that number instead
  /// of a person. The roster maps name to identity, so it is inverted
  /// here for LAN peers; online contacts already carry the account id.
  String? displayNameFor(String identity) {
    if (identity.isEmpty) return null;

    if (_myLanId != null && identity == '$_myLanId') {
      return _myUsername;
    }

    for (final MapEntry<String, int> entry
        in _lanIdsByName.entries) {
      if ('${entry.value}' == identity) return entry.key;
    }

    return null;
  }

  String get _callIdentity {
    if (_myLanId != null) return '$_myLanId';
    if (_myUserId != null && _myUserId! > 0) return '$_myUserId';
    return _myFirebaseUid ?? _myUsername ?? '';
  }

  void sendOffer(
    String peer,
    dynamic sdp,
  ) {
    final callId =
        _getCallId(peer);

    if (callId == null) {
      print(
        "âš ï¸ Cannot send offer: "
        "no active call",
      );

      return;
    }

    sendRaw({
      "type": "offer",
      "callId": callId,
      "from": _callIdentity,
      "to": peer,
      "sdp": sdp,
    });
  }

  void sendAnswer(
    String peer,
    dynamic sdp,
  ) {
    final callId =
        _getCallId(peer);

    if (callId == null) {
      print(
        "âš ï¸ Cannot send answer: "
        "no active call",
      );

      return;
    }

    sendRaw({
      "type": "answer",
      "callId": callId,
      "from": _callIdentity,
      "to": peer,
      "sdp": sdp,
    });
  }

  void sendCandidate(
    String peer,
    dynamic candidate,
  ) {
    final callId =
        _getCallId(peer);

    if (callId == null) {
      return;
    }

    sendRaw({
      "type": "candidate",
      "callId": callId,
      "from": _callIdentity,
      "to": peer,
      "candidate": candidate,
    });
  }

  // ---------------------------------------------------------
  // VOICE
  // ---------------------------------------------------------

  void sendVoice({
    required String to,
    required String audio,
  }) {
    final messageId = DateTime.now().microsecondsSinceEpoch.toString();

    // The numeric target is required: a base64 clip is large, and the
    // server resolves the recipient by `to_id`. LAN contacts are named,
    // so their roster identity is used.
    final int? targetUserId =
        int.tryParse(to) ?? _lanIdsByName[to];

    sendRaw(<String, dynamic>{
      'type': 'voice',
      'from': _myFirebaseUid ?? _myUsername!,
      'to': to,
      if (targetUserId != null) 'to_id': targetUserId,
      'audio': audio,
      'time': DateTime.now().toIso8601String(),
      'message_id': messageId,
    });
  }

  // ---------------------------------------------------------
  // FILE
  // ---------------------------------------------------------

  void sendFileOffer({
    required String to,
    required String name,
    required int size,
  }) {
    final messageId = DateTime.now().microsecondsSinceEpoch.toString();
    sendRaw({
      "type": "file_offer",
      "from": _callIdentity,
      "to": to,
      "name": name,
      "size": size,
      "message_id": messageId,
    });
  }

  // ---------------------------------------------------------
  // READ RECEIPT
  // ---------------------------------------------------------

  void sendReadReceipt({
    required String to,
    required String messageId,
  }) {
    // Message ids are stored as "db_<n>" or "srv_<n>". The server can
    // only mark a row read by its numeric id or the client id it was
    // sent with, so the number is sent alongside the original.
    final int? numeric = _numericMessageId(messageId);

    sendRaw(<String, dynamic>{
      'type': 'read_receipt',
      'from': _myFirebaseUid ?? _myUsername!,
      'to': to,
      'to_id': int.tryParse(to) ?? _lanIdsByName[to],
      // Prefer the raw form; the server accepts either.
      'read_message_id': messageId,
      if (numeric != null) 'read_message_numeric_id': '$numeric',
    });
  }

  /// Extracts the row number from a stored id such as `db_42`.
  static int? _numericMessageId(String id) {
    final int dash = id.lastIndexOf('_');
    if (dash < 0 || dash == id.length - 1) {
      return int.tryParse(id);
    }
    return int.tryParse(id.substring(dash + 1));
  }

  /// Exposed for the read-receipt id tests.
  @visibleForTesting
  static int? numericMessageIdForTest(String id) => _numericMessageId(id);

  // ---------------------------------------------------------
  // DISCONNECT
  // ---------------------------------------------------------

  void disconnect() {
    _setConnected = false;

    _callIds.clear();

    _activeCallId = null;
    _activeCallPeer = null;

    RTCService().close();

    _channel?.sink.close();

    _channel = null;

    // The identity MUST be cleared. Leaving it behind meant that after
    // switching accounts the app still believed it was the previous
    // user, so every sender check misfired: your own messages were
    // treated as the other party's and vice versa.
    clearIdentity();

    print(
      "PULSAR disconnected",
    );
  }

  /// Drops everything tied to the account that just signed out.
  void clearIdentity() {
    _myUsername = null;
    _myFirebaseUid = null;
    _myUserId = null;
    _myLanId = null;

    _lastUid = null;
    _lastUserId = null;
    _lastSessionToken = null;

    _lanIdsByName = <String, int>{};

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;

    // Cached conversations belong to the account that just left, so
    // keeping them mixes two people's threads together.
    _conversationStorage.clear();
    _messages.clear();

    if (!_conversationsController.isClosed) {
      _conversationsController.add(
        <String, List<ChatMessage>>{},
      );
    }
  }
}