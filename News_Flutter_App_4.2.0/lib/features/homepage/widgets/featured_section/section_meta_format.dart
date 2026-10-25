import 'package:flutter/material.dart';
import 'package:news/utils/ui_utils.dart';

/// Compact count e.g. 1000 -> "1K", 1_200_000 -> "1.2M". Matches the Figma
/// "1K read" label.
String compactCount(int n) {
  if (n >= 1000000) {
    return "${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M";
  }
  if (n >= 1000) {
    return "${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K";
  }
  return "$n";
}

/// Relative time e.g. "4 minutes ago", "2 days ago". Unlike
/// `UiUtils.convertToAgo(from: 0)`, which switches to an absolute date after a
/// day, this always stays relative, as the Figma "4 min ago" label does. A time
/// in the future (clock/timezone skew) reads "just now".
String relativeTime(BuildContext context, DateTime input) {
  final Duration diff = DateTime.now().difference(input);
  String ago(int count, String unitKey) =>
      "$count ${UiUtils.getTranslatedLabel(context, unitKey)} ${UiUtils.getTranslatedLabel(context, 'ago')}";

  if (diff.inMinutes < 1) return UiUtils.getTranslatedLabel(context, 'justNow');
  if (diff.inHours < 1) return ago(diff.inMinutes, 'minutes');
  if (diff.inDays < 1) return ago(diff.inHours, 'hours');
  if (diff.inDays < 30) return ago(diff.inDays, 'days');
  if (diff.inDays < 365) return ago(diff.inDays ~/ 30, 'months');
  return ago(diff.inDays ~/ 365, 'years');
}
