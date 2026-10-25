// The "Short News" rail on the home screen (Figma node 4170:9559, dark
// 4170:9648 — the frame is named "Video Container" but its header reads
// "Short News"): a header with "View More" above a horizontally scrolling row of
// bordered cards, each a two-line title, a 116px thumbnail and a date / views
// row. Replaces the floating Short News button the home screen used to carry.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/utils/ui_utils.dart';

class ShortNewsHomeSection extends StatelessWidget {
  final List<NewsModel> shortNews;
  final VoidCallback? onViewMoreTap;
  final void Function(int index)? onNewsTap;

  const ShortNewsHomeSection({
    super.key,
    required this.shortNews,
    this.onViewMoreTap,
    this.onNewsTap,
  });

  static const double _cardGap = 12.0;

  @override
  Widget build(BuildContext context) {
    if (shortNews.isEmpty) return const SizedBox.shrink();

    final colorScheme = UiUtils.getColorScheme(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomTextLabel(
                text: 'shortNewsLbl',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textStyle: TextStyle(
                  fontSize: 20.0,
                  height: 28 / 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primaryContainer,
                ),
              ),
            ),
            GestureDetector(
              onTap: onViewMoreTap,
              child: CustomTextLabel(
                text: 'viewMore',
                textStyle: TextStyle(
                  fontSize: 14.0,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? textTertiaryColor : textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: _ShortNewsCard.heightFor(MediaQuery.textScalerOf(context)),
          child: ListView.separated(
            // The rail runs off the trailing screen edge in the design, past
            // the 16px page gutter this section sits inside.
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: shortNews.length,
            separatorBuilder: (_, __) => const SizedBox(width: _cardGap),
            itemBuilder: (context, index) => _ShortNewsCard(
              news: shortNews[index],
              onTap: onNewsTap == null ? null : () => onNewsTap!(index),
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma "card container" (222px wide): 8px padding, 1px Border/Default outline,
/// 8px radius, 4.313px between the title, thumbnail and meta row.
class _ShortNewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback? onTap;

  const _ShortNewsCard({required this.news, this.onTap});

  static const double _width = 222.0;
  static const double _padding = 8.0;
  static const double _borderWidth = 1.0;
  static const double _gap = 4.313;
  // Breathing room between the thumbnail and the date / views row, a touch
  // more than the design's 4.313px `_gap` used around the title.
  static const double _metaGap = 8.0;
  static const double _imageHeight = 116.0;
  static const double _iconSize = 16.0;
  static const double _titleFontSize = 14.0;
  static const double _titleLineHeight = 1.55;
  static const double _metaFontSize = 11.0;
  static const double _metaLineHeight = 14.0;

  /// Two title lines are always reserved so every card in the rail is the same
  /// height, whatever the headline length.
  static double _titleBlockHeight(TextScaler scaler) =>
      scaler.scale(_titleFontSize) * _titleLineHeight * 2;

  static double _metaRowHeight(TextScaler scaler) =>
      scaler.scale(_metaLineHeight) > _iconSize
          ? scaler.scale(_metaLineHeight)
          : _iconSize;

  /// Full card height, following the system text scale so the fixed-height
  /// rail never clips the title or meta row.
  static double heightFor(TextScaler scaler) =>
      2 * (_borderWidth + _padding) +
      _titleBlockHeight(scaler) +
      _gap +
      _imageHeight +
      _metaGap +
      _metaRowHeight(scaler);

  /// "4 Aug 2026" from the published date, falling back to the created date
  /// (`published_date` is null for many items).
  String? get _dateText {
    for (final String? raw in <String?>[news.publishDate, news.date]) {
      final DateTime? parsed =
          (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
      if (parsed != null) return DateFormat('d MMM yyyy').format(parsed);
    }
    return null;
  }

  String? get _viewsText {
    final String? views = news.totalViews?.trim();
    return (views == null || views.isEmpty || views == "null") ? null : views;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    // Text/Secondary and Icon/Secondary are the light-mode names; in dark mode
    // they resolve to #A0A0A0 and #CECECE.
    final Color metaTextColor = isDark ? textTertiaryColor : textSecondaryColor;
    final Color metaIconColor =
        isDark ? darkIconSecondaryColor : textSecondaryColor;
    final String? dateText = _dateText;
    final String? viewsText = _viewsText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _width,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: isDark ? darkSecondaryColor : secondaryColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
              color: isDark ? darkBorderDefaultColor : borderDefaultColor,
              width: _borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _titleBlockHeight(scaler),
              width: double.infinity,
              child: Text(
                news.title ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _titleFontSize,
                  height: _titleLineHeight,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.28,
                  color: UiUtils.getColorScheme(context).primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: _gap),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CustomNetworkImage(
                  networkImageUrl: news.image ?? "",
                  width: double.maxFinite,
                  height: _imageHeight,
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: _metaGap),
            Row(
              children: [
                if (dateText != null) ...[
                  SvgPictureWidget(
                      assetName: "calendar_2",
                      width: _iconSize,
                      height: _iconSize,
                      assetColor: ColorFilter.mode(metaIconColor, BlendMode.srcIn)),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: _metaFontSize,
                            height: _metaLineHeight / _metaFontSize,
                            color: metaTextColor)),
                  ),
                ],
                if (dateText != null && viewsText != null)
                  const SizedBox(width: 4.0),
                if (viewsText != null) ...[
                  SvgPictureWidget(
                      assetName: "eye_outline",
                      width: _iconSize,
                      height: _iconSize,
                      assetColor: ColorFilter.mode(metaIconColor, BlendMode.srcIn)),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: Text(viewsText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: _metaFontSize,
                            height: _metaLineHeight / _metaFontSize,
                            color: metaTextColor)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
