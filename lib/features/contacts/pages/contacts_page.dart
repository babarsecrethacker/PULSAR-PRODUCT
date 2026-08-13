import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/websocket_service.dart';
import '../models/contact.dart';
import '../widgets/contact_tile.dart';

class ContactsPage extends StatefulWidget {
  final Contact? selectedContact;
  final ValueChanged<Contact> onContactSelected;

  const ContactsPage({
    super.key,
    required this.selectedContact,
    required this.onContactSelected,
  });

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final TextEditingController searchController =
      TextEditingController();

  final List<Contact> contacts = [];

  StreamSubscription<List<String>>? usersSubscription;

  @override
  void initState() {
    super.initState();

    usersSubscription =
        WebSocketService().users.listen((users) {
      if (!mounted) return;

      setState(() {
        contacts
          ..clear()
          ..addAll(
            users
                .map((e) => Contact.fromLanUser(e))
                .toList(),
          );
      });
    });
  }

  @override
  void dispose() {
    usersSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query =
        searchController.text.trim().toLowerCase();

    final filtered = contacts.where((contact) {
      return contact.name
          .toLowerCase()
          .contains(query);
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 20),

        const Text(
          "LAN Users",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          child: TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: "Search LAN users...",
              hintStyle: const TextStyle(
                color: Colors.white38,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white54,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(.05),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    "No LAN users online",
                    style: TextStyle(
                      color: Colors.white38,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final contact = filtered[index];

                    return ContactTile(
                      contact: contact,
                      selected: widget
                              .selectedContact
                              ?.id ==
                          contact.id,
                      onTap: () {
                        widget.onContactSelected(
                          contact,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}