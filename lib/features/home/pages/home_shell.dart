import 'package:flutter/material.dart';

import '../../../core/models/sidebar_page.dart';
import '../../../core/widgets/nova_panel.dart';
import '../../../core/widgets/nova_sidebar.dart';

import '../../chat/pages/chat_page.dart';
import '../../contacts/models/contact.dart';
import '../../contacts/pages/contacts_page.dart';
import '../../lan/pages/lan_users_page.dart';
import '../../settings/pages/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  SidebarPage selectedPage = SidebarPage.lanUsers;

  Contact? selectedContact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111315),
      body: SafeArea(
        child: Row(
          children: [
            // ======================================================
            // SIDEBAR
            // ======================================================

            NovaSidebar(
              selectedPage: selectedPage,
              onPageSelected: (page) {
                setState(() {
                  selectedPage = page;
                });
              },
            ),

            // ======================================================
            // MAIN AREA
            // ======================================================

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: NovaPanel(
                  child: _buildCurrentPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // CURRENT PAGE
  // ==============================================================

  Widget _buildCurrentPage() {
    switch (selectedPage) {
      // ==========================================================
      // LAN USERS
      // ==========================================================

      case SidebarPage.lanUsers:
        return Row(
          children: [
            // ------------------------------------------------------
            // LEFT PANEL
            // ------------------------------------------------------

            SizedBox(
              width: 300,
              child: LanUsersPage(
                selectedUser: selectedContact,
                onUserSelected: (contact) {
                  setState(() {
                    selectedContact = contact;
                  });
                },
              ),
            ),

            const SizedBox(width: 16),

            // ------------------------------------------------------
            // RIGHT PANEL
            // ------------------------------------------------------

            Expanded(
              child: AnimatedSwitcher(
                duration:
                    const Duration(milliseconds: 250),
                child: selectedContact == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white24,
                              size: 72,
                            ),
                            SizedBox(height: 18),
                            Text(
                              'Select a conversation',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Choose someone from the left to start chatting.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ChatPage(
                        key: ValueKey(
                          selectedContact!.id,
                        ),
                        contact: selectedContact!,
                        onBack: () {
                          setState(() {
                            selectedContact = null;
                          });
                        },
                      ),
              ),
            ),
          ],
        );

      // ==========================================================
      // CHATS
      // ==========================================================

      case SidebarPage.chats:
        if (selectedContact == null) {
          return const Center(
            child: Text(
              'No conversation selected',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 22,
              ),
            ),
          );
        }

        return ChatPage(
          key: ValueKey(
            selectedContact!.id,
          ),
          contact: selectedContact!,
          onBack: () {
            setState(() {
              selectedContact = null;
            });
          },
        );

      // ==========================================================
      // CONTACTS
      // ==========================================================

      case SidebarPage.contacts:
        return ContactsPage(
          selectedContact: selectedContact,
          onContactSelected: (contact) {
            setState(() {
              selectedContact = contact;
              selectedPage = SidebarPage.chats;
            });
          },
        );

      // ==========================================================
      // CALLS
      // ==========================================================

      case SidebarPage.calls:
        return const Center(
          child: Text(
            'Calls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        );

      // ==========================================================
      // FILES
      // ==========================================================

      case SidebarPage.files:
        return const Center(
          child: Text(
            'Files',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        );

      // ==========================================================
      // SETTINGS
      // ==========================================================

      case SidebarPage.settings:
        return const SettingsPage();
    }
  }
}