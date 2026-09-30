import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/websocket_service.dart';
import '../../../core/theme/nova_theme.dart';
import '../../contacts/models/contact.dart';

/// LAN directory.
///
/// This page lists discovered local-network users and nothing else. It
/// deliberately shows no message preview or conversation state: opening
/// someone hands off to the chat view rather than expanding a thread
/// inline, so a directory and a conversation can never be confused for
/// one another.
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

  final TextEditingController _searchController =
      TextEditingController();

  StreamSubscription<List<String>>? usersSubscription;

  String _query = '';

  @override
  void initState() {
    super.initState();

    users.addAll(
      WebSocketService()
          .cachedUsers
          .map((String name) => Contact.fromLanUser(name)),
    );

    usersSubscription =
        WebSocketService().users.listen((List<String> lanUsers) {
      if (!mounted) return;

      setState(() {
        users
          ..clear()
          ..addAll(lanUsers.map(Contact.fromLanUser));
      });
    });
  }

  @override
  void dispose() {
    usersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> get _visibleUsers {
    final String q = _query.trim().toLowerCase();

    if (q.isEmpty) return users;

    return users
        .where(
          (Contact c) => c.name.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Contact> visible = _visibleUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NovaSpacing.xl,
            NovaSpacing.xl,
            NovaSpacing.xl,
            NovaSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'LAN Users',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(
                height: NovaSpacing.xs,
              ),
              Text(
                'People discovered on your local network.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            NovaSpacing.xl,
            NovaSpacing.lg,
            NovaSpacing.xl,
            NovaSpacing.md,
          ),
          child: TextField(
            controller: _searchController,
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (String v) =>
                setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search LAN users',
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
              ),
            ),
          ),
        ),

        Expanded(
          child: visible.isEmpty
              ? _LanEmptyState(
                  hasQuery: _query.trim().isNotEmpty,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NovaSpacing.xl,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Contact user = visible[index];

                    final bool selected =
                        widget.selectedUser?.id == user.id;

                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: NovaSpacing.sm,
                      ),
                      child: Material(
                        color: selected
                            ? NovaColors.accentMuted
                            : NovaColors.surfaceRaised,
                        borderRadius:
                            BorderRadius.circular(
                          NovaRadius.md,
                        ),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(
                            NovaRadius.md,
                          ),
                          onTap: () => widget.onUserSelected(
                            user,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: NovaSpacing.lg,
                              vertical: NovaSpacing.md,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment:
                                      Alignment.center,
                                  decoration:
                                      BoxDecoration(
                                    color: NovaColors
                                        .surfaceOverlay,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      NovaRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    user.name
                                            .substring(
                                              0,
                                              1,
                                            )
                                            .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: NovaColors
                                          .textPrimary,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      NovaSpacing.md,
                                ),

                                Expanded(
                                  child: Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme
                                        .titleMedium,
                                  ),
                                ),

                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        NovaColors.online,
                                    shape: BoxShape
                                        .circle,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      NovaSpacing.sm,
                                ),

                                Text(
                                  'Online',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall,
                                ),

                                const SizedBox(
                                  width:
                                      NovaSpacing.sm,
                                ),

                                const Icon(
                                  Icons
                                      .chevron_right_rounded,
                                  size: 18,
                                  color: NovaColors
                                      .textDisabled,
                                ),
                              ],
                            ),
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

class _LanEmptyState extends StatelessWidget {
  final bool hasQuery;

  const _LanEmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NovaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              hasQuery
                  ? Icons.person_search_rounded
                  : Icons.wifi_off_rounded,
              size: 44,
              color: NovaColors.textDisabled,
            ),
            const SizedBox(height: NovaSpacing.lg),
            Text(
              hasQuery
                  ? 'No matching LAN users'
                  : 'No LAN users online',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: NovaSpacing.xs),
            Text(
              hasQuery
                  ? 'Try a different name.'
                  : 'Start Pulsar Chat on another device '
                      'on this network and it will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
