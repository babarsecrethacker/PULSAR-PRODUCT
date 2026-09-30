import 'package:flutter/material.dart';

import '../models/sidebar_page.dart';
import '../theme/nova_theme.dart';

/// Navigation drawer for narrow screens (phones).
///
/// The desktop rail expands on hover, which is meaningless on touch, so
/// mobile gets a conventional drawer instead: a menu button in the top
/// left that reveals every destination, leaving the rest of the screen
/// for the conversation.
class NovaDrawer extends StatelessWidget {
  final String username;
  final SidebarPage selectedPage;
  final ValueChanged<SidebarPage> onPageSelected;
  final Future<void> Function() onSwitchMode;

  const NovaDrawer({
    super.key,
    required this.username,
    required this.selectedPage,
    required this.onPageSelected,
    required this.onSwitchMode,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(
                NovaSpacing.lg,
                NovaSpacing.xl,
                NovaSpacing.lg,
                NovaSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: scheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(
                        NovaRadius.md,
                      ),
                    ),
                    child: const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: NovaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Pulsar Chat',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Destinations
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: NovaSpacing.sm,
                ),
                children: <Widget>[
                  _item(
                      context,
                      page: SidebarPage.onlineUsers,
                    icon: Icons.public_rounded,
                    label: 'Online Users',
                  ),
                  _item(
                      context,
                      page: SidebarPage.lanUsers,
                    icon: Icons.wifi_rounded,
                    label: 'LAN Users',
                  ),
                  _item(
                      context,
                      page: SidebarPage.chats,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chats',
                  ),
                  const _SectionGap(),
                  _item(
                      context,
                      page: SidebarPage.contacts,
                    icon: Icons.people_outline_rounded,
                    label: 'Contacts',
                  ),
                  _item(
                      context,
                      page: SidebarPage.calls,
                    icon: Icons.call_outlined,
                    label: 'Calls',
                  ),
                  _item(
                      context,
                      page: SidebarPage.files,
                    icon: Icons.folder_outlined,
                    label: 'Files',
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(NovaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _item(
                      context,
                      page: SidebarPage.settings,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                  ),
                  const SizedBox(height: NovaSpacing.sm),
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSwitchMode();
                      },
                      icon: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 18,
                      ),
                      label: const Text('Switch mode'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        side: BorderSide(
                          color: scheme.outline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            NovaRadius.md,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required SidebarPage page,
    required IconData icon,
    required String label,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool selected = selectedPage == page;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NovaSpacing.md,
        vertical: 2,
      ),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(NovaRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(NovaRadius.md),
          onTap: () {
            Navigator.of(context).pop();
            onPageSelected(page);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NovaSpacing.md,
              vertical: 12,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: NovaSpacing.lg),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: selected
                          ? scheme.primary
                          : scheme.onSurface,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500,
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

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NovaSpacing.lg,
        vertical: NovaSpacing.sm,
      ),
      child: Divider(
        height: 1,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant,
      ),
    );
  }
}

/// Top bar for narrow screens: menu button on the left, title, and the
/// unread count on the right.
///
/// This is a plain Container rather than an [AppBar]. On a phone the
/// header lives inside a Column, not in a Scaffold's `appBar` slot, and
/// an AppBar placed there does not render reliably - the screen came up
/// blank.
class NovaMobileBar extends StatelessWidget {
  final String title;
  final int unreadCount;
  final VoidCallback onMenuPressed;
  final VoidCallback? onSearch;

  const NovaMobileBar({
    super.key,
    required this.title,
    required this.onMenuPressed,
    this.unreadCount = 0,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
          ),
          if (unreadCount > 0) ...<Widget>[
            Container(
              margin: const EdgeInsets.only(right: NovaSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              constraints: const BoxConstraints(maxWidth: 52),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(
                  NovaRadius.pill,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          if (onSearch != null)
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
            ),
          const SizedBox(width: NovaSpacing.xs),
        ],
      ),
    );
  }
}
