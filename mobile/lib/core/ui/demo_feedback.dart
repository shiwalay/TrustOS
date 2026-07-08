import 'package:flutter/material.dart';

/// Consistent, contextual feedback for demo actions that don't yet have a
/// full backend destination — so every tap does something and the app never
/// feels dead. Production replaces these with real flows.
void showDemoSnack(BuildContext context, String message, {IconData? icon}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon ?? Icons.check_circle_outline,
                size: 18, color: theme.colorScheme.onInverseSurface),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
