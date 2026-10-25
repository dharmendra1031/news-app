// The one channel row: cover, title and the listener / episode counts. 65px on the
// home section, 93px in the dashboard and the author's list.

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/podcast/screens/widgets/podcast_deactive_notice.dart';
import 'package:news/utils/ui_utils.dart';

class PodcastCardData {
  final String? id;
  final String? slug;
  final String imageUrl;
  final String title;
  final String? description;

  final String listenersCount;

  final String episodesCount;

  final String authorName;
  final String authorImageUrl;
  final bool isFollowed;

  /// `status == "1"` on the API. Only the author's own list ever carries a
  /// deactivated channel — the public lists never return one — so this stays
  /// true everywhere else.
  final bool isActive;

  const PodcastCardData({
    this.id,
    this.slug,
    required this.imageUrl,
    required this.title,
    this.description,
    required this.listenersCount,
    required this.episodesCount,
    this.authorName = '',
    this.authorImageUrl = '',
    this.isFollowed = false,
    this.isActive = true,
  });
}

class PodcastCard extends StatelessWidget {
  final PodcastCardData data;
  final VoidCallback? onTap;

  final double imageSize;

  final Widget? trailing;

  /// Switches to the home section's Figma card look — single-line 14px
  /// title, a description line, and a divider before the stats row —
  /// instead of the legacy dashboard/author-list row look.
  final bool homeStyle;

  const PodcastCard(
      {super.key,
      required this.data,
      this.onTap,
      this.imageSize = 65,
      this.trailing,
      this.homeStyle = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final description = data.description?.trim() ?? '';
    // A deactivated channel has no detail page to open — the badge is the only
    // thing the row does.
    return GestureDetector(
      onTap: data.isActive ? onTap : null,
      child: Container(
        padding: EdgeInsets.all(homeStyle ? 6 : 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: homeStyle
                  ? (isDark ? darkBorderDefaultColor : borderDefaultColor)
                  : colorScheme.primaryContainer.withOpacity(0.1),
              width: homeStyle ? 1.0 : 0.678),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(homeStyle ? 4 : 6),
              child: CustomNetworkImage(
                  networkImageUrl: data.imageUrl,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title,
                      maxLines: homeStyle ? 1 : 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: homeStyle
                          ? TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.55,
                              letterSpacing: -0.28,
                              color: colorScheme.primaryContainer,
                            )
                          : TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 22.3 / 16,
                              letterSpacing: 0.1018,
                              color: colorScheme.primaryContainer,
                            )),
                  if (homeStyle && description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                          color: textSecondaryColor,
                        )),
                  ],
                  SizedBox(height: homeStyle ? 8 : 4),
                  if (homeStyle) ...[
                    Divider(
                        height: 1.0,
                        color:
                            isDark ? darkBorderDefaultColor : borderDefaultColor),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      _stat(context, 'podcast_listeners', data.listenersCount),
                      const SizedBox(width: 8),
                      _stat(context, 'podcast_episodes', data.episodesCount),
                    ],
                  ),
                  if (!data.isActive) ...[
                    const SizedBox(height: 6),
                    const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: PodcastDeactiveBadge()),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String iconName, String value) {
    final colorScheme = UiUtils.getColorScheme(context);
    final color = homeStyle
        ? textSecondaryColor
        : colorScheme.primaryContainer.withOpacity(0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPictureWidget(
            assetName: iconName,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(color, BlendMode.srcIn)),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
              fontSize: homeStyle ? 12 : 11,
              fontWeight: homeStyle ? FontWeight.w400 : FontWeight.w500,
              height: homeStyle ? 16 / 12 : 16 / 11,
              letterSpacing: homeStyle ? 0 : 0.5,
              color: color,
            )),
      ],
    );
  }
}
