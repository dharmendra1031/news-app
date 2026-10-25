// Publish-date dialog shared by the Create channel and Create episode forms —
// the same rounded, brand-tinted date picker in both places.

import 'package:flutter/material.dart';
import 'package:news/utils/ui_utils.dart';

Future<DateTime?> showPodcastPublishDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: const DialogThemeData(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
          colorScheme: ColorScheme.fromSeed(
              seedColor: UiUtils.getColorScheme(context).primary,
              brightness: Theme.of(context).brightness,
              primary: UiUtils.getColorScheme(context).secondaryContainer),
        ),
        child: child!,
      );
    },
  );
}
