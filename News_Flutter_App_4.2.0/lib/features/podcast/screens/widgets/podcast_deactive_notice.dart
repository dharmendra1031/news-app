// Read-only "Deactive" strip shown at the top of the Create/Edit channel and
// episode forms when the saved row came back with `status == "0"`.
//
// Status is admin-owned — the forms never send it — so this only reports it,
// in the same two reds the deactivated badge on PodcastCard uses (the
// light-theme red is unreadable on a dark card).

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/theme/theme_colors.dart';

/// The red used by every deactivated marker. The light-theme red is unreadable
/// on a dark card, so the two themes take the two reds the "Deactivated" news
/// badge already uses.
Color _deactiveRed(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? darkIconColor : iconColor;

/// Compact "Deactive" pill for a list row — the channel card and the episode
/// tile both mark a deactivated row with this.
class PodcastDeactiveBadge extends StatelessWidget {
  const PodcastDeactiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final Color red = _deactiveRed(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomTextLabel(
          text: 'deactiveLbl',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 16 / 11,
            letterSpacing: 0.5,
            color: red,
          )),
    );
  }
}

class PodcastDeactiveNotice extends StatelessWidget {
  const PodcastDeactiveNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final Color red = _deactiveRed(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: red),
          const SizedBox(width: 8),
          Expanded(
            child: CustomTextLabel(
                text: 'deactiveLbl',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 18 / 13,
                  letterSpacing: 0.5,
                  color: red,
                )),
          ),
        ],
      ),
    );
  }
}
