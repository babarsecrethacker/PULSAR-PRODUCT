import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/conversation_inbox_service.dart';
import '../../../core/services/unread_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/nova_theme.dart';
import '../../contacts/models/contact.dart';

/// Conversation list for the Chats section.
///
/// LAN and online contacts are kept in separate, clearly labelled
/// sections rather than being merged, because the two groups behave
/// very differently: a LAN contact is a bare name discovered on the
/// local network, while an online contact is a PULSAR account with an
/// id, a profile picture and a Firebase UID behind it.
class ChatsPage extends StatefulWidget {
  final Contact? selectedContact;
  final ValueChanged<Contact> onConversationSelected;
  final List<Contact> onlineContacts;

  const ChatsPage({
    super.key,
    required this.selectedContact,
    required this.onConversationSelected,
    required this.onlineContacts,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final List<Contact> _lanContacts = [];

  StreamSubscription<List<String>>? _usersSubscription;
  String _query = '';

  @override
  void initState() {
    super.initState();

    // The inbox is the source of truth for the list, so the page has to
    // rebuild when it changes.
    ConversationInboxService.instance.addListener(_onInboxChanged);

    _lanContacts.addAll(
      WebSocketService()
          .cachedUsers
          .map(Contact.fromLanUser),
    );

    _usersSubscription =
        WebSocketService().users.listen((List<String> names) {
      if (!mounted) return;

      setState(() {
        _lanContacts
          ..clear()
          ..addAll(names.map(Contact.fromLanUser));
      });
    });
  }

  void _onInboxChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    ConversationInboxService.instance.removeListener(
      _onInboxChanged,
    );
    _usersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> _filter(List<Contact> source) {
    final String q = _query.trim().toLowerCase();

    if (q.isEmpty) return source;

    return source
        .where(
          (Contact c) => c.name.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // The inbox is the source of truth for online conversations, so a
    // thread with a waiting message still shows up even though it was
    // never opened in this session.
    final List<ConversationInboxEntry> inbox =
        ConversationInboxService.instance.entries;

    final Map<String, Contact> merged = <String, Contact>{};

    for (final Contact c in _lanContacts) {
      merged[c.id] = c;
    }

    for (final ConversationInboxEntry e in inbox) {
      merged['${e.otherId}'] = e.contact;
    }

    for (final Contact c in widget.onlineContacts) {
      merged.putIfAbsent(c.id, () => c);
    }

    final List<Contact> all = merged.values.toList();

    final List<Contact> online = all
        .where((Contact c) => int.tryParse(c.id) != null)
        .toList();

    final List<Contact> lan =
        all.where((Contact c) => int.tryParse(c.id) == null).toList();

    final List<Contact> lanFiltered = _filter(lan);
    final List<Contact> onlineFiltered = _filter(online);

    final bool isEmpty = lanFiltered.isEmpty && onlineFiltered.isEmpty;

    final int totalUnread = ConversationInboxService.instance.totalUnread;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (totalUnread > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NovaSpacing.lg,
              NovaSpacing.lg,
              NovaSpacing.lg,
              0,
            ),
            child: _UnreadBanner(count: totalUnread),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NovaSpacing.lg,
            NovaSpacing.xl,
            NovaSpacing.lg,
            NovaSpacing.md,
          ),
          child: TextField(
            controller: _searchController,
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (String v) =>
                setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search conversations',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
              ),
            ),
          ),
        ),

        Expanded(
          child: isEmpty
              ? const _EmptyChats()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    NovaSpacing.md,
                    0,
                    NovaSpacing.md,
                    NovaSpacing.lg,
                  ),
                  children: <Widget>[
                    if (lanFiltered.isNotEmpty) ...<Widget>[
                      _SectionHeader(
                        label: 'LAN Users',
                        count: lanFiltered.length,
                        icon: Icons.wifi_rounded,
                        accent: NovaColors.textSecondary,
                      ),
                      for (final Contact c in lanFiltered)
                        _ConversationTile(
                          contact: c,
                          selected:
                              widget.selectedContact?.id == c.id,
                          onTap: () =>
                              widget.onConversationSelected(c),
                        ),
                    ],

                    if (lanFiltered.isNotEmpty &&
                        onlineFiltered.isNotEmpty)
                      const SizedBox(
                        height: NovaSpacing.lg,
                      ),

                    if (onlineFiltered.isNotEmpty) ...<Widget>[
                      _SectionHeader(
                        label: 'Online Users',
                        count: onlineFiltered.length,
                        icon: Icons.public_rounded,
                        accent: NovaColors.accent,
                      ),
                      for (final Contact c in onlineFiltered)
                        _ConversationTile(
                          contact: c,
                          selected:
                              widget.selectedContact?.id == c.id,
                          onTap: () =>
                              widget.onConversationSelected(c),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// Surfaces the total waiting-message count above the list, so messages
/// that arrived while the user was away are announced rather than only
/// discoverable by opening each chat.
class _UnreadBanner extends StatelessWidget {
  final int count;

  const _UnreadBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NovaSpacing.md,
        vertical: NovaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: NovaColors.accentMuted,
        borderRadius: BorderRadius.circular(NovaRadius.md),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.mark_chat_unread_rounded,
            size: 17,
            color: NovaColors.accent,
          ),
          const SizedBox(width: NovaSpacing.sm),
          Expanded(
            child: Text(
              count == 1
                  ? '1 unread message'
                  : '$count unread messages',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: NovaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color accent;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NovaSpacing.sm,
        NovaSpacing.md,
        NovaSpacing.sm,
        NovaSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: NovaSpacing.sm),
          Text(
            label.toUpperCase(),
            style: NovaTheme.sectionLabel.copyWith(
              color: accent,
            ),
          ),
          const SizedBox(width: NovaSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: NovaColors.surfaceOverlay,
              borderRadius: BorderRadius.circular(
                NovaRadius.pill,
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NovaColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Contact contact;
  final bool selected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int unread = UnreadService.instance.unreadFor(
      contact.id,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? NovaColors.accentMuted
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(NovaRadius.md),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(NovaRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NovaSpacing.md,
              vertical: NovaSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                _ContactAvatar(contact: contact),

                const SizedBox(
                    width: NovaSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: unread > 0
                                  ? NovaColors.textPrimary
                                  : NovaColors.textSecondary,
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: contact.online
                                  ? NovaColors.online
                                  : NovaColors.textDisabled,
                            ),
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            contact.online
                                ? 'Online'
                                : 'Offline',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (unread > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: NovaColors.accent,
                      borderRadius:
                          BorderRadius.circular(
                        NovaRadius.pill,
                      ),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final Contact contact;

  const _ContactAvatar({required this.contact});

  @override
  Widget build(BuildContext context) {
    final String name = contact.name.trim();
    final String letter = name.isEmpty
        ? '?'
        : name.substring(0, 1).toUpperCase();

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: contact.online
            ? NovaColors.accentMuted
            : NovaColors.surfaceOverlay,
        borderRadius:
            BorderRadius.circular(NovaRadius.md),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NovaColors.textPrimary,
        ),
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NovaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.forum_outlined,
              size: 44,
              color: NovaColors.textDisabled,
            ),
            const SizedBox(height: NovaSpacing.lg),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: NovaSpacing.xs),
            Text(
              'Start one from Online Users or LAN Users.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
