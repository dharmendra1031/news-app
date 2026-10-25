import 'dart:math';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/homepage/widgets/common_section_title.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Figma "card container" (Latest News): a title, a meta row (author/date for
/// an RSS item, calendar/date + eye/views for any other item), a 156px image
/// with a white top-right category tag, then a short description.
class _LatestNewsCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final bool isVideo;
  final String? categoryName;
  final String? authorText;
  final String? dateText;
  final String? viewsText;
  final String? description;
  final VoidCallback onTap;

  const _LatestNewsCard({
    required this.imageUrl,
    required this.title,
    required this.onTap,
    this.isVideo = false,
    this.categoryName,
    this.authorText,
    this.dateText,
    this.viewsText,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Text/Tertiary and Text/Secondary swap values between light and dark.
    final Color metaColor = isDark ? textSecondaryColor : textTertiaryColor;
    final Color descriptionColor =
        isDark ? textTertiaryColor : textSecondaryColor;
    final bool hasAuthor = authorText != null && authorText!.trim().isNotEmpty;
    final bool hasDate = dateText != null && dateText!.isNotEmpty;
    // A count of 0 (or a missing/"null" value) hides the eye + count entirely.
    final bool hasViews = (int.tryParse(viewsText?.trim() ?? '') ?? 0) > 0;
    final TextStyle metaStyle =
        TextStyle(fontSize: 12.0, height: 16 / 12, color: metaColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 6.0,
        children: <Widget>[
          CustomTextLabel(
            text: title,
            textStyle: TextStyle(
                fontSize: 16.0,
                height: 24 / 16,
                fontWeight: FontWeight.w500,
                color: UiUtils.getColorScheme(context).primaryContainer),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
          if (hasAuthor || hasDate || hasViews)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (hasAuthor) ...<Widget>[
                  SvgPictureWidget(
                      assetName: "profile",
                      height: 16.0,
                      width: 16.0,
                      assetColor: ColorFilter.mode(metaColor, BlendMode.srcIn)),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: CustomTextLabel(
                        text: authorText!,
                        textStyle: metaStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
                if (hasAuthor && hasDate) const SizedBox(width: 8.0),
                if (hasDate) ...<Widget>[
                  SvgPictureWidget(
                      assetName: "calendar_2",
                      height: 16.0,
                      width: 16.0,
                      assetColor: ColorFilter.mode(metaColor, BlendMode.srcIn)),
                  const SizedBox(width: 4.0),
                  // With an author only the author shrinks, so it takes the
                  // room the date leaves.
                  if (hasAuthor)
                    CustomTextLabel(
                        text: dateText!,
                        textStyle: metaStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  else
                    Flexible(
                      child: CustomTextLabel(
                          text: dateText!,
                          textStyle: metaStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                if (hasDate && hasViews) const SizedBox(width: 8.0),
                if (hasViews) ...<Widget>[
                  SvgPictureWidget(
                      assetName: "eye_outline",
                      height: 16.0,
                      width: 16.0,
                      assetColor: ColorFilter.mode(metaColor, BlendMode.srcIn)),
                  const SizedBox(width: 4.0),
                  Flexible(
                    child: CustomTextLabel(
                        text: viewsText!,
                        textStyle: metaStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          SizedBox(
            height: 156.0,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: CustomNetworkImage(
                      networkImageUrl: imageUrl,
                      width: double.maxFinite,
                      height: 156.0,
                      fit: BoxFit.cover,
                      isVideo: isVideo),
                ),
                if (isVideo)
                  Center(child: UiUtils.setPlayButton(context: context)),
                if (categoryName != null && categoryName!.trim().isNotEmpty)
                  PositionedDirectional(
                    top: 8.0,
                    end: 8.0,
                    // The Figma tag is a white chip with Text/Primary (#1E1E1E)
                    // text; both are kept fixed so it stays legible over the
                    // photo in dark mode too.
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: CustomTextLabel(
                        text: categoryName!,
                        textStyle: const TextStyle(
                            fontSize: 12.0,
                            height: 16 / 12,
                            // Figma centres the glyphs in the 16px line;
                            // Flutter's default weights the spare space toward
                            // the top, which sat the label low in the chip.
                            leadingDistribution: TextLeadingDistribution.even,
                            fontWeight: FontWeight.w400,
                            color: textPrimaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (description != null && description!.isNotEmpty)
            CustomTextLabel(
              text: description!,
              textStyle: TextStyle(
                  fontSize: 12.0,
                  height: 16 / 12,
                  fontWeight: FontWeight.w400,
                  color: descriptionColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
        ],
      ),
    );
  }
}

/// Figma "Line 4": a 1px Border/Default line between cards. It is drawn 7px
/// under the previous card with 8px above the next (16px in all) and spans the
/// full 358px card width.
class _LatestNewsDivider extends StatelessWidget {
  const _LatestNewsDivider();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 7.0, bottom: 8.0),
      child: Divider(
          height: 1.0,
          thickness: 1.0,
          color: isDark ? darkBorderDefaultColor : borderDefaultColor),
    );
  }
}

class Style6Section extends StatelessWidget {
  final FeatureSectionModel model;

  const Style6Section({super.key, required this.model});

  /// Figma shows exactly 3 stacked cards. This only caps how many are drawn on
  /// the home feed — the API data in [model] is untouched and "View More" still
  /// opens the full list.
  static const int _limit = 3;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = _buildCards(context);
    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        commonSectionTitle(model, context),
        for (int i = 0; i < cards.length; i++) ...<Widget>[
          if (i != 0) const _LatestNewsDivider(),
          cards[i],
        ],
      ],
    );
  }

  List<Widget> _buildCards(BuildContext context) {
    final NewsType type = model.newsTypeEnum;
    final bool isVideo = type == NewsType.videos;

    if (type == NewsType.breakingNews ||
        model.videosTypeEnum == NewsType.breakingNews) {
      final List<BreakingNewsModel> list = type == NewsType.breakingNews
          ? (model.breakNews ?? [])
          : (model.breakVideos ?? []);
      return List<Widget>.generate(min(list.length, _limit), (int index) {
        final BreakingNewsModel data = list[index];
        return _LatestNewsCard(
          imageUrl: data.image ?? "",
          title: data.title ?? "",
          isVideo: isVideo,
          dateText: _formatDate(null, data.date),
          viewsText: data.totalViews,
          description: _plainText(data.desc),
          onTap: () {
            final List<BreakingNewsModel> others = List.of(list)
              ..removeAt(index);
            if (isVideo) {
              Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
                "from": 3,
                "breakModel": data,
                "otherBreakingVideos": others
              });
            } else {
              //interstitial ads
              UiUtils.showInterstitialAds(context: context);
              Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                "breakModel": data,
                "breakNewsList": others,
                "isFromBreak": true,
                "fromShowMore": false
              });
            }
          },
        );
      });
    }

    if (type == NewsType.rssFeedsNews) {
      final List<RSSFeedModel> list = model.rssFeedNews ?? [];
      return List<Widget>.generate(min(list.length, _limit), (int index) {
        final RSSFeedModel data = list[index];
        return _LatestNewsCard(
          imageUrl: data.image ?? "",
          title: data.feedName ?? "",
          categoryName: data.categoryName,
          // RSS item: author + date, no read count.
          authorText: data.author,
          dateText: _formatDate(data.pubDate, data.date),
          description: _plainText(data.description),
          // RSS items open their source link in the in-app browser.
          onTap: () async {
            final Uri? uri = Uri.tryParse(data.feedUrl ?? "");
            if (uri != null && uri.hasScheme) {
              await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
            }
          },
        );
      });
    }

    final List<NewsModel> list =
        (type == NewsType.news || type == NewsType.userChoice)
            ? (model.news ?? [])
            : type == NewsType.authorNews
                ? (model.authorNews ?? [])
                : (model.videos ?? []);
    return List<Widget>.generate(min(list.length, _limit), (int index) {
      final NewsModel data = list[index];
      return _LatestNewsCard(
        imageUrl: data.image ?? "",
        title: data.title ?? "",
        isVideo: isVideo,
        categoryName: data.categoryName,
        dateText: _formatDate(data.publishDate, data.date),
        viewsText: data.totalViews,
        // `summarized_description` is often null, so fall back to the HTML body.
        description: _plainText((data.shortDesc ?? "").trim().isNotEmpty
            ? data.shortDesc
            : data.desc),
        onTap: () {
          final List<NewsModel> others = List.of(list)..removeAt(index);
          if (isVideo) {
            Navigator.of(context).pushNamed(Routes.newsVideo,
                arguments: {"from": 1, "model": data, "otherVideos": others});
          } else {
            //interstitial ads
            UiUtils.showInterstitialAds(context: context);
            Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
              "model": data,
              "newsList": others,
              "isFromBreak": false,
              "fromShowMore": false
            });
          }
        },
      );
    });
  }

  /// The API sends descriptions as HTML; the 2-line preview needs plain text
  /// on a single flow of whitespace.
  static String _plainText(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    return (html_parser.parse(raw).body?.text ?? "")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// "11 Sep 2025" from the first of [primary] / [fallback] that parses —
  /// `published_date` is null for many items, so the created `date` backs it up.
  static String? _formatDate(String? primary, String? fallback) {
    for (final String? raw in <String?>[primary, fallback]) {
      final DateTime? parsed =
          (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
      if (parsed != null) return DateFormat('d MMM yyyy').format(parsed);
    }
    return null;
  }
}
