import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:flutter/material.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// "11 Sep 2026" from the first of [publishDate] / [date] that parses —
/// `published_date` is null for many items, so the created date backs it up. A
/// value that is missing or not a date is skipped instead of throwing, so the
/// banner just omits the date row. RSS items send a UTC `published_at`, so the
/// date is shown in the device's timezone.
String? _bannerDateText(String? publishDate, String? date) {
  for (final String? raw in <String?>[publishDate, date]) {
    final DateTime? parsed =
        (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
    if (parsed != null) {
      return DateFormat('d MMM yyyy').format(parsed.toLocal());
    }
  }
  return null;
}

/// The banner's read count, or null for 0 (or a missing / unparsable value) so
/// the meta row never shows an eye icon next to "0".
String? _bannerViewsText(String? rawViews) {
  final int views = int.tryParse(rawViews?.trim() ?? '') ?? 0;
  return views > 0 ? "$views" : null;
}

/// Figma "Container" banner card: full-bleed 235px image, bottom gradient
/// scrim, top-left category tag, bottom title + meta row. The meta row is
/// author + date for an RSS item and date + read count for any other item.
class _BannerOverlay extends StatelessWidget {
  final String imageUrl;
  final bool isVideo;
  final String? categoryName;
  final String title;
  final String? authorText;
  final String? dateText;
  final String? viewsText;
  final VoidCallback? onPlayTap;

  const _BannerOverlay({
    required this.imageUrl,
    required this.title,
    this.isVideo = false,
    this.categoryName,
    this.authorText,
    this.dateText,
    this.viewsText,
    this.onPlayTap,
  });

  /// An icon + white label pair of the meta row. A [grow] item shrinks (with an
  /// ellipsis) to fit the row; the others keep their natural width.
  Widget _metaItem(String assetName, String text, {required bool grow}) {
    final Widget label = CustomTextLabel(
      text: text,
      textStyle: const TextStyle(
          fontSize: 12.0,
          height: 16 / 12,
          fontWeight: FontWeight.w400,
          color: Colors.white),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final Widget item = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPictureWidget(
            assetName: assetName,
            height: 16.0,
            width: 16.0,
            assetColor: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        const SizedBox(width: 10.0),
        grow ? Flexible(child: label) : label,
      ],
    );
    return grow ? Flexible(child: item) : item;
  }

  Widget _missingImageFallback() => ColoredBox(
        color: const Color(0xff1e1e1e),
        child: Center(
          child: Image.asset(
            UiUtils.getPlaceholderPngPath(),
            width: 96.0,
            height: 96.0,
            fit: BoxFit.contain,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasAuthor = authorText != null && authorText!.trim().isNotEmpty;
    // With an author only the author shrinks, so it takes the room the date
    // leaves; without one the date and read count share the row.
    final List<Widget> metaItems = <Widget>[
      if (hasAuthor) _metaItem("profile", authorText!, grow: true),
      if (dateText != null && dateText!.trim().isNotEmpty)
        _metaItem("calendar_2", dateText!, grow: !hasAuthor),
      if (viewsText != null && viewsText!.trim().isNotEmpty)
        _metaItem("eye_outline", viewsText!, grow: !hasAuthor),
    ];
    return SizedBox(
      height: 235.0,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomNetworkImage(
              networkImageUrl: imageUrl,
              width: double.maxFinite,
              height: 235.0,
              fit: BoxFit.cover,
              isVideo: isVideo,
              // The shared placeholder.png is a square logo mark; letting
              // CustomNetworkImage cover-crop it into this wide 235px banner
              // (its default fallback behavior) zooms and clips it into an
              // unrecognizable smear. Contain it centered on the gradient's
              // own end color instead, so a missing/broken image reads as a
              // deliberate empty state rather than a distorted stretch.
              placeholderBuilder: _missingImageFallback(),
              errorBuilder: _missingImageFallback()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: <double>[0.166, 1.0],
                colors: <Color>[Colors.transparent, Color(0xff1e1e1e)],
              ),
            ),
          ),
          if (isVideo)
            Center(
              child: InkWell(
                  onTap: onPlayTap,
                  child: UiUtils.setPlayButton(context: context)),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (categoryName != null && categoryName!.trim().isNotEmpty)
                  // Figma Background/Inverse + Text/Inverse Dark: #1E1E1E chip
                  // with white text in light, white chip with #101010 text in
                  // dark. Title and date stay white on the scrim in both.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: CustomTextLabel(
                      text: categoryName!,
                      textStyle: TextStyle(
                          fontSize: 12.0,
                          height: 16 / 12,
                          // Figma centres the glyphs in the 16px line; Flutter's
                          // default weights the spare space toward the top,
                          // which sat the label ~0.6px low in the 24px chip.
                          leadingDistribution: TextLeadingDistribution.even,
                          fontWeight: FontWeight.w400,
                          color: isDark ? darkTextInverseColor : Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CustomTextLabel(
                      text: title,
                      textStyle: const TextStyle(
                          fontSize: 14.0,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                    if (metaItems.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (int i = 0; i < metaItems.length; i++) ...<Widget>[
                            if (i > 0) const SizedBox(width: 12.0),
                            metaItems[i],
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Style1Section extends StatefulWidget {
  final FeatureSectionModel model;

  const Style1Section({super.key, required this.model});

  @override
  Style1SectionState createState() => Style1SectionState();
}

class Style1SectionState extends State<Style1Section> {
  int? style1Sel = 0;
  PageController? _pageStyle1Controller = PageController();
  int limit = limitOfStyle1;

  /// Figma shows 5 pagination dots; more slides than this reuse the same 5.
  static const int _maxDots = 5;
  int newsLength = 0;
  int brNewsLength = 0;
  String? sectionCategoryName;

  @override
  void dispose() {
    _pageStyle1Controller!.dispose();
    super.dispose();
  }

  /// The tag text: the item's own category when the API sent one, otherwise
  /// the section's configured category (see [_sectionCategoryName]).
  String? _tagCategoryName(String? itemCategoryName) =>
      (itemCategoryName ?? '').trim().isNotEmpty
          ? itemCategoryName
          : sectionCategoryName;

  /// Fallback for items with no category name of their own (an RSS item may
  /// only carry an `rss_source_id`): the section's configured category — but
  /// only when it is a single one, since with several the item's own category
  /// is unknown.
  String? _sectionCategoryName(CategoryState state) {
    final List<String> ids = (widget.model.categoryIds ?? '')
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

  @override
  Widget build(BuildContext context) {
    sectionCategoryName =
        _sectionCategoryName(context.watch<CategoryCubit>().state);
    newsLength = (widget.model.newsType == newsTypeToString(NewsType.news) ||
            widget.model.newsType == newsTypeToString(NewsType.userChoice))
        ? (widget.model.news?.length ?? 0)
        : (widget.model.newsType == newsTypeToString(NewsType.rssFeedsNews))
            ? (widget.model.rssFeedNews?.length ?? 0)
            : widget.model.newsType == newsTypeToString(NewsType.authorNews)
                ? (widget.model.authorNews?.length ?? 0)
                : (widget.model.videos?.length ?? 0);
    brNewsLength =
        widget.model.newsType == newsTypeToString(NewsType.breakingNews)
            ? (widget.model.breakNews?.length ?? 0)
            : (widget.model.breakVideos?.length ?? 0);

    return style1Data(widget.model);
  }

  Widget style1Data(FeatureSectionModel model) {
    final isNewsType = model.newsType == newsTypeToString(NewsType.news) ||
        model.newsType == newsTypeToString(NewsType.userChoice) ||
        model.newsType == newsTypeToString(NewsType.authorNews) ||
        model.newsType == newsTypeToString(NewsType.rssFeedsNews);
    final isVideoNewsType = model.videosType == newsTypeToString(NewsType.news);

    final hasData = model.newsType == newsTypeToString(NewsType.rssFeedsNews)
        ? model.rssFeedNews?.isNotEmpty == true
        : model.newsType == newsTypeToString(NewsType.authorNews)
            ? model.authorNews?.isNotEmpty == true
            : isNewsType
                ? model.news?.isNotEmpty == true
                : model.videos?.isNotEmpty == true;
    if (model.breakVideos!.isNotEmpty ||
        model.breakNews!.isNotEmpty ||
        model.videos!.isNotEmpty ||
        model.news?.isNotEmpty == true ||
        model.authorNews?.isNotEmpty == true ||
        (model.rssFeedNews != null && model.rssFeedNews!.isNotEmpty)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Figma's banner (node 3718:8934) has no title/"View More" header —
          // just the image carousel and its pagination dots.
          if ((isNewsType || isVideoNewsType) && hasData) style1NewsData(model),
          if ((model.newsType == newsTypeToString(NewsType.breakingNews) ||
                  model.videosType == newsTypeToString(NewsType.breakingNews) &&
                      (model.newsType ==
                          newsTypeToString(NewsType.breakingNews))
              ? model.breakNews!.isNotEmpty
              : model.breakVideos!.isNotEmpty))
            style1BreakNewsData(model)
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget style1NewsData(FeatureSectionModel model) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Figma's banner bleeds edge-to-edge; cancel the feed's ambient 16px
        // side padding just for this carousel. Container/Padding assert
        // non-negative insets and LayoutBuilder/OverflowBox desync inside
        // this shrinkWrap ListView's dry-layout pass, so Positioned (which
        // allows negative offsets and lays out synchronously) is used
        // instead to bleed past the Stack's own bounds.
        SizedBox(
          height: 235.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -16.0,
                right: -16.0,
                top: 0,
                bottom: 0,
                child: PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: min(newsLength, limit),
                  scrollDirection: Axis.horizontal,
                  pageSnapping: true,
                  controller: _pageStyle1Controller,
                  onPageChanged: (index) {
                    setState(() => style1Sel = index);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final List<NewsModel> sourceList =
                        (model.newsType == newsTypeToString(NewsType.news) ||
                                model.newsType ==
                                    newsTypeToString(NewsType.userChoice))
                            ? (model.news ?? [])
                            : model.newsType ==
                                    newsTypeToString(NewsType.authorNews)
                                ? (model.authorNews ?? [])
                                : (model.videos ?? []);
                    bool isRssFeedsNews = model.newsType ==
                        newsTypeToString(NewsType.rssFeedsNews);
                    final List<RSSFeedModel> rssSourceList =
                        isRssFeedsNews ? (model.rssFeedNews ?? []) : [];

                    final NewsModel data =
                        sourceList.isNotEmpty ? sourceList[index] : NewsModel();
                    final RSSFeedModel rssData =
                        isRssFeedsNews ? rssSourceList[index] : RSSFeedModel();
                    final bool isVideo =
                        model.newsType == newsTypeToString(NewsType.videos);

                    return InkWell(
                      onTap: () async {
                        // Open RSS feed links in external browser for RSS sections
                        if (isRssFeedsNews &&
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
                          //interstitial ads
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
                      child: _BannerOverlay(
                        imageUrl: isRssFeedsNews
                            ? rssData.image ?? ""
                            : data.image ?? "",
                        isVideo: isVideo,
                        onPlayTap: isVideo
                            ? () {
                                List<NewsModel> newsList =
                                    List.from(model.videos ?? [])
                                      ..removeAt(index);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsVideo, arguments: {
                                  "from": 1,
                                  "model": data,
                                  "otherVideos": newsList
                                });
                              }
                            : null,
                        categoryName: _tagCategoryName(isRssFeedsNews
                            ? rssData.categoryName
                            : data.categoryName),
                        title: isRssFeedsNews
                            ? rssData.feedName ?? ""
                            : data.title ?? "",
                        // RSS item: author + date. Any other item: date + read
                        // count.
                        authorText: isRssFeedsNews ? rssData.author : null,
                        dateText: isRssFeedsNews
                            ? _bannerDateText(rssData.pubDate, rssData.date)
                            : _bannerDateText(data.publishDate, data.date),
                        viewsText: isRssFeedsNews
                            ? null
                            : _bannerViewsText(data.totalViews),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        style1Indicator(min(newsLength, limit))
      ],
    );
  }

  Widget style1BreakNewsData(FeatureSectionModel model) {
    final bool isVideo = model.newsType == newsTypeToString(NewsType.videos);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Figma's banner bleeds edge-to-edge; cancel the feed's ambient 16px
        // side padding just for this carousel. Container/Padding assert
        // non-negative insets and LayoutBuilder/OverflowBox desync inside
        // this shrinkWrap ListView's dry-layout pass, so Positioned (which
        // allows negative offsets and lays out synchronously) is used
        // instead to bleed past the Stack's own bounds.
        SizedBox(
          height: 235.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -16.0,
                right: -16.0,
                top: 0,
                bottom: 0,
                child: PageView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: min(brNewsLength, limit),
                  scrollDirection: Axis.horizontal,
                  controller: _pageStyle1Controller,
                  reverse: false,
                  onPageChanged: (index) {
                    setState(() => style1Sel = index);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    BreakingNewsModel data = model.newsType ==
                            newsTypeToString(NewsType.breakingNews)
                        ? (model.breakNews ?? [])[index]
                        : (model.breakVideos ?? [])[index];

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
                      child: _BannerOverlay(
                        imageUrl: data.image ?? "",
                        isVideo: isVideo,
                        categoryName: _tagCategoryName(data.categoryName),
                        title: data.title ?? "",
                        dateText: _bannerDateText(null, data.date),
                        viewsText: _bannerViewsText(data.totalViews),
                        onPlayTap: isVideo
                            ? () {
                                List<BreakingNewsModel> allBrNewsList =
                                    List.from(model.breakVideos ?? [])
                                      ..removeAt(index);
                                Navigator.of(context)
                                    .pushNamed(Routes.newsVideo, arguments: {
                                  "from": 3,
                                  "breakModel": data,
                                  "otherBreakingVideos": allBrNewsList
                                });
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        style1Indicator(min(brNewsLength, limit))
      ],
    );
  }

  /// Which of the [dotCount] dots is active for slide [page] of [len].
  ///
  /// With no more slides than dots it is one dot per slide. With more, the
  /// active dot walks forward to the second-to-last dot and stays there while
  /// the slides keep going, and only jumps to the last dot on the final slide —
  /// so the last dot means "end of the carousel". Going back mirrors it.
  int _activeDot(int page, int len, int dotCount) {
    if (len <= dotCount) return page;
    if (page >= len - 1) return dotCount - 1;
    return min(page, dotCount - 2);
  }

  /// Figma "Pagination Container": 8px dots, 8px apart, the active one in
  /// Background/Brand and the rest in Icon/Tertiary (#A0A0A0 light, #676767
  /// dark). [len] is the already-limited slide count of whichever list the
  /// carousel is showing, so every section type (news, RSS, author, video,
  /// breaking) gets its dots — capped at [_maxDots] so a large
  /// `limitOfStyle1` can't overflow the row.
  Widget style1Indicator(int len) {
    if (len <= 1) return const SizedBox.shrink();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveColor = isDark ? textSecondaryColor : textTertiaryColor;
    final int dotCount = min(len, _maxDots);
    final int activeDot = _activeDot(max(style1Sel ?? 0, 0), len, dotCount);
    return Align(
        alignment: Alignment.center,
        child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(dotCount, (int index) {
                return Padding(
                  padding:
                      EdgeInsetsDirectional.only(start: index == 0 ? 0.0 : 8.0),
                  child: Container(
                    height: 8.0,
                    width: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Figma dims the trailing dot (opacity 80%) to hint
                      // there's more to scroll past the visible dots.
                      color: activeDot == index
                          ? Theme.of(context).primaryColor
                          : index == dotCount - 1
                              ? inactiveColor.withOpacity(0.8)
                              : inactiveColor,
                    ),
                  ),
                );
              }),
            )));
  }
}
