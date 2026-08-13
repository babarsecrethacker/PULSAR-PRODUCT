import 'package:flutter/material.dart';

class CallStatus extends StatelessWidget {

  final String status;

  const CallStatus({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),

      decoration: BoxDecoration(

        color: Colors.white.withOpacity(.06),

        borderRadius:
            BorderRadius.circular(30),

      ),

      child: Text(

        status,

        style: const TextStyle(

          color: Colors.white70,

          fontSize: 18,

          letterSpacing: 1,

        ),

      ),

    );

  }

}