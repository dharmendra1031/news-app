import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/homepage/widgets/common_section_title.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// "11 Sep 2025" from the first of [publishDate] / [date] that parses —
/// `published_date` is null for many items, so the created date backs it up. A
/// value that is missing or not a date is skipped instead of throwing, so the
/// card just omits the date. RSS items send a UTC `published_at`, so the date
/// is shown in the device's timezone.
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

/// Figma "card container": image (with a top-right category tag) above a
/// title, then a meta row — author/date (RSS item) or calendar/date +
/// eye/views (any other item).
class _RecentNewsCard extends StatelessWidget {
  final String imageUrl;
  final bool isVideo;
  final String? categoryName;
  final String title;
  final String? authorText;
  final String? dateText;
  final String? viewsText;
  final VoidCallback? onPlayTap;

  const _RecentNewsCard({
    required this.imageUrl,
    required this.title,
    this.isVideo = false,
    this.categoryName,
    this.authorText,
    this.dateText,
    this.viewsText,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Text/Tertiary swaps values between light and dark.
    final Color metaColor = isDark ? textSecondaryColor : textTertiaryColor;
    final TextStyle metaStyle =
        TextStyle(fontSize: 12.0, height: 16 / 12, color: metaColor);
    final bool hasAuthor = authorText != null && authorText!.trim().isNotEmpty;
    // A count of 0 (or a missing/"null" value) hides the eye + count entirely.
    final bool hasViews = (int.tryParse(viewsText?.trim() ?? '') ?? 0) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
                Center(
                  child: InkWell(
                      onTap: onPlayTap,
                      child: UiUtils.setPlayButton(context: context)),
                ),
              if (categoryName != null && categoryName!.trim().isNotEmpty)
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  // Figma Background/Inverse + Text/Inverse Dark: #1E1E1E chip
                  // with white text in light, white chip with #101010 text in
                  // dark.
                  child: Container(
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
                          // which sat the label low in the chip.
                          leadingDistribution: TextLeadingDistribution.even,
                          fontWeight: FontWeight.w400,
                          color: isDark ? darkTextInverseColor : Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6.0),
        CustomTextLabel(
          text: title,
          textStyle: TextStyle(
              fontSize: 16.0,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
              color: UiUtils.getColorScheme(context).primaryContainer),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
        if (hasAuthor ||
            (dateText != null && dateText!.isNotEmpty) ||
            hasViews) ...<Widget>[
          const SizedBox(height: 6.0),
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
              if (hasAuthor && dateText != null && dateText!.isNotEmpty)
                const SizedBox(width: 8.0),
              if (dateText != null && dateText!.isNotEmpty) ...<Widget>[
                SvgPictureWidget(
                    assetName: "calendar_2",
                    height: 16.0,
                    width: 16.0,
                    assetColor: ColorFilter.mode(metaColor, BlendMode.srcIn)),
                const SizedBox(width: 4.0),
                CustomTextLabel(
                    text: dateText!,
                    textStyle: metaStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
              if (dateText != null && dateText!.isNotEmpty && hasViews)
                const SizedBox(width: 8.0),
              if (hasViews) ...<Widget>[
                SvgPictureWidget(
                    assetName: "eye_outline",
                    height: 16.0,
                    width: 16.0,
                    assetColor: ColorFilter.mode(metaColor, BlendMode.srcIn)),
                const SizedBox(width: 4.0),
                CustomTextLabel(
                    text: viewsText!,
                    textStyle: metaStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class Style3Section extends StatelessWidget {
  final FeatureSectionModel model;

  const Style3Section({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return style3Data(model, context);
  }

  Widget style3Data(FeatureSectionModel model, BuildContext context) {
    // Figma shows exactly 3 stacked cards in this section, unlike the
    // horizontal-scroll styles that reuse limitOfAllOtherStyle. This only caps
    // how many cards are drawn on the home feed — the API data in [model] is
    // untouched and "View More" still opens the full list.
    const int limit = 3;
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
      final bool isVideo =
          model.newsType == newsTypeToString(NewsType.videos) ||
              model.videosType == newsTypeToString(NewsType.videos);
      final bool showBreaking = (model.newsType ==
                  newsTypeToString(NewsType.breakingNews) ||
              model.videosType == newsTypeToString(NewsType.breakingNews)) &&
          (model.newsType == newsTypeToString(NewsType.breakingNews)
              ? model.breakNews?.isNotEmpty == true
              : model.breakVideos?.isNotEmpty == true);
      final bool showRegular = (model.newsType ==
                  newsTypeToString(NewsType.news) ||
              model.videosType == newsTypeToString(NewsType.news) ||
              model.newsType == newsTypeToString(NewsType.userChoice) ||
              model.newsType == newsTypeToString(NewsType.authorNews) ||
              model.newsType == newsTypeToString(NewsType.rssFeedsNews)) &&
          ((model.newsType == newsTypeToString(NewsType.news) ||
                  model.newsType == newsTypeToString(NewsType.userChoice) ||
                  model.newsType == newsTypeToString(NewsType.authorNews) ||
                  model.newsType == newsTypeToString(NewsType.rssFeedsNews))
              ? (model.newsType == newsTypeToString(NewsType.rssFeedsNews))
                  ? model.rssFeedNews?.isNotEmpty == true
                  : (model.newsType == newsTypeToString(NewsType.authorNews))
                      ? model.authorNews?.isNotEmpty == true
                      : model.news?.isNotEmpty == true
              : model.videos?.isNotEmpty == true);

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          commonSectionTitle(model, context),
          if (showBreaking)
            ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(brNewsLength, limit),
                separatorBuilder: (_, __) => const SizedBox(height: 20.0),
                itemBuilder: (BuildContext context, int index) {
                  BreakingNewsModel data =
                      model.newsType == newsTypeToString(NewsType.breakingNews)
                          ? (model.breakNews ?? [])[index]
                          : (model.breakVideos ?? [])[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if ((index != 0 && index % nativeAdsIndex == 0) &&
                          context
                                  .read<AppConfigurationCubit>()
                                  .getInAppAdsMode() ==
                              "1" &&
                          (context.read<AppConfigurationCubit>().getAdsType() !=
                                  "unity" ||
                              context
                                      .read<AppConfigurationCubit>()
                                      .getIOSAdsType() !=
                                  "unity"))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: nativeAdsShow(context: context, index: index),
                        ),
                      InkWell(
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
                        child: _RecentNewsCard(
                          imageUrl: data.image ?? "",
                          isVideo: isVideo,
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
                      ),
                    ],
                  );
                }),
          if (showRegular)
            ListView.separated(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: min(newsLength, limit),
                shrinkWrap: true,
                separatorBuilder: (_, __) => const SizedBox(height: 20.0),
                itemBuilder: (BuildContext context, int index) {
                  bool isRssFeedsNews =
                      model.newsType == newsTypeToString(NewsType.rssFeedsNews);

                  NewsModel data =
                      (model.newsType == newsTypeToString(NewsType.news) ||
                              model.newsType ==
                                  newsTypeToString(NewsType.userChoice))
                          ? (model.news ?? [])[index]
                          : (isRssFeedsNews)
                              ? NewsModel()
                              : (model.newsType ==
                                      newsTypeToString(NewsType.authorNews))
                                  ? (model.authorNews ?? [])[index]
                                  : (model.videos ?? [])[index];
                  final RSSFeedModel rssData = (model.newsType ==
                          newsTypeToString(NewsType.rssFeedsNews))
                      ? (model.rssFeedNews?[index] ?? RSSFeedModel())
                      : RSSFeedModel();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if ((index != 0 && index % nativeAdsIndex == 0) &&
                          context
                                  .read<AppConfigurationCubit>()
                                  .getInAppAdsMode() ==
                              "1" &&
                          (context.read<AppConfigurationCubit>().getAdsType() !=
                                  "unity" ||
                              context
                                      .read<AppConfigurationCubit>()
                                      .getIOSAdsType() !=
                                  "unity"))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: nativeAdsShow(context: context, index: index),
                        ),
                      InkWell(
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

                          if (model.newsType ==
                                  newsTypeToString(NewsType.news) ||
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
                        child: _RecentNewsCard(
                          imageUrl: isRssFeedsNews
                              ? rssData.image ?? ""
                              : data.image ?? "",
                          isVideo: isVideo,
                          categoryName:
                              isRssFeedsNews ? null : data.categoryName,
                          title: isRssFeedsNews
                              ? rssData.feedName ?? ""
                              : data.title ?? "",
                          // RSS item: author + date. Any other item: date +
                          // read count.
                          authorText: isRssFeedsNews ? rssData.author : null,
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
                      ),
                    ],
                  );
                }),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
