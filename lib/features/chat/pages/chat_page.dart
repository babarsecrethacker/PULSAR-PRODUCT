import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/voice_message_bubble.dart';

import 'package:just_audio/just_audio.dart';

import '../../../core/config/online_config.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/nova_theme.dart';

import '../../call/pages/call_page.dart';
import '../../contacts/models/contact.dart';

import '../../call/widgets/incoming_call_toast.dart';
import '../../call/services/rtc_service.dart';

import '../../../core/services/voice_record_service.dart';

import '../../../core/services/file_picker_service.dart';
import 'dart:io';

import '../../files/widgets/incoming_file_toast.dart';
import '../../../core/services/firebase_service.dart';

class ChatPage extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onBack;

  /// The signed-in user's id, used to fetch persisted conversation
  /// history for online contacts.
  final int currentUserId;

  const ChatPage({
    super.key,
    required this.contact,
    this.onBack,
    this.currentUserId = 0,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller =
      TextEditingController();

      final AudioPlayer _player = AudioPlayer();

bool _isRecording = false;

      File? pendingFile;

  List<ChatMessage> messages = [];

  OverlayEntry? incomingCallOverlay;

  OverlayEntry? incomingFileOverlay;

StreamSubscription? conversationSubscription;
  StreamSubscription<ChatMessage>? messageStatusSubscription;

  StreamSubscription<Map<String, dynamic>>? incomingFileSubscription;
StreamSubscription<Map<String, dynamic>>? fileReadySubscription;

  StreamSubscription<String>? incomingCallSubscription;
  StreamSubscription<String>? callAcceptedSubscription;
  StreamSubscription<String>? callRejectedSubscription;
  StreamSubscription<String>? callEndedSubscription;

  StreamSubscription<DatabaseEvent>? _firebaseCallSubscription;
  StreamSubscription<DatabaseEvent>? _firebaseMessageSubscription;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  bool get _wsConnected => WebSocketService().isConnected;

  /// Live presence for the contact in the header.
  ///
  /// This used to be the literal string "Online", so the chat header
  /// claimed presence regardless of the truth. It is now read from the
  /// server and refreshed while the thread is open.
  bool _contactOnline = false;

  Timer? _presenceTimer;
  VoidCallback? _connectionListener;

  /// LAN contacts are bare names with no account row, so presence comes
  /// from the local socket roster instead of the server's user list.
  bool get _isLanContact => int.tryParse(widget.contact.id) == null;

  Future<void> _refreshContactPresence() async {
    if (!mounted) return;

    if (_isLanContact) {
      final bool present = WebSocketService().cachedUsers
          .contains(widget.contact.id);

      if (present != _contactOnline) {
        setState(() => _contactOnline = present);
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${OnlineConfig.serverUrl}/users/online'),
      );

      if (response.statusCode != 200 || !mounted) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;

      final users = decoded['users'];
      if (users is! List) return;

      final bool present = users.any((Object? u) {
        if (u is! Map) return false;
        final Object? id = u['id'];
        return id is num && id.toInt().toString() == widget.contact.id;
      });

      if (present != _contactOnline) {
        setState(() => _contactOnline = present);
      }
    } catch (_) {
      // Leave the last known value rather than flickering.
    }
  }

@override
  void initState() {
    super.initState();

    _loadConversation();

    _listenMessages();

    _listenMessageStatus();

    _listenForCalls();

    _listenForFirebaseCalls();

    _listenForFirebaseMessages();

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _contactOnline = widget.contact.online;
    _refreshContactPresence();

    // The socket comes up asynchronously after launch. Without this the
    // header kept rendering "not connected" for the whole session
    // because nothing triggered a rebuild when it connected.
    _connectionListener = () {
      if (!mounted) return;
      setState(() {});
    };

    WebSocketService().connectionState.addListener(
      _connectionListener!,
    );

    _presenceTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _refreshContactPresence(),
    );
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();

    if (_connectionListener != null) {
      WebSocketService().connectionState.removeListener(
        _connectionListener!,
      );
    }

    conversationSubscription?.cancel();
    messageStatusSubscription?.cancel();

    incomingCallSubscription?.cancel();
    callAcceptedSubscription?.cancel();
    callRejectedSubscription?.cancel();
    callEndedSubscription?.cancel();

    _firebaseCallSubscription?.cancel();
    _firebaseMessageSubscription?.cancel();

    controller.dispose();

    incomingCallOverlay?.remove();

    _player.dispose();

    super.dispose();
  }

  //---------------------------------------------------
  // Conversation
  //---------------------------------------------------

  void _loadConversation() {
    messages = WebSocketService().conversationWith(
      widget.contact.id,
    );

    // Pull anything that was sent while this conversation had no live
    // socket, so an offline recipient still sees it once they open the
    // thread.
    _fetchHistory();

    // Send read receipts for all unread messages from this contact
    _sendReadReceipts();
  }

  /// Loads persisted messages for this conversation from the server.
  ///
  /// Only meaningful for online contacts: a LAN peer has no account row,
  /// so there is nothing to query and the live socket is the only path.
  Future<void> _fetchHistory() async {
    final int me = widget.currentUserId;
    final int? other = int.tryParse(widget.contact.id);

    if (me <= 0 || other == null || other == me) return;

    try {
      final uri = Uri.parse(
        '${OnlineConfig.serverUrl}/conversation',
      ).replace(queryParameters: <String, String>{
        'me': '$me',
        'user': '$other',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return;

      final List<ChatMessage> history = <ChatMessage>[];

      for (final Object? row in decoded) {
        if (row is! Map<String, dynamic>) continue;

        final Object? senderId = row['sender_id'];
        if (senderId is! num) continue;

        final Object? createdAt = row['created_at'];

        DateTime time;
        try {
          time = DateTime.parse(createdAt?.toString() ?? '')
              .toLocal();
        } catch (_) {
          time = DateTime.now();
        }

        history.add(
          ChatMessage(
            // Prefixed so it cannot collide with a live id, and so the
            // merge treats it as a distinct record.
            id: 'db_${row['id']}',
            from: senderId.toInt().toString(),
            to: (row['receiver_id'] as num?)?.toInt().toString() ??
                '',
            message: row['text']?.toString() ?? '',
            time: time,
            status: _statusFromServer(
              row['status']?.toString(),
            ),
            // Voice notes are stored with their clip.
            voiceBase64: row['audio']?.toString(),
          ),
        );
      }

      if (history.isEmpty) return;

      WebSocketService().mergeHistory(
        widget.contact.id,
        history,
      );

      if (!mounted) return;

      setState(() {
        messages = WebSocketService()
            .conversationWith(widget.contact.id);
      });
    } catch (_) {
      // History is an enhancement; the live stream still works without
      // it, so a failure here must not surface as an error state.
    }
  }

  MessageStatus _statusFromServer(String? status) {
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
        return MessageStatus.sent;
    }
  }

  void _listenMessages() {
    conversationSubscription =
        WebSocketService()
            .conversations
            .listen((_) {
      if (!mounted) return;

      setState(() {
        messages = WebSocketService()
            .conversationWith(widget.contact.id);
      });
    });
  }

  void _listenMessageStatus() {
    messageStatusSubscription =
        WebSocketService()
            .messageStatusStream
            .listen((statusMsg) {
      if (!mounted) return;

      // Only handle status updates for messages in this conversation
      final isFromContact = statusMsg.from == widget.contact.id;
      final isToContact = statusMsg.to == widget.contact.id;
      final isSelf = statusMsg.from == statusMsg.to && statusMsg.from == widget.contact.id;

      if (isFromContact || isToContact || isSelf) {
        setState(() {
          messages = WebSocketService()
              .conversationWith(widget.contact.id);
        });
      }
    });
  }

void _sendReadReceipts() {
    for (final msg in messages) {
      if (msg.from == widget.contact.id && msg.status != MessageStatus.read) {
        WebSocketService().sendReadReceipt(
          to: widget.contact.id,
          messageId: msg.id,
        );
      }
    }
  }

  Widget _buildStatusIcon(MessageStatus status) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final IconData icon;
    final Color color;
    const double size = 14;

    switch (status) {
      case MessageStatus.pending:
        icon = Icons.access_time_rounded;
        color = scheme.onSurfaceVariant;
        break;

      // Single blue tick: accepted by the server.
      case MessageStatus.sent:
        icon = Icons.done_rounded;
        color = scheme.primary;
        break;

      // Double green tick: reached the other person.
      case MessageStatus.delivered:
        icon = Icons.done_all_rounded;
        color = NovaColors.success;
        break;

      // Double blue tick: they have read it.
      case MessageStatus.read:
        icon = Icons.done_all_rounded;
        color = scheme.primary;
        break;

      case MessageStatus.failed:
        icon = Icons.error_outline_rounded;
        color = scheme.error;
        break;
    }

    return Icon(icon, size: size, color: color);
  }

  //---------------------------------------------------
  // Incoming Calls
  //---------------------------------------------------

  void _listenForCalls() {

  //---------------------------------------------------
  // Incoming Call
  //---------------------------------------------------

  incomingFileSubscription =
    WebSocketService()
        .incomingFiles
        .listen((file) {

  if (!mounted) return;

  incomingFileOverlay?.remove();

  incomingFileOverlay = OverlayEntry(

    builder: (_) => IncomingFileToast(
  sender: file["from"],
  fileName: file["name"],
  fileSize: file["size"],

  onAccept: () {
    print("Accept pressed");

    incomingFileOverlay?.remove();
    incomingFileOverlay = null;
  },

  onDecline: () {
    print("Decline pressed");

    incomingFileOverlay?.remove();
    incomingFileOverlay = null;
  },
)

  );

  Overlay.of(context).insert(
    incomingFileOverlay!,
  );

});

  incomingCallSubscription =
      WebSocketService()
          .incomingCalls
          .listen((caller) {

    if (!mounted) return;


    incomingCallOverlay?.remove();


    incomingCallOverlay = OverlayEntry(

builder: (_) => IncomingCallToast(
      // Resolved so the toast shows a name rather than a raw id.
      caller: WebSocketService().displayNameFor(caller) ?? caller,

    onAccept: () async {

      WebSocketService().acceptCall(caller);

      incomingCallOverlay?.remove();
      incomingCallOverlay = null;

      if (!mounted) return;

Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            // Resolve the numeric identity back to a person, otherwise
            // the call screen shows a raw id.
            username: WebSocketService()
                    .displayNameFor(caller) ??
                caller,
          ),
        ),
      );
    },

    onReject: () {

      WebSocketService().rejectCall(caller);

      incomingCallOverlay?.remove();
      incomingCallOverlay = null;

    },

  ),

);

Overlay.of(context).insert(
  incomingCallOverlay!,
);


  });



  //---------------------------------------------------
  // Call Accepted
  //---------------------------------------------------

  callAcceptedSubscription =
      WebSocketService()
          .callAccepted
          .listen((user) {

    if (!mounted) return;


    if (user == widget.contact.id) {

      setState(() {

        // optional:
        // update UI if needed

      });

    }

  });



  //---------------------------------------------------
  // Call Rejected
  //---------------------------------------------------

  callRejectedSubscription =
    WebSocketService()
        .callRejected
        .listen((user) {

  if (!mounted) return;


  if (user == widget.contact.id) {

    if (widget.onBack != null) {

      widget.onBack!();

    }

  }

});



  //---------------------------------------------------
  // Call Ended
  //---------------------------------------------------

  callEndedSubscription =
    WebSocketService()
        .callEnded
        .listen((user) {

  if (!mounted) return;


  if (user == widget.contact.id) {

    if (widget.onBack != null) {

      widget.onBack!();

    }

  }

});

}

  void _listenForFirebaseCalls() {
    if (!FirebaseService().isAvailable) return;

    final firebaseUid = widget.contact.firebaseUid;
    if (firebaseUid == null || firebaseUid.isEmpty) return;

    _firebaseCallSubscription = _dbRef
        .child('users/$firebaseUid/signaling/offers')
        .onChildAdded
        .listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map?;
      if (data == null) return;

      final from = data['from']?.toString() ?? '';
      final callId = data['callId']?.toString() ?? '';

      if (from.isEmpty || callId.isEmpty) return;

      if (!_wsConnected) {
        if (mounted) {
          setState(() {
            incomingCallOverlay ??= OverlayEntry(
              builder: (_) => IncomingCallToast(
                caller: from,
                onAccept: () async {
                  _acceptCallViaFirebase(firebaseUid, callId);
                  incomingCallOverlay?.remove();
                  incomingCallOverlay = null;
                },
                onReject: () {
                  _rejectCallViaFirebase(firebaseUid, callId);
                  incomingCallOverlay?.remove();
                  incomingCallOverlay = null;
                },
              ),
            );
            Overlay.of(context).insert(incomingCallOverlay!);
          });
        }
      }
    });
  }

  Future<void> _acceptCallViaFirebase(String firebaseUid, String callId) async {
    await _dbRef.child('users/$firebaseUid/signaling/offers/$callId').remove();
    WebSocketService().acceptCall(callId);
  }

  Future<void> _rejectCallViaFirebase(String firebaseUid, String callId) async {
    await _dbRef.child('users/$firebaseUid/signaling/offers/$callId').remove();
  }

  void _listenForFirebaseMessages() {
    if (!FirebaseService().isAvailable) return;

    final firebaseUid = widget.contact.firebaseUid;
    if (firebaseUid == null || firebaseUid.isEmpty) return;

    _firebaseMessageSubscription = _dbRef
        .child('users/$firebaseUid/messages')
        .onChildAdded
        .listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map?;
      if (data == null) return;

      final from = data['from']?.toString() ?? '';
      final text = data['text']?.toString() ?? '';
      final timestamp = data['timestamp'] as int?;

      if (from.isEmpty || text.isEmpty) return;

      final msg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        from: from,
        to: firebaseUid,
        message: text,
        time: DateTime.fromMillisecondsSinceEpoch(timestamp ?? DateTime.now().millisecondsSinceEpoch),
        status: MessageStatus.delivered,
      );

      if (!mounted) return;

      setState(() {
        messages.add(msg);
      });
    });
  }

  //---------------------------------------------------
  // Send Message
  //---------------------------------------------------

  void sendMessage() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    if (_wsConnected) {
      WebSocketService().send(
        to: widget.contact.id,
        message: text,
      );
    } else {
      // Queue it on the socket outbox instead of dropping it. The
      // previous Firebase fallback returned silently for every online
      // contact (they carry no firebase_uid), so the message vanished
      // and the composer was cleared anyway.
      WebSocketService().send(
        to: widget.contact.id,
        message: text,
      );

      _showQueuedNotice();
    }

    controller.clear();
  }

  /// Tells the user the message is waiting rather than lost, which is
  /// the difference between "broken" and "queued".
  void _showQueuedNotice() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: NovaChatColors.of(context).warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pulsar Chat is not connected to the server, '
                  'so this is queued and will send itself once the '
                  'connection is back.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _sendMessageViaFirebase(String text) async {
    if (!FirebaseService().isAvailable) return;

    final firebaseUid = widget.contact.firebaseUid;
    if (firebaseUid == null || firebaseUid.isEmpty) return;

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    await _dbRef.child('users/$firebaseUid/messages/$messageId').set({
      'from': firebaseUid,
      'text': text,
      'timestamp': ServerValue.timestamp,
      'status': 'sent',
    });
  }

  //---------------------------------------------------
  // UI
  //---------------------------------------------------

    //---------------------------------------------------
  // UI
  //---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final chat = NovaChatColors.of(context);

    return Column(
      children: [
        //---------------------------------------------------
        // HEADER
        //---------------------------------------------------

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),

              CircleAvatar(
                radius: 20,
                child: Text(
                  widget.contact.name[0].toUpperCase(),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contact.name,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _contactOnline
                                ? chat.online
                                : NovaColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _contactOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: _contactOnline
                                ? chat.online
                                : NovaColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),

                        // Surface our own link state, otherwise a queued
                        // message is the only clue the app is offline.
                        if (!_wsConnected) ...<Widget>[
                          const SizedBox(width: 10),
                          Text(
                            '· not connected',
                            style: TextStyle(
                              color: chat.warning,
                              fontSize: 12,
                            ),
                          ),
                        ] else ...<Widget>[
                          const SizedBox(width: 10),
                          Text(
                            '· connected',
                            style: TextStyle(
                              color: chat.online,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
  icon: const Icon(Icons.call),

  onPressed: () async {
  try {
    debugPrint("ðŸ“ž Starting call to ${widget.contact.id}");

    // 1. Tell the other user first.
    WebSocketService().callUser(
      widget.contact.id,
    );

    // 2. Configure the RTC target before initializing.
    RTCService().setRemoteUser(
      widget.contact.id,
    );

    // 3. Initialize WebRTC.
    await RTCService().initialize();

    debugPrint("ðŸ“ž RTC initialized");

    // 4. Create the offer.
    final offer =
        await RTCService().createOffer();

    debugPrint("ðŸ“ž Offer created");

    // 5. Send the offer through the EXISTING WebSocket.
    WebSocketService().sendOffer(
      widget.contact.id,
      offer,
    );

    debugPrint("ðŸ“ž Offer sent");

    if (!mounted) return;

    // 6. Open the call screen.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          username: widget.contact.name,
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint("âŒ Call start failed: $e");
    debugPrint("$stackTrace");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Could not start the call: $e",
        ),
      ),
    );
  }
},
 ),
            ],
          ),
        ),

        //---------------------------------------------------
        // MESSAGES
        //---------------------------------------------------

        Expanded(
          child: Container(
            // The message area carries the theme's chat background,
            // which is what gives the WhatsApp theme its familiar look.
            color: chat.chatBackground,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                final isMine =
                    message.from != widget.contact.id;

                return Align(
                  alignment: isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(
            maxWidth: 320,
          ),
          decoration: BoxDecoration(
            // Themed so a message follows the active theme, including
            // the WhatsApp-style green/white bubbles.
            color: isMine
                ? chat.bubbleOwn
                : chat.bubbleOther,
            borderRadius: BorderRadius.circular(18),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              message.voiceBase64 != null
                  ? VoiceMessageBubble(
                      audioBase64: message.voiceBase64!,
                      isMine: isMine,
                    )
                  : Text(
                      message.message,
                      style: TextStyle(
                        color: isMine
                            ? chat.bubbleOwnText
                            : chat.bubbleOtherText,
                      ),
                    ),
              if (isMine) ...[
                const SizedBox(height: 4),
                _buildStatusIcon(message.status),
              ],
            ],
          ),
        ),
      );
              },
            ),
          ),
        ),
        //---------------------------------------------------
        // INPUT
        //---------------------------------------------------

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
  icon: const Icon(
    Icons.attach_file,
    color: Colors.white70,
  ),
  onPressed: () async {

    final file =
        await FilePickerService().pickFile();

    if (file == null) return;

    final f = File(file);

 pendingFile = f;

 WebSocketService().sendFileOffer(
   to: widget.contact.id,
   name: f.path.split("\\").last,
   size: await f.length(),
 );

   },
 ),

        Expanded(
          child: TextField(
            controller: controller,
            // Read from the theme: hard-coded white left the composer
            // invisible on the light themes.
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: "Type a message...",
              hintStyle: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
            onSubmitted: (_) {
              sendMessage();
            },
          ),
        ),

               const SizedBox(width: 10),

 // ðŸ‘‡ REPLACE THE OLD ANIMATEDSWITCHER HERE
 AnimatedSwitcher(
   duration: const Duration(milliseconds: 200),

   child: _isRecording
       ? CircleAvatar(
           key: const ValueKey("recording-send"),
           radius: 26,
           backgroundColor: Theme.of(context).colorScheme.primary,
           child: IconButton(
             icon: const Icon(
               Icons.send,
               color: Colors.white,
             ),
             onPressed: () async {
               try {
                 final audioBase64 =
                     await VoiceRecordService().stop();

                 if (audioBase64 != null &&
                     audioBase64.isNotEmpty) {
                   WebSocketService().sendVoice(
                     to: widget.contact.id,
                     audio: audioBase64,
                   );
                 }
               } catch (e) {
                 debugPrint("Voice send error: $e");
               }

               if (mounted) {
                 setState(() {
                   _isRecording = false;
                 });
               }
             },
           ),
         )

       : controller.text.trim().isNotEmpty
           ? CircleAvatar(
               key: const ValueKey("send"),
               radius: 26,
               backgroundColor: Theme.of(context).colorScheme.primary,
               child: IconButton(
                 icon: const Icon(
                   Icons.send,
                   color: Colors.white,
                 ),
                 onPressed: sendMessage,
               ),
             )

           : CircleAvatar(
               key: const ValueKey("mic"),
               radius: 26,
               backgroundColor: Theme.of(context).colorScheme.primary,
               child: IconButton(
                 icon: const Icon(
                   Icons.mic,
                   color: Colors.white,
                 ),
                 onPressed: () async {
                   try {
                     await VoiceRecordService().start();

                     if (mounted) {
                       setState(() {
                         _isRecording = true;
                       });
                     }
                   } catch (e) {
                     debugPrint(
                       "Voice recording error: $e",
                     );
                   }
                 },
               ),
             ),
 ),
             ],
           ),
        ),
      ],
    );
  }
}
