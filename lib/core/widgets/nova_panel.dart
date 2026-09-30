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
        // Reads from the active theme so the panel follows whichever
        // family is selected.
        color: Theme.of(context).colorScheme.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),

      child: child,
    );
  }
}