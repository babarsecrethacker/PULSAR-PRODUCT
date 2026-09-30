import 'package:flutter/material.dart';

import '../models/sidebar_page.dart';

class NovaSidebar extends StatefulWidget {
  final String username;
  final Future<void> Function() onSwitchMode;
  final SidebarPage selectedPage;
  final ValueChanged<SidebarPage> onPageSelected;
  final int unreadCount;

  const NovaSidebar({
    super.key,
    required this.username,
    required this.onSwitchMode,
    required this.selectedPage,
    required this.onPageSelected,
    this.unreadCount = 0,
  });

  @override
  State<NovaSidebar> createState() => _NovaSidebarState();
}

class _NovaSidebarState extends State<NovaSidebar> {
  bool expanded = false;

  static const double _collapsedWidth = 58;
  static const double _expandedWidth = 190;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => expanded = true),
      onExit: (_) => setState(() => expanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: expanded ? _expandedWidth : _collapsedWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        // The rail is height-constrained by the window, so item sizing
        // adapts instead of overflowing on short windows.
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final bool tight = c.maxHeight < 560;

            final double itemHeight = tight ? 38 : 48;
            final double itemVPad = tight ? 2 : 4;

            return Column(
              children: <Widget>[
                SizedBox(height: tight ? 6 : 10),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: expanded ? 18 : 8,
                  ),
                  child: Row(
                    mainAxisAlignment: expanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.forum_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: expanded ? 28 : 22,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: tight ? 4 : 10),

                // Scrollable so a short window can never overflow the
                // rail, however many destinations are added later.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        _item(
                          page: SidebarPage.onlineUsers,
                          icon: Icons.public_rounded,
                          title: 'Online Users',
                          height: itemHeight,
                          vPad: itemVPad,
                        ),
                        _item(
                          page: SidebarPage.lanUsers,
                          icon: Icons.wifi_rounded,
                          title: 'LAN Users',
                          height: itemHeight,
                          vPad: itemVPad,
                        ),
                        _item(
                          page: SidebarPage.chats,
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Chats',
                          badge: widget.unreadCount,
                          height: itemHeight,
                          vPad: itemVPad,
                        ),
                        _item(
                          page: SidebarPage.contacts,
                          icon: Icons.people_outline_rounded,
                          title: 'Contacts',
                          height: itemHeight,
                          vPad: itemVPad,
                        ),
                        _item(
                          page: SidebarPage.calls,
                          icon: Icons.call_outlined,
                          title: 'Calls',
                          height: itemHeight,
                          vPad: itemVPad,
                        ),
                        _item(
                          page: SidebarPage.files,
                          icon: Icons.folder_outlined,
                          title: 'Files',
                          height: itemHeight,
                          vPad: itemVPad,
                        ),
                      ],
                    ),
                  ),
                ),

                _item(
                  page: SidebarPage.settings,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  height: itemHeight,
                  vPad: itemVPad,
                ),

                SizedBox(height: tight ? 4 : 8),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 40,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: expanded
                            ? Row(
                                children: <Widget>[
                                  const SizedBox(width: 10),
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.username,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.color,
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              )
                            : Center(
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      Theme.of(context)
                                          .colorScheme
                                          .primary,
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                ),
                              ),
                      ),

                      if (expanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: widget.onSwitchMode,
                              icon: const Icon(
                                Icons.swap_horiz_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Switch mode',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Colors.white70,
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                visualDensity:
                                    VisualDensity.compact,
                                tapTargetSize:
                                    MaterialTapTargetSize
                                        .shrinkWrap,
                                side: const BorderSide(
                                  color: Color(0xFF303030),
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _item({
    required SidebarPage page,
    required IconData icon,
    required String title,
    double height = 48,
    double vPad = 4,
    int badge = 0,
  }) {
    final bool selected = widget.selectedPage == page;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: vPad,
      ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => widget.onPageSelected(page),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: height,
            // The collapsed rail is only 38px of usable width, so it
            // must not spend any of it on padding.
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.outlineVariant
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: expanded ? 22 : 20,
                  child: Icon(
                    icon,
                    size: 19,
                    color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

              // A plain spacer rather than an animated fixed-width box:
              // a hard width here is what overflowed the row when the
              // rail expanded.
              SizedBox(width: expanded ? 8 : 0),

              // The label is flexible and ellipsised, so it can never
              // demand more width than the rail actually has.
              Expanded(
                child: ClipRect(
                  child: AnimatedOpacity(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    opacity: expanded ? 1 : 0,
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // A real unread count has to be visible in both states,
              // so show a dot while collapsed.
              if (badge > 0)
                expanded
                    ? Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        constraints:
                            const BoxConstraints(
                          maxWidth: 40,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5484D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Container(
                        // A slim spacer, not Padding, so the collapsed
                        // rail stays inside its 38px.
                        margin: const EdgeInsets.only(left: 2),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5484D),
                          shape: BoxShape.circle,
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
