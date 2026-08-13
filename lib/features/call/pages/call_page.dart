import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/call_avatar.dart';
import '../widgets/call_status.dart';
import '../widgets/call_controls.dart';

import '../../../core/services/websocket_service.dart';
import '../services/rtc_service.dart';

class CallPage extends StatefulWidget {
  final String username;

  const CallPage({
    super.key,
    required this.username,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with SingleTickerProviderStateMixin {

  late AnimationController glowController;

  Timer? timer;

  StreamSubscription<String>? acceptedSubscription;
StreamSubscription<String>? rejectedSubscription;
StreamSubscription<String>? endedSubscription;

  int seconds = 0;

  String status = "Calling...";
  bool micMuted = false;

  @override
  void initState() {
    super.initState();

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ),
    )..repeat(reverse: true);

    startTimer();
    listenForCallEvents();

  }

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          seconds++;
        });
      },
    );
  }

  void listenForCallEvents() {
  acceptedSubscription =
      WebSocketService().callAccepted.listen((user) {
    if (!mounted) return;

    if (user == widget.username) {
      setState(() {
        status = "Connected";
      });
    }
  });

  rejectedSubscription =
      WebSocketService().callRejected.listen((user) {
    if (!mounted) return;

    if (user == widget.username &&
    Navigator.canPop(context)) {

  Navigator.pop(context);

}
  });

  endedSubscription =
      WebSocketService().callEnded.listen((user) {
    if (!mounted) return;

    if (user == widget.username &&
    Navigator.canPop(context)) {

  Navigator.pop(context);

}
  });
}

  String formattedTime() {
    final m =
        (seconds ~/ 60)
            .toString()
            .padLeft(2, '0');

    final s =
        (seconds % 60)
            .toString()
            .padLeft(2, '0');

    return "$m:$s";
  }

  void endCall() {

  WebSocketService().endCall(
    widget.username,
  );


  Navigator.pop(context);

}

  @override
  void dispose() {
    timer?.cancel();
    glowController.dispose();
    acceptedSubscription?.cancel();
rejectedSubscription?.cancel();
endedSubscription?.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {

  return Scaffold(

    backgroundColor: const Color(0xff08111F),

    body: SafeArea(

      child: Stack(

        children: [

          //--------------------------------
          // Galaxy Background
          //--------------------------------

          AnimatedBuilder(

            animation: glowController,

            builder: (context, child) {

              return Container(

                decoration: BoxDecoration(

                  gradient: RadialGradient(

                    radius: 1.1 + glowController.value * .15,

                    colors: const [

                      Color(0xff5B5FEF),

                      Color(0xff162040),

                      Color(0xff08111F),

                    ],

                  ),

                ),

              );

            },

          ),

          //--------------------------------
          // Main Content
          //--------------------------------

          Center(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                const Text(

                  "NOVASPACE",

                  style: TextStyle(

                    color: Colors.white70,

                    letterSpacing: 5,

                    fontWeight: FontWeight.bold,

                    fontSize: 16,

                  ),

                ),

                const SizedBox(height: 40),

                CallAvatar(
                  animation: glowController,
                ),

                const SizedBox(height: 30),

                Text(

                  widget.username,

                  style: const TextStyle(

                    color: Colors.white,

                    fontSize: 34,

                    fontWeight: FontWeight.bold,

                  ),

                ),

                const SizedBox(height: 10),

                const Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Icon(

                      Icons.lock,

                      color: Colors.greenAccent,

                      size: 16,

                    ),

                    SizedBox(width: 8),

                    Text(

                      "End-to-End Encrypted",

                      style: TextStyle(

                        color: Colors.white60,

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 28),

                CallStatus(
                  status: status,
                ),

                const SizedBox(height: 12),

                Text(

                  formattedTime(),

                  style: const TextStyle(

                    color: Colors.white,

                    fontSize: 42,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ],

            ),

          ),

          //--------------------------------
          // Controls (Middle Right)
          //--------------------------------

          Align(

            alignment: Alignment.centerRight,

            child: Padding(

              padding: const EdgeInsets.only(right: 25),

              child: CallControls(
  micMuted: micMuted,
  onEnd: endCall,
  onMic: () {
    final stream = RTCService().localStream;

    if (stream == null) return;

    final track = stream.getAudioTracks().first;

    micMuted = !micMuted;

    track.enabled = !micMuted;

    setState(() {});
  },
  onSpeaker: () {},
  onVideo: () {},
),

            ),

          ),

        ],

      ),

    ),

  );

}

}