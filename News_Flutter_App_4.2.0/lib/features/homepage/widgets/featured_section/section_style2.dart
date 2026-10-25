import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/homepage/widgets/common_section_title.dart';
import 'package:news/features/homepage/widgets/featured_section/section_meta_format.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Figma "News Item": a small square thumbnail beside a title, with a
/// "author • time ago" (RSS item) or "time ago • views" (any other item) meta
/// row underneath, inset by the item's 2px padding.
class _TrendingListItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? authorText;
  final String? timeAgo;
  final String? viewsText;

  const _TrendingListItem({
    required this.imageUrl,
    required this.title,
    this.authorText,
    this.timeAgo,
    this.viewsText,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Text/Secondary is #676767 in light and #A0A0A0 in dark; Icon/Secondary is
    // #676767 in light and #CECECE in dark.
    final Color metaColor = isDark ? textTertiaryColor : textSecondaryColor;
    final Color dotColor = isDark ? darkIconSecondaryColor : textSecondaryColor;
    final TextStyle metaStyle =
        TextStyle(fontSize: 12.0, height: 16 / 12, color: metaColor);
    final bool hasAuthor = authorText != null && authorText!.trim().isNotEmpty;
    final List<String> metaParts = <String>[
      if (hasAuthor) authorText!,
      if (timeAgo != null && timeAgo!.isNotEmpty) timeAgo!,
      if (viewsText != null && viewsText!.isNotEmpty) viewsText!,
    ];

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: CustomNetworkImage(
                networkImageUrl: imageUrl,
                width: 78.0,
                height: 78.0,
                fit: BoxFit.cover),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CustomTextLabel(
                  text: title,
                  textStyle: TextStyle(
                      fontSize: 14.0,
                      height: 1.55,
                      letterSpacing: -0.28,
                      fontWeight: FontWeight.w500,
                      color: UiUtils.getColorScheme(context).primaryContainer),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                if (metaParts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < metaParts.length; i++) ...<Widget>[
                        if (i > 0) ...<Widget>[
                          const SizedBox(width: 6.0),
                          Container(
                            width: 5.0,
                            height: 5.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: dotColor),
                          ),
                          const SizedBox(width: 6.0),
                        ],
                        // With an author only the author shrinks, so it takes
                        // the room the date leaves.
                        if (hasAuthor && i > 0)
                          CustomTextLabel(
                              text: metaParts[i],
                              textStyle: metaStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                        else
                          Flexible(
                            child: CustomTextLabel(
                                text: metaParts[i],
                                textStyle: metaStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma "Line 108": a 1px Border/Muted line between "News Item" rows. It is
/// drawn 7px under the previous row with 8px below it (16px in all) and is
/// 354px wide, i.e. 4px short of the 358px row. Border/Muted is #EFEFEF in
/// light mode and #1E1E1E (the surface colour) in dark, so the line only shows
/// up in light mode, exactly as in the design.
class _TrendingDivider extends StatelessWidget {
  const _TrendingDivider();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding:
          const EdgeInsetsDirectional.only(top: 7.0, end: 4.0, bottom: 8.0),
      child: Divider(
          height: 1.0,
          thickness: 1.0,
          color: isDark ? darkBackgroundColor : backgroundColor),
    );
  }
}

class Style2Section extends StatelessWidget {
  final FeatureSectionModel model;
  bool isNews = true;

  Style2Section({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return style2Data(model, context);
  }

  Widget style2Data(FeatureSectionModel model, BuildContext context) {
    if (model.breakVideos!.isNotEmpty ||
        model.breakNews!.isNotEmpty ||
        model.videos!.isNotEmpty ||
        model.news?.isNotEmpty == true ||
        model.authorNews?.isNotEmpty == true ||
        (model.rssFeedNews != null && model.rssFeedNews!.isNotEmpty)) {
      final bool isRegularNewsType =
          model.newsType == newsTypeToString(NewsType.news) ||
              model.newsType == newsTypeToString(NewsType.userChoice) ||
              model.newsType == newsTypeToString(NewsType.authorNews) ||
              model.newsType == newsTypeToString(NewsType.rssFeedsNews) ||
              model.videosType == newsTypeToString(NewsType.news);

      final bool hasRegularNewsData = model.newsType ==
              newsTypeToString(NewsType.rssFeedsNews)
          ? model.rssFeedNews?.isNotEmpty == true
          : model.newsType == newsTypeToString(NewsType.authorNews)
              ? model.authorNews?.isNotEmpty == true
              : (model.newsType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice))
                  ? model.news?.isNotEmpty == true
                  : model.videos?.isNotEmpty == true;

      final bool isBreakingNewsType =
          model.newsType == newsTypeToString(NewsType.breakingNews) ||
              model.videosType == newsTypeToString(NewsType.breakingNews);

      final bool hasBreakingNewsData =
          model.newsType == newsTypeToString(NewsType.breakingNews)
              ? model.breakNews?.isNotEmpty == true
              : model.breakVideos?.isNotEmpty == true;

      if (isRegularNewsType && hasRegularNewsData) isNews = true;

      if (isBreakingNewsType && hasBreakingNewsData) isNews = false;

      // Figma shows exactly 4 "News Item" rows in this section, unlike the
      // horizontal-scroll styles that reuse limitOfAllOtherStyle. This only caps
      // how many rows are drawn on the home feed — the API data in [model] is
      // untouched and "View More" still opens the full list.
      const int limit = 4;
      final List items = model.newsType ==
              newsTypeToString(NewsType.rssFeedsNews)
          ? model.rssFeedNews!
          : model.newsType == newsTypeToString(NewsType.authorNews)
              ? (model.authorNews ?? [])
              : (model.newsType == newsTypeToString(NewsType.news) ||
                      model.newsType == newsTypeToString(NewsType.userChoice))
                  ? model.news!
                  : model.videos!;

      final int newsLength = items.length;

      int brNewsLength =
          model.newsType == newsTypeToString(NewsType.breakingNews)
              ? model.breakNews!.length
              : model.breakVideos!.length;

      var totalCount = (isNews)
          ? (newsLength < limit ? newsLength : limit)
          : (brNewsLength < limit ? brNewsLength : limit);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          commonSectionTitle(model, context),
          ListView.separated(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: totalCount,
              separatorBuilder: (_, __) => const _TrendingDivider(),
              itemBuilder: (context, index) {
                if (isNews) {
                  if (model.newsType ==
                      newsTypeToString(NewsType.rssFeedsNews)) {
                    return setStyle2(
                        context: context,
                        index: index,
                        model: model,
                        rssFeedModel: model.rssFeedNews![index]);
                  } else {
                    final items =
                        (model.newsType == newsTypeToString(NewsType.news) ||
                                model.newsType ==
                                    newsTypeToString(NewsType.userChoice))
                            ? model.news!
                            : model.videos!;
                    final authorItems =
                        model.newsType == newsTypeToString(NewsType.authorNews)
                            ? (model.authorNews ?? [])
                            : [];

                    final item =
                        model.newsType == newsTypeToString(NewsType.authorNews)
                            ? authorItems[index]
                            : items[index];
                    return setStyle2(
                        context: context,
                        index: index,
                        model: model,
                        newsModel: item);
                  }
                } else {
                  return setStyle2(
                      context: context,
                      index: index,
                      model: model,
                      breakingNewsModel: (model.newsType ==
                              newsTypeToString(NewsType.breakingNews))
                          ? model.breakNews![index]
                          : model.breakVideos![index]);
                }
              })
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget setStyle2(
      {required BuildContext context,
      required int index,
      required FeatureSectionModel model,
      NewsModel? newsModel,
      BreakingNewsModel? breakingNewsModel,
      RSSFeedModel? rssFeedModel}) {
    // Breaking news/videos carry their date in `date` (mapped from the API's
    // `created_at`) and their view count in `totalViews`, same as news.
    final String? rawDate = (rssFeedModel != null)
        ? (rssFeedModel.pubDate ?? rssFeedModel.date)
        : (newsModel != null)
            ? (newsModel.publishDate ?? newsModel.date)
            : breakingNewsModel?.date;
    String? timeAgo;
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        timeAgo = relativeTime(context, DateTime.parse(rawDate));
      } catch (_) {
        timeAgo = null;
      }
    }
    // RSS item (`news_type` is `rss_feeds_news`): author + date, no read
    // count. Any other item: date + read count, no author.
    final bool isRssFeed =
        model.newsType == newsTypeToString(NewsType.rssFeedsNews);
    // Nothing is shown for 0 (or an unparsable value) so the row never reads
    // "0 read".
    final String? rawViews = (newsModel != null)
        ? newsModel.totalViews
        : breakingNewsModel?.totalViews;
    final int views = int.tryParse(rawViews ?? '') ?? 0;
    final String? viewsText = (!isRssFeed && views > 0)
        ? "${compactCount(views)} ${UiUtils.getTranslatedLabel(context, 'read')}"
        : null;

    return Column(
      children: [
        if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1" &&
            (context.read<AppConfigurationCubit>().getAdsType() != "unity" ||
                context.read<AppConfigurationCubit>().getIOSAdsType() !=
                    "unity"))
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: nativeAdsShow(context: context, index: index),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () async {
            // If RSS feed section, open link in external browser
            if (model.newsType == newsTypeToString(NewsType.rssFeedsNews) &&
                rssFeedModel != null &&
                rssFeedModel.feedUrl != null &&
                rssFeedModel.feedUrl!.isNotEmpty) {
              final uri = Uri.tryParse(rssFeedModel.feedUrl!);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
              }
              return;
            }

            //interstitial ads
            UiUtils.showInterstitialAds(context: context);
            if (model.newsType == newsTypeToString(NewsType.news) ||
                model.newsType == newsTypeToString(NewsType.userChoice) ||
                model.newsType == newsTypeToString(NewsType.authorNews)) {
              List<NewsModel> newsList = [];
              newsList.addAll(
                  model.newsType == newsTypeToString(NewsType.authorNews)
                      ? (model.authorNews ?? [])
                      : (model.news ?? []));
              newsList.removeAt(index);
              Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                "model": newsModel,
                "newsList": newsList,
                "isFromBreak": false,
                "fromShowMore": false
              });
            } else if (model.newsType ==
                newsTypeToString(NewsType.breakingNews)) {
              List<BreakingNewsModel> breakList = [];
              breakList.addAll(model.breakNews!);
              breakList.removeAt(index);
              Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                "breakModel": breakingNewsModel,
                "breakNewsList": breakList,
                "isFromBreak": true,
                "fromShowMore": false
              });
            }
          },
          child: _TrendingListItem(
            imageUrl: (rssFeedModel != null)
                ? rssFeedModel.image ?? ""
                : (newsModel != null)
                    ? newsModel.image ?? ""
                    : breakingNewsModel!.image ?? "",
            title: (rssFeedModel != null)
                ? rssFeedModel.feedName ?? ""
                : (newsModel != null)
                    ? newsModel.title ?? ""
                    : breakingNewsModel!.title ?? "",
            authorText: isRssFeed ? rssFeedModel?.author : null,
            timeAgo: timeAgo,
            viewsText: viewsText,
          ),
        ),
      ],
    );
  }
}
