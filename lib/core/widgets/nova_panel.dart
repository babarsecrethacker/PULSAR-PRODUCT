import 'package:flutter/material.dart';

class NovaPanel extends StatelessWidget {
  final Widget child;
  final double? width;

  const NovaPanel({
    super.key,
    required this.child,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF171717),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: const Color(0xFF2B2B2B),
          width: 1,
        ),
      ),

      child: child,
    );
  }
}