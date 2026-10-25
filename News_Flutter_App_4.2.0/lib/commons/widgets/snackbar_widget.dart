import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';

showSnackBar(String msg, BuildContext context, {int? durationInMiliSeconds}) {
  try {
    // Check if the context is still valid before showing snackbar
    // Use a try-catch around ScaffoldMessenger.of() as it throws when context is disposed
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Get theme and color scheme safely
    final theme = Theme.of(context);
    final colorScheme = UiUtils.getColorScheme(context);

    // A tapped action should never queue up behind the previous message.
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // Centred text in a flat pill reads as a button; a wide bar that sits
        // off the screen edges with a shadow under it reads as a snackbar.
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: CustomTextLabel(
            text: msg,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textStyle: TextStyle(
              color: theme.colorScheme.surface,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              letterSpacing: 0.1018,
            )),
        showCloseIcon: false,
        duration: Duration(
            milliseconds: durationInMiliSeconds ?? 1500), //bydefault 4000 ms
        backgroundColor: colorScheme.primaryContainer,
        elevation: 6.0,
      ),
    );
  } catch (e) {
    // Silently handle errors if context is no longer valid or widget is disposed
    // This prevents "Looking up a deactivated widget's ancestor is unsafe" errors
    // Don't log the error to avoid cluttering logs with expected errors
  }
}
