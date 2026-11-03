import 'package:flutter/material.dart';

/// A small tracked-caps label, like the printed legends on an inspection
/// tag ("LOCATION", "LAST SERVICED"). Used for field names and section
/// titles; the value goes below it in normal weight.
class Legend extends StatelessWidget {
  const Legend(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
