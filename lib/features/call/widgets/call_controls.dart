import 'package:flutter/material.dart';

class CallControls extends StatelessWidget {
  final bool micMuted;

  final VoidCallback onEnd;
  final VoidCallback onMic;
  final VoidCallback onSpeaker;
  final VoidCallback onVideo;

  const CallControls({
    super.key,
    required this.micMuted,
    required this.onEnd,
    required this.onMic,
    required this.onSpeaker,
    required this.onVideo,
  });

  Widget buildButton(
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 25,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white10,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildButton(
              micMuted ? Icons.mic_off : Icons.mic,
              micMuted ? Colors.red : Colors.blueGrey,
              onMic,
            ),

            const SizedBox(height: 14),

            buildButton(
              Icons.volume_up,
              Colors.blueGrey,
              onSpeaker,
            ),

            const SizedBox(height: 14),

            buildButton(
              Icons.videocam,
              Colors.blueGrey,
              onVideo,
            ),

            const SizedBox(height: 14),

            buildButton(
              Icons.call_end,
              Colors.red,
              onEnd,
            ),
          ],
        ),
      ),
    );
  }
}