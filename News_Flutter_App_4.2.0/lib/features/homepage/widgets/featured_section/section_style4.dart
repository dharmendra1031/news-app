import 'package:news/commons/widgets/network_image.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:flutter/material.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/homepage/widgets/common_section_title.dart';
import 'package:news/features/homepage/widgets/featured_section/section_meta_format.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// The non-empty meta labels of a card, in display order: author + time ago for
/// an RSS item, time ago + views for any other item (the caller passes only the
/// ones that apply).
List<String> _travelMetaParts(
        {String? authorText, String? timeAgo, String? viewsText}) =>
    <String>[
      if (authorText != null && authorText.trim().isNotEmpty) authorText,
      if (timeAgo != null && timeAgo.isNotEmpty) timeAgo,
      if (viewsText != null && viewsText.isNotEmpty) viewsText,
    ];

/// The "author • time ago" / "time ago • views" row shared by the hero and
/// ranked cards: [parts] separated by dots. With an author ([hasAuthor], always
/// the first part) only the author shrinks, so it takes the room the date
/// leaves.
class _TravelMetaRow extends StatelessWidget {
  final List<String> parts;
  final bool hasAuthor;

  const _TravelMetaRow({required this.parts, required this.hasAuthor});

  @override
  Widget build(BuildContext context) {
    const TextStyle metaStyle =
        TextStyle(fontSize: 12.0, height: 16 / 12, color: textTertiaryColor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < parts.length; i++) ...<Widget>[
          if (i > 0) ...<Widget>[
            const SizedBox(width: 6.0),
            Container(
              width: 5.0,
              height: 5.0,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: textTertiaryColor),
            ),
            const SizedBox(width: 6.0),
          ],
          if (hasAuthor && i > 0)
            CustomTextLabel(
                text: parts[i],
                textStyle: metaStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
          else
            Flexible(
              child: CustomTextLabel(
                  text: parts[i],
                  textStyle: metaStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
        ],
      ],
    );
  }
}

/// Figma "Image news container": a 215px hero image with a bottom gradient,
/// a title, a divider, then a meta row.
class _TravelHero extends StatelessWidget {
  final String imageUrl;
  final bool isVideo;
  final String title;
  final String? authorText;
  final String? timeAgo;
  final String? viewsText;
  final VoidCallback? onPlayTap;

