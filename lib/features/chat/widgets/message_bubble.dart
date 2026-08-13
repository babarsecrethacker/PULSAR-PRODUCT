import 'package:flutter/material.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final String? voiceBase64;
  final bool isMe;
  final String time;

  const MessageBubble({
    super.key,
    required this.message,
    this.voiceBase64,
    required this.isMe,
    required this.time,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  late final Animation<double> fade;

  late final Animation<Offset> slide;

  late final Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    fade = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );

    slide = Tween<Offset>(
      begin: Offset(
        widget.isMe ? .18 : -.18,
        .10,
      ),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );

    scale = Tween<double>(
      begin: .96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ),
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
    final bool mine = widget.isMe;

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(
          scale: scale,
          child: Align(
            alignment:
                mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 460,
              ),
              margin: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (mine)
                    BoxShadow(
                      color: const Color(0xff7C4DFF)
                          .withOpacity(.35),
                      blurRadius: 22,
                      spreadRadius: -8,
                    ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: mine
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xff8A63FF),
                            Color(0xff5B5FEF),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(.08),
                            Colors.white.withOpacity(.04),
                          ],
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft:
                        Radius.circular(mine ? 24 : 8),
                    bottomRight:
                        Radius.circular(mine ? 8 : 24),
                  ),
                  border: Border.all(
                    color: mine
                        ? Colors.white.withOpacity(.10)
                        : Colors.white.withOpacity(.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    widget.voiceBase64 != null
    ? Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 26,
          ),
          SizedBox(width: 8),
          Text(
            "Voice message",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      )
    : Text(
        widget.message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.5,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.time,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.55),
                            fontSize: 11,
                          ),
                        ),

                        if (mine) ...[
                          const SizedBox(width: 6),

                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: 1,
                            ),
                            duration:
                                const Duration(milliseconds: 700),
                            builder: (_, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.scale(
                                  scale: value,
                                  child: child,
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.done_all_rounded,
                              size: 16,
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}