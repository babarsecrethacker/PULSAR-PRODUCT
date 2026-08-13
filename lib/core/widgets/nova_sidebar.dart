import 'package:flutter/material.dart';
import '../models/sidebar_page.dart';

class NovaSidebar extends StatefulWidget {
  final SidebarPage selectedPage;
  final ValueChanged<SidebarPage> onPageSelected;

  const NovaSidebar({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
  });

  @override
  State<NovaSidebar> createState() => _NovaSidebarState();
}

class _NovaSidebarState extends State<NovaSidebar> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => expanded = true),
      onExit: (_) => setState(() => expanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: expanded ? 190 : 58,
        decoration: BoxDecoration(
  color: const Color(0xFF171717),
  borderRadius: BorderRadius.circular(18),
  border: Border.all(
    color: const Color(0xFF2B2B2B),
  ),
),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Padding(
  padding: EdgeInsets.symmetric(
    horizontal: expanded ? 18 : 8,
  ),
  child: Row(
  mainAxisAlignment: expanded
      ? MainAxisAlignment.start
      : MainAxisAlignment.center,
  children: [
    Icon(
      Icons.forum_rounded,
      color: Colors.white,
      size: expanded ? 28 : 22,
    ),
  ],
),
            ),

            const SizedBox(height: 10),

            _item(
              page: SidebarPage.lanUsers,
              icon: Icons.wifi_rounded,
              title: "LAN Users",
            ),

            _item(
              page: SidebarPage.chats,
              icon: Icons.chat_bubble_outline_rounded,
              title: "Chats",
              badge: 3,
            ),

            _item(
              page: SidebarPage.contacts,
              icon: Icons.people_outline_rounded,
              title: "Contacts",
            ),

            _item(
              page: SidebarPage.calls,
              icon: Icons.call_outlined,
              title: "Calls",
            ),

            _item(
              page: SidebarPage.files,
              icon: Icons.folder_outlined,
              title: "Files",
            ),

            const Flexible(
  child: SizedBox(),
),

            _item(
              page: SidebarPage.settings,
              icon: Icons.settings_outlined,
              title: "Settings",
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: expanded
    ? Row(
        children: [
          const SizedBox(width: 10),

          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF3B82F6),
            child: Icon(
              Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Babar",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    : const Center(
        child: CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFF3B82F6),
          child: Icon(
            Icons.person,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

    Widget _item({
    required SidebarPage page,
    required IconData icon,
    required String title,
    int badge = 0,
  }) {
    final bool selected = widget.selectedPage == page;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          widget.onPageSelected(page);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 48,
          decoration: BoxDecoration(
            color: selected
    ? const Color(0xFF2B2B2B)
    : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),

              Icon(
  icon,
  size: 20,
  color: selected
      ? Colors.white
      : Colors.white70,
),

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: expanded ? 16 : 0,
              ),

              Expanded(
                child: ClipRect(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: expanded ? 1 : 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: expanded ? 120 : 0,
                      child: Text(
                        title,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (expanded && badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: expanded ? 12 : 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}