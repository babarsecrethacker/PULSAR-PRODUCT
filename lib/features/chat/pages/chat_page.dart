import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import '../widgets/voice_message_bubble.dart';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/services/websocket_service.dart';

import '../../call/pages/call_page.dart';
import '../../contacts/models/contact.dart';

import '../../call/widgets/incoming_call_toast.dart';
import '../../call/services/rtc_service.dart';

import '../../../core/services/voice_record_service.dart';

import '../../../core/services/file_picker_service.dart';
import 'dart:io';

import '../../files/widgets/incoming_file_toast.dart';

class ChatPage extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onBack;

  const ChatPage({
    super.key,
    required this.contact,
    this.onBack,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller =
      TextEditingController();

      final AudioPlayer _player = AudioPlayer();

bool _isPlayingVoice = false;
bool _isRecording = false;

      File? pendingFile;

  List<ChatMessage> messages = [];

  OverlayEntry? incomingCallOverlay;

  OverlayEntry? incomingFileOverlay;

  StreamSubscription? conversationSubscription;

StreamSubscription<Map<String, dynamic>>? incomingFileSubscription;
StreamSubscription<Map<String, dynamic>>? fileReadySubscription;

  StreamSubscription<String>? incomingCallSubscription;
  StreamSubscription<String>? callAcceptedSubscription;
  StreamSubscription<String>? callRejectedSubscription;
  StreamSubscription<String>? callEndedSubscription;

  @override
  void initState() {
    super.initState();

    _loadConversation();

    _listenMessages();

    _listenForCalls();

    controller.addListener(() {
  if (mounted) {
    setState(() {});
  }
});
  }

  @override
  void dispose() {

    conversationSubscription?.cancel();

    incomingCallSubscription?.cancel();
    callAcceptedSubscription?.cancel();
    callRejectedSubscription?.cancel();
    callEndedSubscription?.cancel();

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

    caller: caller,

    onAccept: () async {

      WebSocketService().acceptCall(caller);

      incomingCallOverlay?.remove();
      incomingCallOverlay = null;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            username: caller,
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


  //---------------------------------------------------
  // Send Message
  //---------------------------------------------------

  void sendMessage() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    WebSocketService().send(
      to: widget.contact.id,
      message: text,
    );

    controller.clear();
  }

  //---------------------------------------------------
  // UI
  //---------------------------------------------------

    //---------------------------------------------------
  // UI
  //---------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Online",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
  icon: const Icon(Icons.call),

  onPressed: () async {

    //----------------------------------
    // Tell other user we are calling
    //----------------------------------

    WebSocketService().callUser(
      widget.contact.id,
    );

    //----------------------------------
    // Initialize WebRTC
    //----------------------------------

    await RTCService().initialize();

    RTCService().setRemoteUser(
  widget.contact.id,
);

    //----------------------------------
    // Create Offer
    //----------------------------------

    final offer =
        await RTCService().createOffer();

    //----------------------------------
    // Send Offer
    //----------------------------------

    WebSocketService().sendOffer(
      widget.contact.id,
      offer,
    );

    //----------------------------------
    // Open Calling Screen
    //----------------------------------

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          username: widget.contact.name,
        ),
      ),
    );
  },
),
            ],
          ),
        ),

        //---------------------------------------------------
        // MESSAGES
        //---------------------------------------------------

        Expanded(
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
            color: isMine
                ? const Color(0xFF6C63FF)
                : const Color(0xFF1A2335),
            borderRadius: BorderRadius.circular(18),
          ),

          child: message.voiceBase64 != null
    ? VoiceMessageBubble(
        audioBase64: message.voiceBase64!,
        isMine: isMine,
      )
    : Text(
        message.message,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
        ),
      );
    },
  ),
),
        //---------------------------------------------------
        // INPUT
        //---------------------------------------------------

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                Colors.white.withValues(alpha: .05),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(
                    alpha: .08),
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
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                    ),
                    filled: true,
                    fillColor:
                        Colors.white.withValues(
                            alpha: .08),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(30),
                      borderSide:
                          BorderSide.none,
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

// 👇 REPLACE THE OLD ANIMATEDSWITCHER HERE
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),

  child: _isRecording
      ? CircleAvatar(
          key: const ValueKey("recording-send"),
          radius: 26,
          backgroundColor: const Color(0xFF6C63FF),
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
              backgroundColor: const Color(0xFF6C63FF),
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
              backgroundColor: const Color(0xFF6C63FF),
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