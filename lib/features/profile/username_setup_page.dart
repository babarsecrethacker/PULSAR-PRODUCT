import 'package:flutter/material.dart';

import '../../../core/theme/nova_theme.dart';
import '../../../core/widgets/nova_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsernameSetupPage extends StatefulWidget {
  final Future<void> Function(String username) onComplete;

  const UsernameSetupPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<UsernameSetupPage> createState() =>
      _UsernameSetupPageState();
}


class _UsernameSetupPageState
    extends State<UsernameSetupPage> {

  final controller = TextEditingController();

  bool loading = false;


  Future<void> saveUsername() async {
    final username = controller.text.trim();

    if (username.isEmpty) return;

    setState(() {
      loading = true;
    });

    try {
      await widget.onComplete(username);
    } catch (e) {
      // The page used to be left stuck on "connecting" forever because
      // loading was set and never reset when this threw.
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 6),
              content: Text(
                'Could not join: $e',
                style: const TextStyle(color: Color(0xFFEDF1FF)),
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {

    return NovaScreen(
      dense: true,
      child: Center(
        child: SingleChildScrollView(
          // A fixed 380px card plus 30px of padding on each side needs
          // 440px, so anything narrower had to scroll.
          padding: const EdgeInsets.all(16),
          child: Container(
            // Flexible rather than fixed: the card now shrinks with the
            // window instead of overflowing it.
            width: 380,
            constraints: const BoxConstraints(maxWidth: 440),

          padding:
              const EdgeInsets.all(30),


          decoration: BoxDecoration(

            color:
                NovaColors.surfaceRaised,

            borderRadius:
                BorderRadius.circular(25),

            border: Border.all(
              color:
                  NovaColors.border,
            ),

          ),


          child: Column(

            mainAxisSize:
                MainAxisSize.min,


            children: [


              const Icon(
                Icons.bubble_chart,
                size: 60,
                color:
                    Color(0xff7C4DFF),
              ),


              const SizedBox(height:20),


              Text(
                "Welcome to PULSAR CHAT",
                style:
                    TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                  fontSize:
                      26,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),


              const SizedBox(height:10),


              const Text(
                "Choose your LAN name",
                style:
                    TextStyle(
                  color:
                      NovaColors.textSecondary,
                ),
              ),


              const SizedBox(height:25),


              TextField(

                controller:
                    controller,


                style:
                    TextStyle(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .onSurface,
                ),


                decoration:
                    InputDecoration(

                  hintText:
                      "Example: Babar",

                  hintStyle:
                      TextStyle(
                    color:
                        NovaColors.textTertiary,
                  ),


                  filled:
                      true,


                  fillColor:
                      NovaColors.border,


                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        BorderSide.none,

                  ),

                ),

              ),


              const SizedBox(height:20),


              SizedBox(

                width:
                    double.infinity,


                child:
                    ElevatedButton(

                  onPressed:
                      loading
                          ? null
                          : saveUsername,


                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        NovaColors.accent,

                    padding:
                        const EdgeInsets.all(16),

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(18),

                    ),

                  ),


                  child:
                      const Text(
                    "CONNECT",
                  ),

                ),

              )

            ],

          ),

          ),

        ),

      ),

    );
  }
}