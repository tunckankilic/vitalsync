/// VitalSync — Health Module: delete confirmation.
///
/// Shared by the glucose and meal lists, which both delete by swipe.
library;

import 'package:flutter/material.dart';

/// Asks the user to confirm a destructive swipe.
///
/// Returns false when the dialog is dismissed without a choice, so an
/// accidental swipe never removes anything.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