  const _TravelHero({
    required this.imageUrl,
    required this.title,
    this.isVideo = false,
    this.authorText,
    this.timeAgo,
    this.viewsText,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> metaParts = _travelMetaParts(
        authorText: authorText, timeAgo: timeAgo, viewsText: viewsText);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SizedBox(
        height: 215.0,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomNetworkImage(
                networkImageUrl: imageUrl,
                width: double.maxFinite,
                height: 215.0,
                fit: BoxFit.cover,
                isVideo: isVideo),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: <double>[0.0, 0.8262],
                  colors: <Color>[Colors.transparent, Colors.black],
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
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomTextLabel(
                    text: title,
                    textStyle: const TextStyle(
                        fontSize: 16.0,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  if (metaParts.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4.0),
                    const Divider(height: 1.0, color: Colors.white24),
                    const SizedBox(height: 4.0),
                    _TravelMetaRow(
                        parts: metaParts,
                        hasAuthor: authorText?.trim().isNotEmpty == true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma "category wise card container": a bordered row with an 88x96
/// thumbnail on the left and a title + meta row on the right.
class _TravelRankedItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? authorText;
  final String? timeAgo;
  final String? viewsText;

  const _TravelRankedItem({
    required this.imageUrl,
    required this.title,
    this.authorText,
    this.timeAgo,
    this.viewsText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> metaParts = _travelMetaParts(
        authorText: authorText, timeAgo: timeAgo, viewsText: viewsText);
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? darkBorderDefaultColor : borderDefaultColor,
            width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: CustomNetworkImage(
                networkImageUrl: imageUrl,
                width: 88.0,
                height: 96.0,
                fit: BoxFit.cover),
          ),
          const SizedBox(width: 12.0),
          Expanded(
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
                      color: colorScheme.primaryContainer),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (metaParts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4.0),
                  Divider(
                      height: 1.0,
                      color:
                          isDark ? darkBorderDefaultColor : borderDefaultColor),
                  const SizedBox(height: 4.0),
                  _TravelMetaRow(
                      parts: metaParts,
                      hasAuthor: authorText?.trim().isNotEmpty == true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Style4Section extends StatelessWidget {
  final FeatureSectionModel model;

  const Style4Section({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return style4Data(model, context);
  }

  /// "4 minutes ago" — always relative, like the Figma "4 min ago" label.
  String? _timeAgo(BuildContext context, String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return null;
    try {
      return relativeTime(context, DateTime.parse(rawDate));
    } catch (_) {
      return null;
    }
  }

  /// "1K read". Nothing is shown for 0 (or a missing/unparsable value) so the
  /// row never reads "0 read".
  String? _viewsText(BuildContext context, String? rawViews) {
    final int views = int.tryParse(rawViews ?? '') ?? 0;
    if (views <= 0) return null;
    return "${compactCount(views)} ${UiUtils.getTranslatedLabel(context, 'read')}";
  }

  Widget style4SingleNewsData(FeatureSectionModel model, BuildContext context,
      {int index = 0}) {
    bool isRssFeedsNews =
        model.newsType == newsTypeToString(NewsType.rssFeedsNews);
    final RSSFeedModel rssData = (isRssFeedsNews)
        ? (model.rssFeedNews?[index] ?? RSSFeedModel())
        : RSSFeedModel();
    NewsModel data = (model.newsType == newsTypeToString(NewsType.news) ||
            model.newsType == newsTypeToString(NewsType.userChoice))
        ? (model.news ?? [])[index]
        : (model.newsType == newsTypeToString(NewsType.authorNews))
            ? (model.authorNews ?? [])[index]
            : (model.newsType == newsTypeToString(NewsType.videos))
                ? (model.videos ?? [])[index]
                : NewsModel();
    final bool isVideo = model.newsType == newsTypeToString(NewsType.videos);
    return InkWell(
      onTap: () async {
        // Open RSS feed links in external browser for RSS sections
        if (isRssFeedsNews &&
            rssData.feedUrl != null &&
            rssData.feedUrl!.isNotEmpty) {
          final uri = Uri.tryParse(rssData.feedUrl!);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          }
          return;
        }

        if (model.newsType == newsTypeToString(NewsType.news) ||
            model.newsType == newsTypeToString(NewsType.userChoice) ||
            model.newsType == newsTypeToString(NewsType.authorNews)) {
          //interstitial ads
          UiUtils.showInterstitialAds(context: context);
          List<NewsModel> newsList = [];
          newsList.addAll(
              model.newsType == newsTypeToString(NewsType.authorNews)
                  ? (model.authorNews ?? [])
                  : (model.news ?? []));
          newsList.removeAt(index);
          Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
            "model": data,
            "newsList": newsList,
            "isFromBreak": false,
            "fromShowMore": false
          });
        }
      },
      child: _TravelHero(
        imageUrl: isRssFeedsNews ? (rssData.image ?? "") : (data.image ?? ""),
        isVideo: isVideo,
        title: isRssFeedsNews ? rssData.feedName ?? "" : data.title ?? "",
        // RSS item: author + date. Any other item: date + read count.
        authorText: isRssFeedsNews ? rssData.author : null,
        timeAgo: isRssFeedsNews
            ? _timeAgo(context, rssData.pubDate ?? rssData.date)
            : _timeAgo(context, data.publishDate ?? data.date),
        viewsText:
            isRssFeedsNews ? null : _viewsText(context, data.totalViews),
        onPlayTap: isVideo
            ? () {
                List<NewsModel> allNewsList = List.from(model.videos ?? [])
                  ..removeWhere((item) => item.id == data.id);
                Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
                  "from": 1,
                  "model": data,
                  "otherVideos": allNewsList
                });
              }
            : null,
      ),
    );
  }

  Widget style4SingleBreakNewsData(
      FeatureSectionModel model, BuildContext context,
      {int index = 0}) {
    BreakingNewsModel data =
        model.newsType == newsTypeToString(NewsType.breakingNews)
            ? (model.breakNews ?? [])[index]
            : (model.breakVideos ?? [])[index];
    final bool isVideo = model.newsType == newsTypeToString(NewsType.videos);
    return InkWell(
      onTap: () {
        if (model.newsType == newsTypeToString(NewsType.breakingNews)) {
          //show interstitial ads
          UiUtils.showInterstitialAds(context: context);
          List<BreakingNewsModel> breakList = [];
          breakList.addAll(model.breakNews!);
          breakList.removeAt(index);
          Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
            "breakModel": data,
            "breakNewsList": breakList,
            "isFromBreak": true,
            "fromShowMore": false
          });
        }
      },
      child: _TravelHero(
        imageUrl: data.image ?? "",
        isVideo: isVideo,
        title: data.title ?? "",
        timeAgo: _timeAgo(context, data.date),
        viewsText: _viewsText(context, data.totalViews),
        onPlayTap: isVideo
            ? () {
                List<BreakingNewsModel> brNewsList =
                    List.from(model.breakVideos ?? [])
                      ..removeWhere((item) => item.id == data.id);
                Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
                  "from": 3,
                  "breakModel": data,
                  "otherBreakingVideos": brNewsList
                });
              }
            : null,
      ),
    );
  }

  Widget style4Data(FeatureSectionModel model, BuildContext context) {
    // Figma caps this layout at 1 hero card + 3 ranked cards (index 1-3),
    // unlike the horizontal-scroll styles that reuse limitOfAllOtherStyle.
    const int limit = 4;
    int newsLength = (model.newsType == newsTypeToString(NewsType.news) ||
            model.newsType == newsTypeToString(NewsType.userChoice))
        ? (model.news?.length ?? 0)
        : (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
            ? (model.rssFeedNews?.length ?? 0)
            : (model.newsType == newsTypeToString(NewsType.authorNews))
                ? (model.authorNews?.length ?? 0)
                : (model.videos?.length ?? 0);
    int brNewsLength = model.newsType == newsTypeToString(NewsType.breakingNews)
        ? (model.breakNews?.length ?? 0)
        : (model.breakVideos?.length ?? 0);

    if (model.breakVideos!.isNotEmpty ||
        model.breakNews!.isNotEmpty ||
        model.videos!.isNotEmpty ||
        model.news?.isNotEmpty == true ||
        model.authorNews?.isNotEmpty == true ||
        model.rssFeedNews?.isNotEmpty == true) {
      final bool isRssFeedsNews =
          model.newsType == newsTypeToString(NewsType.rssFeedsNews);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commonSectionTitle(model, context),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12.0,
            children: [
              if ((model.newsType == newsTypeToString(NewsType.news) ||
                          model.videosType == newsTypeToString(NewsType.news) ||
                          model.newsType ==
                              newsTypeToString(NewsType.userChoice) ||
                          model.newsType ==
                              newsTypeToString(NewsType.authorNews) ||
                          model.newsType ==
                              newsTypeToString(NewsType.rssFeedsNews)) &&
                      (model.newsType == newsTypeToString(NewsType.news) ||
                          model.newsType ==
                              newsTypeToString(NewsType.userChoice) ||
                          model.newsType ==
                              newsTypeToString(NewsType.authorNews) ||
                          model.newsType ==
                              newsTypeToString(NewsType.rssFeedsNews))
                  ? (isRssFeedsNews)
                      ? model.rssFeedNews?.isNotEmpty == true
                      : (model.newsType ==
                              newsTypeToString(NewsType.authorNews))
                          ? model.authorNews?.isNotEmpty == true
                          : model.news!.isNotEmpty
                  : model.videos!.isNotEmpty) ...<Widget>[
                style4SingleNewsData(model, context),
                for (int index = 1;
                    index < newsLength && index < limit;
                    index++)
                  Builder(builder: (context) {
                    bool isRss = model.newsType ==
                        newsTypeToString(NewsType.rssFeedsNews);
                    final RSSFeedModel rssData = (isRss)
                        ? (model.rssFeedNews?[index] ?? RSSFeedModel())
                        : RSSFeedModel();
                    NewsModel data =
                        (model.newsType == newsTypeToString(NewsType.news) ||
                                model.newsType ==
                                    newsTypeToString(NewsType.userChoice))
                            ? (model.news ?? [])[index]
                            : (model.newsType ==
                                    newsTypeToString(NewsType.authorNews))
                                ? (model.authorNews ?? [])[index]
                                : (model.newsType ==
                                        newsTypeToString(NewsType.videos))
                                    ? (model.videos ?? [])[index]
                                    : NewsModel();
                    return InkWell(
                      onTap: () async {
                        if (isRss &&
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
                      child: _TravelRankedItem(
                        imageUrl:
                            isRss ? rssData.image ?? "" : data.image ?? "",
                        title:
                            isRss ? rssData.feedName ?? "" : data.title ?? "",
                        authorText: isRss ? rssData.author : null,
                        timeAgo: isRss
                            ? _timeAgo(context, rssData.pubDate ?? rssData.date)
                            : _timeAgo(context, data.publishDate ?? data.date),
                        viewsText:
                            isRss ? null : _viewsText(context, data.totalViews),
                      ),
                    );
                  }),
              ],
              if ((model.newsType == newsTypeToString(NewsType.breakingNews) &&
                      model.breakNews?.isNotEmpty == true) ||
                  (model.videosType ==
                          newsTypeToString(NewsType.breakingNews) &&
                      model.breakVideos?.isNotEmpty == true)) ...<Widget>[
                style4SingleBreakNewsData(model, context),
                for (int index = 1;
                    index < brNewsLength && index < limit;
                    index++)
                  Builder(builder: (context) {
                    BreakingNewsModel data = model.newsType ==
                            newsTypeToString(NewsType.breakingNews)
                        ? (model.breakNews ?? [])[index]
                        : (model.breakVideos ?? [])[index];
                    return InkWell(
                      onTap: () {
                        if (model.newsType ==
                                newsTypeToString(NewsType.breakingNews) ||
                            model.videosType ==
                                newsTypeToString(NewsType.breakingNews)) {
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
                      child: _TravelRankedItem(
                        imageUrl: data.image ?? "",
                        title: data.title ?? "",
                        timeAgo: _timeAgo(context, data.date),
                        viewsText: _viewsText(context, data.totalViews),
                      ),
                    );
                  }),
              ],
            ],
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
