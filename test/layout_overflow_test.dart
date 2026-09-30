import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulsar_chat/core/models/sidebar_page.dart';
import 'package:pulsar_chat/core/theme/nova_theme.dart';
import 'package:pulsar_chat/core/widgets/nova_drawer.dart';
import 'package:pulsar_chat/core/widgets/nova_sidebar.dart';
import 'package:pulsar_chat/features/profile/username_setup_page.dart';
import 'package:pulsar_chat/features/online/pages/connection_mode_page.dart';
import 'package:pulsar_chat/features/online/pages/online_login_page.dart';
import 'package:pulsar_chat/features/contacts/pages/contacts_page.dart';
import 'package:pulsar_chat/features/lan/pages/lan_users_page.dart';
import 'package:pulsar_chat/features/chat/pages/chats_page.dart';
import 'package:pulsar_chat/features/contacts/models/contact.dart';
import 'package:pulsar_chat/features/settings/pages/settings_page.dart';

/// Renders widgets at hostile sizes and fails if any of them overflow.
///
/// Flutter reports a layout overflow as a FlutterError, so
/// [tester.takeException] is the reliable signal - asserting on painted
/// pixels would not catch it.
Widget _host(Widget child) {
  return MaterialApp(
    theme: NovaTheme.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // Sizes a user can realistically reach by resizing the window.
  const List<Size> sizes = <Size>[
    Size(1024, 680),
    Size(900, 500),
    Size(700, 420),
    Size(420, 380),
  ];

  group('NovaSidebar', () {
    for (final Size size in sizes) {
      testWidgets('does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            NovaSidebar(
              username: 'Babar YouTube',
              onSwitchMode: () async {},
              selectedPage: SidebarPage.chats,
              unreadCount: 12,
              onPageSelected: (SidebarPage _) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.takeException(),
          isNull,
          reason: 'sidebar overflowed at $size',
        );
      });
    }
  });

  group('UsernameSetupPage', () {
    for (final Size size in sizes) {
      testWidgets('does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            UsernameSetupPage(
              onComplete: (String _) async {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.takeException(),
          isNull,
          reason: 'username setup overflowed at $size',
        );
      });
    }
  });

  group('ConnectionModePage', () {
    for (final Size size in sizes) {
      testWidgets('does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            ConnectionModePage(
              onLanSelected: () {},
              onOnlineSelected: () {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.takeException(),
          isNull,
          reason: 'connection mode overflowed at $size',
        );
      });
    }
  });

  group('OnlineLoginPage', () {
    for (final Size size in sizes) {
      testWidgets('does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(const OnlineLoginPage()),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          tester.takeException(),
          isNull,
          reason: 'login overflowed at $size',
        );
      });
    }
  });

  group('List screens', () {
    for (final Size size in sizes) {
      testWidgets('LAN page does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            LanUsersPage(
              selectedUser: null,
              onUserSelected: (Contact _) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'lan page overflowed at $size',
        );
      });

      testWidgets('Chats page does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            ChatsPage(
              selectedContact: null,
              onlineContacts: const <Contact>[],
              onConversationSelected: (Contact _) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'chats page overflowed at $size',
        );
      });

      testWidgets('Contacts page does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _host(
            ContactsPage(
              selectedContact: null,
              onContactSelected: (Contact _) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'contacts page overflowed at $size',
        );
      });
    }
  });

  group('Mobile drawer', () {
    for (final NovaThemeFamily family in NovaThemeFamily.values) {
      testWidgets('does not overflow on a phone in $family', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: NovaTheme.build(family: family),
            home: Scaffold(
              drawer: NovaDrawer(
                username: 'Babar YouTube',
                selectedPage: SidebarPage.chats,
                onPageSelected: (SidebarPage _) {},
                onSwitchMode: () async {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'drawer overflowed in $family',
        );
      });
    }
  });

  group('Settings page', () {
    for (final Size size in sizes) {
      testWidgets('does not overflow at $size', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(const SettingsPage()));
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.takeException(),
          isNull,
          reason: 'settings overflowed at $size',
        );
      });
    }
  });
}
