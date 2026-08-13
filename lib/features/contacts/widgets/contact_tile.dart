import 'package:flutter/material.dart';

import '../models/contact.dart';

class ContactTile extends StatefulWidget {
  final Contact contact;
  final VoidCallback onTap;

  final bool selected;

  const ContactTile({
    super.key,
    required this.contact,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.selected || hover;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hover = true;
        });
      },
      onExit: (_) {
        setState(() {
          hover = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: highlight
                ? const Color(0xff5B5FEF).withOpacity(.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight
                  ? const Color(0xff7C4DFF)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xff5B5FEF),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: widget.contact.online
                            ? Colors.greenAccent
                            : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xff10131F),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contact.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.contact.typing
                          ? "Typing..."
                          : (widget.contact.lastMessage.isEmpty
                              ? "Online on LAN"
                              : widget.contact.lastMessage),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.contact.typing
                            ? Colors.greenAccent
                            : Colors.white60,
                        fontSize: 12,
                        fontStyle: widget.contact.typing
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    widget.contact.online
                        ? "Online"
                        : widget.contact.lastSeen,
                    style: TextStyle(
                      color: widget.contact.online
                          ? Colors.greenAccent
                          : Colors.white38,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (widget.contact.unread > 0)
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xff7C4DFF),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.contact.unread.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}