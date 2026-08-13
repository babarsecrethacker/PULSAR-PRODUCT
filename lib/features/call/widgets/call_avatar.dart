import 'package:flutter/material.dart';

class CallAvatar extends StatelessWidget {
  final Animation<double> animation;

  const CallAvatar({
    super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(

      animation: animation,

      builder: (context, child) {

        final glow =
            25 + (animation.value * 35);

        return Container(

          decoration: BoxDecoration(

            shape: BoxShape.circle,

            boxShadow: [

              BoxShadow(

                color: const Color(
                  0xff6E6EFF,
                ).withOpacity(.7),

                blurRadius: glow,

                spreadRadius: 8,

              ),

            ],

          ),

          child: const CircleAvatar(

            radius: 70,

            backgroundColor:
                Color(0xff232D59),

            child: Icon(

              Icons.person,

              size: 70,

              color: Colors.white,

            ),

          ),

        );

      },

    );

  }

}