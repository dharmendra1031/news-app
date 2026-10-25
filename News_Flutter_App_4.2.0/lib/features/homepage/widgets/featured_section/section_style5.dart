import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/features/homepage/widgets/common_section_title.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// "4 Aug 2026" from the published date, falling back to the created date
/// (`published_date` is null for many items). A value that is missing or not a
/// date is skipped instead of throwing, so the card just omits the date. RSS
/// items send a UTC `published_at`, so the date is shown in the device's
/// timezone.
String? _cardDateText(String? publishDate, String? date) {
  for (final String? raw in <String?>[publishDate, date]) {
    final DateTime? parsed =
        (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
    if (parsed != null) {
      return DateFormat('d MMM yyyy').format(parsed.toLocal());
    }
  }
  return null;
}

/// RSS items carry no category of their own (only an `rss_source_id`), so the
/// tag falls back to the section's configured category — but only when it is a
/// single one, since with several the item's own category is unknown.
String? _sectionCategoryName(FeatureSectionModel model, CategoryState state) {
  final List<String> ids = (model.categoryIds ?? '')
      .split(',')
      .map((String id) => id.trim())
      .where((String id) => id.isNotEmpty)
      .toList();
  if (ids.length != 1 || state is! CategoryFetchSuccess) return null;
  for (final category in state.category) {
    if (category.id == ids.first) return category.categoryName;
  }
  return null;
}

/// Figma "card container": a bordered, fixed-width card in a horizontally
/// scrolling row — image (with a centered play icon for video), a category
/// tag below it, a title, then a meta row: author + date for an RSS item, date
/// + read count for any other item.
class _VideoGridCard extends StatelessWidget {
  static const double width = 170.0;
  static const double _padding = 4.0;
  static const double _borderWidth = 1.0;
  static const double _imageHeight = 116.0;
  static const double _gap = 4.313;
  static const double _playIconSize = 24.0;
  // Keeps the tap target at the old 40px play button while the glyph itself
  // follows the 24px "video-circle" in the design.
  static const double _playTapSize = 40.0;
  static const double _tagFontSize = 12.0;
  static const double _tagLineHeight = 16 / 12;
  static const double _tagPaddingV = 4.0;
  static const double _titleFontSize = 14.0;
  static const double _titleLineHeight = 1.55;
  static const int _titleLines = 3;
  static const double _authorFontSize = 12.0;
  static const double _authorLineHeight = 16 / 12;
  static const double _dateFontSize = 11.0;
  static const double _dateLineHeight = 14 / 11;
  static const double _viewsIconSize = 12.0;

  /// Figma's title block is 66px: three lines, each rounded up from 21.7px to
  /// 22px.
  static double _titleBlockHeight(TextScaler scaler) =>
      (scaler.scale(_titleFontSize) * _titleLineHeight).ceilToDouble() *
      _titleLines;

  static double _tagHeight(TextScaler scaler) =>
      scaler.scale(_tagFontSize) * _tagLineHeight + 2 * _tagPaddingV;

  static double _metaRowHeight(TextScaler scaler) => max(
      scaler.scale(_authorFontSize) * _authorLineHeight,
      scaler.scale(_dateFontSize) * _dateLineHeight);

  /// Full card height: 244.94px at the default text size, the Figma card, and
  /// growing with the system text scale so the fixed-height rail never clips
  /// the tag, title or author row.
  static double heightFor(TextScaler scaler) =>
      2 * (_borderWidth + _padding) +
      _imageHeight +
      _gap +
      _tagHeight(scaler) +
      _gap +
      _titleBlockHeight(scaler) +
      _gap +
      _metaRowHeight(scaler);

  final String imageUrl;
  final bool isVideo;
  final String? categoryName;
  final String title;
  final String? authorName;
  final String? dateText;
  final String? viewsText;
  final VoidCallback? onPlayTap;

  const _VideoGridCard({
    required this.imageUrl,
    required this.title,
    this.isVideo = false,
    this.categoryName,
    this.authorName,
    this.dateText,
    this.viewsText,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasAuthor = authorName != null && authorName!.trim().isNotEmpty;
    final bool hasDate = dateText != null && dateText!.isNotEmpty;
    // A count of 0 (or a missing/"null" value) hides the eye + count entirely.
    final bool hasViews = (int.tryParse(viewsText?.trim() ?? '') ?? 0) > 0;
    final TextStyle dateStyle = TextStyle(
        fontSize: _dateFontSize,
        height: _dateLineHeight,
        color: isDark ? textSecondaryColor : textTertiaryColor);
    return Container(
      width: width,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: UiUtils.getColorScheme(context).surface,
        borderRadius: BorderRadius.circular(8.0),
        // Figma Border/Default: #DBDBDB light / #363636 dark. (Border/Muted
        // equals the page background in each theme, so it draws no visible
        // outline.)
        border: Border.all(
            color: isDark ? darkBorderDefaultColor : borderDefaultColor,
            width: _borderWidth),
      ),
      // The rail gives the card its full height (see [heightFor]), so the title
      // takes the space left between the tag and the author row and the author
      // row stays at the bottom, whatever the headline length or text scale.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: _imageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CustomNetworkImage(
                      networkImageUrl: imageUrl,
                      width: double.maxFinite,
                      height: _imageHeight,
                      fit: BoxFit.cover,
                      isVideo: isVideo),
                ),
                if (isVideo)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: <double>[0.0, 0.51923, 1.0],
                          colors: <Color>[
                            Colors.transparent,
                            Color(0x80000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isVideo)
                  Center(
                    child: InkWell(
                        onTap: onPlayTap,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                            width: _playTapSize,
                            height: _playTapSize,
                            child: Center(
                                child: UiUtils.setPlayButton(
                                    context: context,
                                    heightVal: _playIconSize)))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: _gap),
          if (categoryName != null &&
              categoryName!.trim().isNotEmpty) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0, vertical: _tagPaddingV),
              decoration: BoxDecoration(
                color: UiUtils.getColorScheme(context).primaryContainer,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: CustomTextLabel(
                text: categoryName!,
                textStyle: TextStyle(
                    fontSize: _tagFontSize,
                    height: _tagLineHeight,
                    fontWeight: FontWeight.w400,
                    color: isDark ? darkTextInverseColor : Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: _gap),
          ],
          Expanded(
            child: CustomTextLabel(
              text: title,
              textStyle: TextStyle(
                  fontSize: _titleFontSize,
                  height: _titleLineHeight,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.28,
                  color: UiUtils.getColorScheme(context).primaryContainer),
              maxLines: _titleLines,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
          if (hasAuthor || hasDate || hasViews) ...<Widget>[
            const SizedBox(height: _gap),
            Row(
              children: <Widget>[
                if (hasAuthor)
                  Expanded(
                    child: CustomTextLabel(
                        text: authorName!,
                        textStyle: TextStyle(
                            fontSize: _authorFontSize,
                            height: _authorLineHeight,
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                if (hasDate) ...<Widget>[
                  if (hasAuthor) const SizedBox(width: 4.0),
                  // Natural width, so the (Expanded) author takes the rest.
                  CustomTextLabel(
                      text: dateText!,
                      textStyle: dateStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                if (hasViews) ...<Widget>[
                  if (hasDate) const SizedBox(width: 8.0),
                  // Sized to the 11px date text so the row stays as tall as
                  // the author line reserved in [heightFor].
                  SvgPictureWidget(
                      assetName: "eye_outline",
                      height: _viewsIconSize,
                      width: _viewsIconSize,
                      assetColor: ColorFilter.mode(
                          dateStyle.color ?? Colors.transparent,
                          BlendMode.srcIn)),
                  const SizedBox(width: 2.0),
                  Flexible(
                    child: CustomTextLabel(
                        text: viewsText!,
                        textStyle: dateStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class Style5Section extends StatelessWidget {
  final FeatureSectionModel model;

  /// Set for the home "Video News" slot. Its Figma cards always carry the play
  /// icon and image gradient, but an admin can back that section with RSS items
  /// (`news_type` is `rss_feeds_news`), which [isVideo] below does not treat as
  /// video, so the overlay would otherwise be skipped.
  final bool isVideoRail;

  const Style5Section({
    super.key,
    required this.model,
    this.isVideoRail = false,
  });

  @override
  Widget build(BuildContext context) {
    return style5Data(model, context);
  }

  Widget style5Data(FeatureSectionModel model, BuildContext context) {
    int limit = limitOfAllOtherStyle;
    int newsLength = (model.newsType == newsTypeToString(NewsType.news) ||
            model.newsType == newsTypeToString(NewsType.userChoice))
        ? model.news!.length
        : (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
            ? model.rssFeedNews!.length
            : (model.newsType == newsTypeToString(NewsType.authorNews))
                ? (model.authorNews?.length ?? 0)
                : model.videos!.length;
    int brNewsLength = model.newsType == newsTypeToString(NewsType.breakingNews)
        ? model.breakNews!.length
        : model.breakVideos!.length;
    final bool isVideo = model.newsType == newsTypeToString(NewsType.videos) ||
        model.videosType == newsTypeToString(NewsType.videos);
    // [isVideo] means real video data (the play button opens the player). The
    // Video News rail also draws the play icon on RSS/news items, which keep
    // opening their own link on tap.
    final bool showPlayIcon = isVideo || isVideoRail;
    final double railHeight =
        _VideoGridCard.heightFor(MediaQuery.textScalerOf(context));
    // Only RSS items fall back to the section's category, so the category list
    // is only watched for them.
    final String? rssCategoryName =
        model.newsType == newsTypeToString(NewsType.rssFeedsNews)
            ? _sectionCategoryName(model, context.watch<CategoryCubit>().state)
            : null;
    if (model.breakVideos!.isNotEmpty ||
        model.breakNews!.isNotEmpty ||
        model.videos!.isNotEmpty ||
        model.news?.isNotEmpty == true ||
        model.authorNews?.isNotEmpty == true ||
        model.rssFeedNews?.isNotEmpty == true) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commonSectionTitle(model, context),
          if ((model.newsType == newsTypeToString(NewsType.news) ||
                  model.newsType == newsTypeToString(NewsType.userChoice) ||
                  model.newsType == newsTypeToString(NewsType.authorNews) ||
                  model.newsType == newsTypeToString(NewsType.rssFeedsNews))
              ? (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
                  ? model.rssFeedNews!.isNotEmpty
                  : (model.newsType == newsTypeToString(NewsType.authorNews))
                      ? model.authorNews?.isNotEmpty == true
                      : model.news!.isNotEmpty
              : model.videos!.isNotEmpty)
            SizedBox(
              height: railHeight,
              child: ListView.separated(
                  // The rail runs off the trailing screen edge in the design,
                  // past the 16px page gutter this section sits inside.
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: min(newsLength, limit),
                  separatorBuilder: (_, __) => const SizedBox(width: 12.0),
                  itemBuilder: (context, index) {
                    bool isRssFeedsNews = model.newsType ==
                        newsTypeToString(NewsType.rssFeedsNews);
                    NewsModel data =
                        (model.newsType == newsTypeToString(NewsType.news) ||
                                model.newsType ==
                                    newsTypeToString(NewsType.userChoice))
                            ? model.news![index]
                            : ((isRssFeedsNews)
                                ? NewsModel()
                                : (model.newsType ==
                                        newsTypeToString(NewsType.authorNews))
                                    ? (model.authorNews ?? [])[index]
                                    : model.videos![index]);
                    final RSSFeedModel rssData = (model.newsType ==
                            newsTypeToString(NewsType.rssFeedsNews))
                        ? (model.rssFeedNews?[index] ?? RSSFeedModel())
                        : RSSFeedModel();
                    return InkWell(
                      onTap: () async {
                        // Open RSS feed links in external browser for RSS sections
                        if (model.newsType ==
                                newsTypeToString(NewsType.rssFeedsNews) &&
                            rssData.feedUrl != null &&
                            rssData.feedUrl!.isNotEmpty) {
                          final uri = Uri.tryParse(rssData.feedUrl!);
                          if (uri != null) {
                            await launchUrl(uri,
                                mode: LaunchMode.inAppBrowserView);
                          }
                          return;
                        }

                        if (model.newsType == newsTypeToString(NewsType.news) ||
                            model.newsType ==
                                newsTypeToString(NewsType.userChoice) ||
                            model.newsType ==
                                newsTypeToString(NewsType.authorNews)) {
                          //show interstitial ads
                          UiUtils.showInterstitialAds(context: context);
                          List<NewsModel> newsList = [];
                          newsList.addAll(model.newsType ==
                                  newsTypeToString(NewsType.authorNews)
                              ? (model.authorNews ?? [])
                              : (model.news ?? []));
                          newsList.removeAt(index);
                          Navigator.of(context).pushNamed(Routes.newsDetails,
                              arguments: {
                                "model": data,
                                "newsList": newsList,
                                "isFromBreak": false,
                                "fromShowMore": false
                              });
                        }
                      },
                      child: _VideoGridCard(
                        imageUrl: isRssFeedsNews
                            ? (rssData.image ?? "")
                            : (data.image ?? ""),
                        isVideo: showPlayIcon,
                        categoryName: isRssFeedsNews
                            ? ((rssData.categoryName ?? '').trim().isNotEmpty
                                ? rssData.categoryName
                                : rssCategoryName)
                            : data.categoryName,
                        title: isRssFeedsNews
                            ? rssData.feedName ?? ""
                            : data.title ?? "",
                        // RSS item: author + date. Any other item: date + read
                        // count.
                        authorName: isRssFeedsNews ? rssData.author : null,
                        dateText: isRssFeedsNews
                            ? _cardDateText(rssData.pubDate, rssData.date)
                            : _cardDateText(data.publishDate, data.date),
                        viewsText: isRssFeedsNews ? null : data.totalViews,
                        onPlayTap: isVideo
                            ? () {
                                List<NewsModel> allNewsList =
                                    List.from(model.videos ?? [])
                                      ..removeAt(index);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsVideo, arguments: {
                                  "from": 1,
                                  "model": data,
                                  "otherVideos": allNewsList
                                });
                              }
                            : null,
                      ),
                    );
                  }),
            ),
          if ((model.newsType == newsTypeToString(NewsType.breakingNews) ||
                  model.videosType ==
                      newsTypeToString(NewsType.breakingNews)) &&
              (model.newsType == newsTypeToString(NewsType.breakingNews)
                  ? model.breakNews!.isNotEmpty
                  : model.breakVideos!.isNotEmpty))
            SizedBox(
              height: railHeight,
              child: ListView.separated(
                  // The rail runs off the trailing screen edge in the design,
                  // past the 16px page gutter this section sits inside.
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: min(brNewsLength, limit),
                  separatorBuilder: (_, __) => const SizedBox(width: 12.0),
                  itemBuilder: (context, index) {
                    BreakingNewsModel data = model.newsType ==
                            newsTypeToString(NewsType.breakingNews)
                        ? model.breakNews![index]
                        : model.breakVideos![index];
                    return InkWell(
                      onTap: () {
                        if (model.newsType ==
                            newsTypeToString(NewsType.breakingNews)) {
                          //interstitial ads
                          UiUtils.showInterstitialAds(context: context);
                          List<BreakingNewsModel> breakList = [];
                          breakList.addAll(model.breakNews!);
                          breakList.removeAt(index);
                          Navigator.of(context)
                              .pushNamed(Routes.newsDetails, arguments: {
                            "breakModel": data,
                            "breakNewsList": breakList,
                            "isFromBreak": true,
                            "fromShowMore": false
                          });
                        }
                      },
                      child: _VideoGridCard(
                        imageUrl: data.image ?? "",
                        isVideo: showPlayIcon,
                        categoryName: data.categoryName,
                        title: data.title ?? "",
                        dateText: _cardDateText(null, data.date),
                        viewsText: data.totalViews,
                        onPlayTap: isVideo
                            ? () {
                                List<BreakingNewsModel> brNewsList =
                                    List.from(model.breakVideos ?? [])
                                      ..removeAt(index);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsVideo, arguments: {
                                  "from": 3,
                                  "breakModel": data,
                                  "otherBreakingVideos": brNewsList
                                });
                              }
                            : null,
                      ),
                    );
                  }),
            )
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
