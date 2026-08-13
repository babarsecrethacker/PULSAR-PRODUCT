import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/websocket_service.dart';
import '../../contacts/models/contact.dart';

class LanUsersPage extends StatefulWidget {
  final Contact? selectedUser;
  final ValueChanged<Contact> onUserSelected;

  const LanUsersPage({
    super.key,
    required this.selectedUser,
    required this.onUserSelected,
  });

  @override
  State<LanUsersPage> createState() => _LanUsersPageState();
}

class _LanUsersPageState extends State<LanUsersPage> {
  final List<Contact> users = [];

  StreamSubscription<List<String>>? usersSubscription;

  @override
  void initState() {
    super.initState();

    users
  ..clear()
  ..addAll(
    WebSocketService()
        .cachedUsers
        .map((name) => Contact.fromLanUser(name)),
  );

    usersSubscription =
        WebSocketService().users.listen((lanUsers) {
      if (!mounted) return;

      setState(() {
        users
          ..clear()
          ..addAll(
            lanUsers.map(Contact.fromLanUser),
          );
      });
    });
  }

  @override
  void dispose() {
    usersSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        const Text(
          "LAN Users",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: "Search LAN users...",
              hintStyle:
                  const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white54,
              ),
              filled: true,
              fillColor: const Color(0xff20222C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        Expanded(
          child: users.isEmpty
              ? const Center(
                  child: Text(
                    "No LAN users online",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];

                    final selected =
                        widget.selectedUser?.id == user.id;

                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(18),
                        onTap: () =>
                            widget.onUserSelected(user),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xff5B5FEF)
                                : const Color(0xff1B1D26),
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    Colors.deepPurple,
                                child: Text(
                                  user.name[0]
                                      .toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      user.name,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(
                                        height: 3),
                                    const Text(
                                      "Online",
                                      style: TextStyle(
                                        color:
                                            Colors.greenAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}