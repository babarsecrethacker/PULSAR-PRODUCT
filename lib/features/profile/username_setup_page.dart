import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsernameSetupPage extends StatefulWidget {
  final Function(String username) onComplete;

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

  widget.onComplete(username);
}



  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xff050510),

      body: Center(

        child: Container(

          width: 380,

          padding:
              const EdgeInsets.all(30),


          decoration: BoxDecoration(

            color:
                Colors.white.withOpacity(.06),

            borderRadius:
                BorderRadius.circular(25),

            border: Border.all(
              color:
                  Colors.white12,
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


              const Text(
                "Welcome to PULSAR CHAT",
                style:
                    TextStyle(
                  color:
                      Colors.white,
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
                      Colors.white60,
                ),
              ),


              const SizedBox(height:25),


              TextField(

                controller:
                    controller,


                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),


                decoration:
                    InputDecoration(

                  hintText:
                      "Example: Babar",

                  hintStyle:
                      const TextStyle(
                    color:
                        Colors.white38,
                  ),


                  filled:
                      true,


                  fillColor:
                      Colors.white10,


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
                        const Color(0xff6C63FF),

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
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                ),

              )

            ],

          ),

        ),

      ),

    );
  }
}