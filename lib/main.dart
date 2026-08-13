import 'package:flutter/material.dart';

import 'core/services/websocket_service.dart';
import 'core/widgets/animated_space_background.dart';
import 'features/home/pages/home_shell.dart';
import 'features/profile/username_setup_page.dart';

import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();



  runApp(const NovaApp());
}

class NovaApp extends StatefulWidget {
  const NovaApp({super.key});

  @override
  State<NovaApp> createState() => _NovaAppState();
}

class _NovaAppState extends State<NovaApp> {
  String? username;

  @override
  void initState() {
    super.initState();
  }

  void connect(String name) {
    print("===== CONNECT CALLED =====");
    print("Username: $name");

    WebSocketService().connect(
      username: name,
    );
  }

  void completeSetup(String name) {
    connect(name);

    setState(() {
      username = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "PULSAR CHAT",

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),

      home: AnimatedSpaceBackground(
        child: username == null
            ? UsernameSetupPage(
                onComplete: completeSetup,
              )
            : const HomeShell(),
      ),
    );
  }
}