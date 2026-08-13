import 'package:flutter/material.dart';

class IncomingCallPage extends StatefulWidget {
  final String caller;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallPage({
    super.key,
    required this.caller,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<IncomingCallPage> createState() =>
      _IncomingCallPageState();
}

class _IncomingCallPageState
    extends State<IncomingCallPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  late final Animation<double> glow;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1400,
      ),
    )..repeat(reverse: true);

    glow = Tween<double>(
      begin: 0.85,
      end: 1.12,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff08111F),
      body: Stack(
        children: [

          //-----------------------------------
          // Background Glow
          //-----------------------------------

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.2,
                  colors: [
                    Color(0xff25376E),
                    Color(0xff08111F),
                  ],
                ),
              ),
            ),
          ),

          //-----------------------------------
          // Main
          //-----------------------------------

          SafeArea(
            child: Center(
              child: Column(
                children: [

                  const Spacer(),

                  const Icon(
                    Icons.call,
                    color: Colors.greenAccent,
                    size: 42,
                  ),

                  const SizedBox(
                    height: 26,
                  ),

                  AnimatedBuilder(
  animation: glow,
  builder: (_, __) {
    return SizedBox(
      width: 185,
      height: 185,
      child: Stack(
        alignment: Alignment.center,
        children: [

          //--------------------------------
          // Outer Glow Ring
          //--------------------------------

          Transform.scale(
            scale: glow.value,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff6C63FF).withOpacity(.08),
              ),
            ),
          ),

          //--------------------------------
          // Middle Ring
          //--------------------------------

          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xff6C63FF),
                width: 2,
              ),
            ),
          ),

          //--------------------------------
          // Avatar
          //--------------------------------

          CircleAvatar(
            radius: 58,
            backgroundColor: const Color(0xff252C47),
            child: Text(
              widget.caller[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  },
),

                  const SizedBox(
                    height: 30,
                  ),

                  Text(
  widget.caller,
  style: const TextStyle(
    color: Colors.white,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  ),
),

const SizedBox(height: 14),

Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 6,
  ),
  decoration: BoxDecoration(
    color: Colors.greenAccent.withOpacity(.08),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.greenAccent.withOpacity(.25),
    ),
  ),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.lock_outline_rounded,
        size: 16,
        color: Colors.greenAccent,
      ),
      SizedBox(width: 8),
      Text(
        "End-to-End Encrypted",
        style: TextStyle(
          color: Colors.greenAccent,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ],
  ),
),

const SizedBox(height: 18),

const Text(
  "Incoming Voice Call",
  style: TextStyle(
    color: Colors.white70,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  ),
),

                  const Spacer(),

                                    //-----------------------------------
                  // Buttons
                  //-----------------------------------

                  Padding(
  padding: const EdgeInsets.only(
    bottom: 48,
    left: 36,
    right: 36,
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [

      //--------------------------------
      // Reject
      //--------------------------------

      Column(
        children: [

          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: widget.onReject,
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xffE53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Decline",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),

      //--------------------------------
      // Accept
      //--------------------------------

      Column(
        children: [

          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: widget.onAccept,
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xff2ECC71),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Accept",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ],
  ),
),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}