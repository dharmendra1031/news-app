import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

/// The view count of a video, or null when there is nothing worth showing:
/// missing, blank, "null", non-numeric or zero. Callers hide the views UI on
/// null so a video nobody has watched yet does not read "0".
int? parseVideoViews(String? raw) {
  final int? count = int.tryParse(raw?.trim() ?? '');
  return (count != null && count > 0) ? count : null;
}

/// Small calendar/eye icon + label, used for the date and views meta row.
class _MetaItem extends StatelessWidget {
  final String assetName;
  final String label;
  final Color color;

  const _MetaItem(
      {required this.assetName, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPictureWidget(
            assetName: assetName,
            height: 16.0,
            width: 16.0,
            assetColor: ColorFilter.mode(color, BlendMode.srcIn)),
        const SizedBox(width: 4.0),
        CustomTextLabel(
          text: label,
          textStyle: TextStyle(
              fontSize: 12.0,
              height: 16 / 12,
              fontWeight: FontWeight.w400,
              color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Calendar + eye row shared by the video list card and the recent-video cards
/// on the video details screen: 16px icons, 4px to the label, 8px between the
/// two items, 12/16 Text/Tertiary. Renders nothing when both are empty.
class VideoMetaRow extends StatelessWidget {
  final String? timeAgo;
  final String? views;

  const VideoMetaRow({super.key, this.timeAgo, this.views});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color metaColor = isDark ? textSecondaryColor : textTertiaryColor;
    final bool hasTimeAgo = timeAgo != null && timeAgo!.isNotEmpty;
    final bool hasViews = parseVideoViews(views) != null;
    if (!hasTimeAgo && !hasViews) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasTimeAgo)
          _MetaItem(assetName: 'calendar_2', label: timeAgo!, color: metaColor),
        if (hasTimeAgo && hasViews) const SizedBox(width: 8.0),
        if (hasViews)
          _MetaItem(
              assetName: 'eye_outline', label: views!.trim(), color: metaColor),
      ],
    );
  }
}

/// Full-width video card used on the Video tab: title, date + views row, and
/// a thumbnail with a centered play button over a dark overlay.
///
/// Purely visual. Taps, navigation and data formatting stay with the caller.
class VideoListCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? timeAgo;
  final String? views;

  const VideoListCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.timeAgo,
    this.views,
  });

  static const double imageAspectRatio = 340 / 198;
  static const double _radius = 8.0;
  static const double _imageRadius = 4.0;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasTimeAgo = timeAgo != null && timeAgo!.isNotEmpty;
    final bool hasViews = parseVideoViews(views) != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9.0),
      decoration: BoxDecoration(
        color: UiUtils.getColorScheme(context).surface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
            color: isDark ? darkBorderDefaultColor : borderDefaultColor,
            width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CustomTextLabel(
            text: title,
            textStyle: TextStyle(
                fontSize: 16.0,
                height: 24 / 16,
                fontWeight: FontWeight.w500,
                color: UiUtils.getColorScheme(context).onPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasTimeAgo || hasViews) ...<Widget>[
            const SizedBox(height: 10.0),
            VideoMetaRow(timeAgo: timeAgo, views: views),
          ],
          const SizedBox(height: 10.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(_imageRadius),
            child: AspectRatio(
              aspectRatio: imageAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CustomNetworkImage(
                      networkImageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(0.4)),
                  Center(
                    child: SvgPictureWidget(
                        assetName: 'video_circle', height: 32.0, width: 32.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
