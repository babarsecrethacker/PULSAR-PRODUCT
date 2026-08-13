import 'package:flutter/material.dart';

class IncomingCallToast extends StatefulWidget {
  final String caller;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallToast({
    super.key,
    required this.caller,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<IncomingCallToast> createState() =>
      _IncomingCallToastState();
}

class _IncomingCallToastState
    extends State<IncomingCallToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  late final Animation<Offset> slide;

  late final Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    slide = Tween<Offset>(
      begin: const Offset(1.2, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );

    fade = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 18,
            right: 18,
          ),
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: fade,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xff171C28),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.35),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Row(
                        children: [
                          Icon(
                            Icons.call_rounded,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Incoming Voice Call",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      CircleAvatar(
                        radius: 34,
                        backgroundColor:
                            const Color(0xff5B5FEF),
                        child: Text(
                          widget.caller[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        widget.caller,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        "NovaSpace LAN",
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [

                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onReject,
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize:
                                    const Size(0, 46),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          14),
                                ),
                              ),
                              child: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onAccept,
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green,
                                minimumSize:
                                    const Size(0, 46),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          14),
                                ),
                              ),
                              child: const Icon(
                                Icons.call,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}