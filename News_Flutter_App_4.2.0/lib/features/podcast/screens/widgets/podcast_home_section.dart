// The "Podcast" block on the home screen. Hides itself when there is nothing to
// show; "View More" opens PodcastDashboardScreen.

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/podcast/screens/widgets/podcast_card.dart';
import 'package:news/utils/ui_utils.dart';

class PodcastHomeSection extends StatelessWidget {
  final String title;
  final List<PodcastCardData> podcasts;
  final VoidCallback? onViewMoreTap;
  final void Function(PodcastCardData podcast)? onPodcastTap;

  const PodcastHomeSection({
    super.key,
    required this.title,
    required this.podcasts,
    this.onViewMoreTap,
    this.onPodcastTap,
  });

  @override
  Widget build(BuildContext context) {
    if (podcasts.isEmpty) return const SizedBox.shrink();

    final colorScheme = UiUtils.getColorScheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 28 / 20,
                    color: colorScheme.primaryContainer,
                  )),
            ),
            GestureDetector(
              onTap: onViewMoreTap,
              child: const CustomTextLabel(
                  text: 'viewMore',
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    color: textSecondaryColor,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < podcasts.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PodcastCard(
              data: podcasts[i],
              imageSize: 122,
              homeStyle: true,
              onTap: onPodcastTap == null
                  ? null
                  : () => onPodcastTap!(podcasts[i])),
        ],
      ],
    );
  }
}
