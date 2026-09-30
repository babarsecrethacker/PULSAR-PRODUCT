import 'package:flutter/material.dart';

import '../../../core/models/sidebar_page.dart';
import '../../../core/services/conversation_inbox_service.dart';
import '../../../core/services/recent_contacts_service.dart';
import '../../../core/services/tray_service.dart';
import '../../../core/services/unread_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/nova_theme.dart';
import '../../../core/widgets/nova_drawer.dart';
import '../../../core/widgets/nova_panel.dart';
import '../../../core/widgets/nova_sidebar.dart';

import '../../chat/pages/chat_page.dart';
import '../../chat/pages/chats_page.dart';
import '../../contacts/models/contact.dart';
import '../../contacts/pages/contacts_page.dart';
import '../../lan/pages/lan_users_page.dart';
import '../../settings/pages/settings_page.dart';

import '../../online/pages/online_home_page.dart';

class HomeShell extends StatefulWidget {
  final String username;
  final int currentUserId;
  final Future<void> Function() onSwitchMode;

  /// Pending request coming from the Windows notification-area menu.
  final TrayAction? trayAction;
  final String? trayContactId;
  final VoidCallback? onTrayActionHandled;

  const HomeShell({
    super.key,
    required this.username,
    required this.currentUserId,
    required this.onSwitchMode,
    this.trayAction,
    this.trayContactId,
    this.onTrayActionHandled,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver {
  // Chats is the default destination: on a phone the rest of the screen
  // is meant to be the conversation, not a directory.
  SidebarPage selectedPage = SidebarPage.chats;

  Contact? selectedContact;

  /// Online contacts that have been opened at least once. The Chats page
  /// needs a stable list to render its "Online Users" section; the
  /// discovery page owns fetching the full directory.
  final List<Contact> _knownOnlineContacts = [];

  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    UnreadService.instance.start();
    UnreadService.instance.addListener(_onUnreadChanged);

    // Server-backed inbox: conversations persist across restarts and
    // messages that arrived while away are counted immediately.
    ConversationInboxService.instance.onUnreadArrived =
        _onInboxUnreadArrived;
    ConversationInboxService.instance.start(
      widget.currentUserId,
    );

    _unreadCount =
        UnreadService.instance.totalUnread +
        ConversationInboxService.instance.totalUnread;

    // Coming back to the app is the moment messages are most likely to
    // have arrived while it was in the background, so the inbox is
    // re-read rather than waiting for the next poll.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    ConversationInboxService.instance.refreshNow();
    _syncAfterOpening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UnreadService.instance.removeListener(_onUnreadChanged);
    ConversationInboxService.instance.onUnreadArrived = null;
    super.dispose();
  }

  /// Announces messages that were already waiting when the app caught
  /// up, so coming back online surfaces them without opening each chat.
  void _onInboxUnreadArrived(int total) {
    if (!mounted) return;

    setState(() {
      _unreadCount = UnreadService.instance.totalUnread + total;
    });

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    // Shown with a timer so it informs without blocking: the banner used
    // to sit on screen until "View" was pressed.
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          children: <Widget>[
            Icon(
              Icons.mark_chat_unread_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: NovaSpacing.md),
            Expanded(
              child: Text(
                total == 1
                    ? 'You have 1 unread message'
                    : 'You have $total unread messages',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
              ),
            ),
            // A close control, so the banner never traps the user even
            // when it is reporting something they want to act on.
            IconButton(
              onPressed: messenger.hideCurrentSnackBar,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
              ),
              color: Theme.of(context).colorScheme.onSurface,
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            setState(() {
              selectedPage = SidebarPage.chats;
            });
          },
        ),
      ),
    );
  }

  void _onUnreadChanged() {
    if (!mounted) return;
    setState(() {
      _unreadCount = UnreadService.instance.totalUnread +
          ConversationInboxService.instance.totalUnread;
    });

    // A live message arrived, so re-read the inbox instead of waiting
    // for the next poll. This is what makes the list and its previews
    // feel immediate rather than lagging behind the thread.
    ConversationInboxService.instance.refreshNow();

    // The tray tooltip is the only place an unread message shows while
    // the window is hidden, so keep it in step with the badge.
    TrayService.instance.updateTooltip(
      trayTooltip(
        appName: 'Pulsar Chat',
        unread: _unreadCount,
      ),
    );
  }

  // ==============================================================
  // TRAY ACTIONS
  // ==============================================================

  /// Applies a request that arrived from the notification-area menu.
  void _handleTrayAction(TrayAction action, String? contactId) {
    switch (action) {
      case TrayAction.open:
        setState(() {
          selectedPage = SidebarPage.chats;
        });

      case TrayAction.settings:
        // Bring the app forward and land directly on Settings.
        setState(() {
          selectedPage = SidebarPage.settings;
        });

      case TrayAction.checkUpdates:
        setState(() {
          selectedPage = SidebarPage.settings;
        });
        _runUpdateCheck();

      case TrayAction.openConversation:
        final Contact? target = _findContact(contactId);
        if (target != null) {
          _openConversation(target);
        }

      case TrayAction.quit:
        break;
    }

    widget.onTrayActionHandled?.call();
  }

  /// Resolves a tray contact id back to a usable [Contact]. LAN
  /// conversations can be rebuilt from the live user list; online ones
  /// are matched against the contacts already opened this session.
  Contact? _findContact(String? id) {
    if (id == null || id.isEmpty) return null;

    for (final Contact c in _knownOnlineContacts) {
      if (c.id == id) return c;
    }

    for (final String name in WebSocketService().cachedUsers) {
      if (name == id) return Contact.fromLanUser(name);
    }

    return null;
  }

  Future<void> _runUpdateCheck() async {
    final UpdateResult result = await UpdateService.check();

    if (!mounted) return;

    final String message;
    final bool isError;
    final IconData icon;

    switch (result) {
      case AlreadyUpToDate():
        message = 'Pulsar Chat is up to date.';
        isError = false;
        icon = Icons.verified_outlined;

      case UpdateCheckFailed(message: final String text):
        message = text;
        isError = true;
        icon = Icons.error_outline_rounded;

      case UpdateAvailable(latestVersion: final String latest):
        message = 'Update $latest is available.\n'
            'Open Settings for details.';
        isError = false;
        icon = Icons.system_update_rounded;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: isError
                    ? NovaColors.danger
                    : NovaColors.success,
              ),
              const SizedBox(width: NovaSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  // ==============================================================
  // NAVIGATION
  // ==============================================================

  /// Opens [contact] in the chat view from anywhere in the shell. Every
  /// entry point (discovery, LAN list, contacts, chat list) funnels
  /// through here so the conversation is always marked as read.
  void _openConversation(Contact contact) {
    _rememberOnlineContact(contact);

    UnreadService.instance.setActiveContact(contact.id);

    // Keep the tray's recent list in step with what the user opens.
    RecentContactsService.instance.record(
      contact.id,
      contact.name,
    );

    setState(() {
      selectedContact = contact;
      selectedPage = SidebarPage.chats;
    });
  }

  /// Re-reads the inbox so an opened conversation stops showing as
  /// unread straight away.
  void _syncAfterOpening() {
    ConversationInboxService.instance.refreshNow();
  }

  void _rememberOnlineContact(Contact contact) {
    if (contact.id.isEmpty) return;
    if (contact.id == widget.username) return;

    // LAN contacts are bare names; they are rendered by their own
    // section in the chat list, so only track account-based contacts.
    if (contact.firebaseUid == null &&
        contact.id == contact.name) {
      return;
    }

    final int existing = _knownOnlineContacts.indexWhere(
      (Contact c) => c.id == contact.id,
    );

    if (existing >= 0) {
      _knownOnlineContacts[existing] = contact;
    } else {
      _knownOnlineContacts.add(contact);
    }
  }

  void _closeConversation() {
    UnreadService.instance.setActiveContact(null);

    setState(() {
      selectedContact = null;
    });
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  /// Below this width the hover rail is replaced by a drawer: a rail
  /// that expands on hover is meaningless on touch, and it would eat a
  /// phone's whole width.
  static const double _railBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    if (widget.trayAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTrayAction(
          widget.trayAction!,
          widget.trayContactId,
        );
      });
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        return c.maxWidth >= _railBreakpoint
            ? _buildWide(context)
            : _buildNarrow(context);
      },
    );
  }

  void _onPageSelected(SidebarPage page) {
    // Leaving the chat view releases the active conversation so new
    // messages count as unread again.
    if (page != SidebarPage.chats) {
      UnreadService.instance.setActiveContact(null);
    }

    setState(() {
      selectedPage = page;
      if (page == SidebarPage.chats && selectedContact == null) {
        UnreadService.instance.markAllRead();
      }
    });
  }

  /// Desktop / tablet: persistent hover rail beside the content.
  Widget _buildWide(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NovaSidebar(
              username: widget.username,
              onSwitchMode: widget.onSwitchMode,
              selectedPage: selectedPage,
              unreadCount: _unreadCount,
              onPageSelected: _onPageSelected,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(NovaSpacing.lg),
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

  /// Phone: a menu button opens the drawer, the rest of the screen is
  /// the conversation.
  Widget _buildNarrow(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surfaceContainerHighest,
      drawer: NovaDrawer(
        username: widget.username,
        selectedPage: selectedPage,
        onPageSelected: _onPageSelected,
        onSwitchMode: widget.onSwitchMode,
      ),
      body: Column(
        children: <Widget>[
          // A Builder so the menu button can reach the enclosing
          // ScaffoldState and open the drawer.
          Builder(
            builder: (BuildContext innerContext) {
              return SafeArea(
                // Keeps the title clear of the status bar clock, which
                // it was overlapping on a phone.
                bottom: false,
                child: NovaMobileBar(
                  title: _titleForPage(),
                  unreadCount: _unreadCount,
                  onMenuPressed: () =>
                      Scaffold.of(innerContext).openDrawer(),
                ),
              );
            },
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(NovaSpacing.sm),
              child: NovaPanel(
                child: _buildNarrowPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// On a phone a page owns the whole screen.
  ///
  /// Reusing the desktop layout here squeezed the conversation list into
  /// a fixed 240px column and left the rest of the display blank, which
  /// looked like the app had crashed.
  Widget _buildNarrowPage() {
    try {
      if (selectedPage == SidebarPage.chats) {
        if (selectedContact != null) {
          return ChatPage(
            key: ValueKey(selectedContact!.id),
            contact: selectedContact!,
            currentUserId: widget.currentUserId,
            onBack: _closeConversation,
          );
        }

        return ChatsPage(
          selectedContact: selectedContact,
          onlineContacts:
              List<Contact>.unmodifiable(_knownOnlineContacts),
          onConversationSelected: _openConversation,
        );
      }

      return _buildCurrentPage();
    } catch (e, stack) {
      // A layout failure on a phone used to leave a blank surface with
      // nothing in the log. Surfacing it means a broken page is at least
      // visible instead of looking like a dead app.
      debugPrint('❌ Narrow page failed to render: $e\n$stack');

      return const _NarrowError();
    }
  }

  String _titleForPage() {
    switch (selectedPage) {
      case SidebarPage.chats:
        return 'Chats';
      case SidebarPage.onlineUsers:
        return 'Online Users';
      case SidebarPage.lanUsers:
        return 'LAN Users';
      case SidebarPage.contacts:
        return 'Contacts';
      case SidebarPage.calls:
        return 'Calls';
      case SidebarPage.files:
        return 'Files';
      case SidebarPage.settings:
        return 'Settings';
    }
  }

  Widget _buildCurrentPage() {
    switch (selectedPage) {
      // ==========================================================
      // ONLINE DISCOVERY
      //
      // Selecting a person moves straight to the conversation; the
      // directory never expands into a split view.
      // ==========================================================

      case SidebarPage.onlineUsers:
        return OnlineHomePage(
          currentUserId: widget.currentUserId,
          onMessage: _openConversation,
        );

      // ==========================================================
      // LAN USERS - directory only, no message thread
      // ==========================================================

      case SidebarPage.lanUsers:
        return LanUsersPage(
          selectedUser: selectedContact,
          onUserSelected: _openConversation,
        );

      // ==========================================================
      // CHATS - conversation list beside the open thread
      // ==========================================================

      case SidebarPage.chats:
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            // The conversation list collapses to zero and the thread
            // takes over on narrow windows, instead of the fixed 320px
            // rail forcing a horizontal overflow.
            final bool wide = c.maxWidth >= 760;

            if (!wide && selectedContact != null) {
              return ChatPage(
                key: ValueKey(selectedContact!.id),
                contact: selectedContact!,
                currentUserId: widget.currentUserId,
                onBack: _closeConversation,
              );
            }

            return Row(
              children: <Widget>[
                SizedBox(
                  width: wide ? 320 : 240,
                  child: ChatsPage(
                    selectedContact: selectedContact,
                    onlineContacts:
                        List<Contact>.unmodifiable(
                      _knownOnlineContacts,
                    ),
                    onConversationSelected: _openConversation,
                  ),
                ),

                if (wide) ...<Widget>[
                  const SizedBox(width: NovaSpacing.lg),

                  Expanded(
                    child: selectedContact == null
                        ? const _NoConversationSelected()
                        : ChatPage(
                            key: ValueKey(
                              selectedContact!.id,
                            ),
                            contact: selectedContact!,
                            currentUserId: widget.currentUserId,
                            onBack: _closeConversation,
                          ),
                  ),
                ],
              ],
            );
          },
        );

      // ==========================================================
      // CONTACTS
      // ==========================================================

      case SidebarPage.contacts:
        return ContactsPage(
          selectedContact: selectedContact,
          onContactSelected: _openConversation,
        );

      // ==========================================================
      // CALLS
      // ==========================================================

      case SidebarPage.calls:
        return const _Placeholder(
          icon: Icons.call_outlined,
          title: 'Calls',
          subtitle:
              'Call history will appear here.',
        );

      // ==========================================================
      // FILES
      // ==========================================================

      case SidebarPage.files:
        return const _Placeholder(
          icon: Icons.folder_outlined,
          title: 'Files',
          subtitle:
              'Shared files will appear here.',
        );

      // ==========================================================
      // SETTINGS
      // ==========================================================

      case SidebarPage.settings:
        return const SettingsPage();
    }
  }
}

class _NarrowError extends StatelessWidget {
  const _NarrowError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NovaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.report_gmailerrorred_outlined,
              size: 42,
              color: NovaColors.danger,
            ),
            const SizedBox(height: NovaSpacing.lg),
            Text(
              'This screen could not be displayed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: NovaSpacing.xs),
            Text(
              'Try switching mode, or reopen the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoConversationSelected extends StatelessWidget {
  const _NoConversationSelected();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NovaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: NovaColors.textDisabled,
              size: 52,
            ),
            const SizedBox(height: NovaSpacing.lg),
            Text(
              'Select a conversation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: NovaSpacing.sm),
            Text(
              'Choose someone from the list to start chatting.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Placeholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 46, color: NovaColors.textDisabled),
          const SizedBox(height: NovaSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: NovaSpacing.xs),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
