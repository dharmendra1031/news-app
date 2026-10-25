import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/homepage/cubits/general_news_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/utils/ui_utils.dart';

/// Figma "card container": title, then a calendar/date + eye/views meta
/// row, then a 156px image (with a top-right category tag), then a
/// description paragraph. Cards are separated by a divider.
class _LatestNewsCard extends StatelessWidget {
  final String imageUrl;
  final bool isVideo;
  final String? categoryName;
  final String title;
  final String? dateText;
  final String? viewsText;
  final String? description;
  final VoidCallback? onPlayTap;

  const _LatestNewsCard({
    required this.imageUrl,
    required this.title,
    this.isVideo = false,
    this.categoryName,
    this.dateText,
    this.viewsText,
    this.description,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    // A count of 0 (or a missing/"null" value) hides the eye + count entirely.
    final bool hasViews = (int.tryParse(viewsText?.trim() ?? '') ?? 0) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
        if ((dateText != null && dateText!.isNotEmpty) ||
            hasViews) ...<Widget>[
          const SizedBox(height: 6.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (dateText != null && dateText!.isNotEmpty) ...<Widget>[
                SvgPictureWidget(
                    assetName: "calendar_2",
                    height: 16.0,
                    width: 16.0,
                    assetColor: const ColorFilter.mode(
                        textTertiaryColor, BlendMode.srcIn)),
                const SizedBox(width: 4.0),
                CustomTextLabel(
                    text: dateText!,
                    textStyle: const TextStyle(
                        fontSize: 12.0,
                        height: 16 / 12,
                        color: textTertiaryColor),
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
                    assetColor: const ColorFilter.mode(
                        textTertiaryColor, BlendMode.srcIn)),
                const SizedBox(width: 4.0),
                CustomTextLabel(
                    text: viewsText!,
                    textStyle: const TextStyle(
                        fontSize: 12.0,
                        height: 16 / 12,
                        color: textTertiaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ],
        const SizedBox(height: 6.0),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e1e1e),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: CustomTextLabel(
                      text: categoryName!,
                      textStyle: const TextStyle(
                          fontSize: 12.0,
                          height: 16 / 12,
                          // Figma centres the glyphs in the 16px line; Flutter's
                          // default weights the spare space toward the top,
                          // which sat the label low in the chip.
                          leadingDistribution: TextLeadingDistribution.even,
                          fontWeight: FontWeight.w400,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (description != null && description!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6.0),
          CustomTextLabel(
            text: description!,
            textStyle: const TextStyle(
                fontSize: 12.0, height: 16 / 12, color: textSecondaryColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ],
      ],
    );
  }
}

class GeneralNewsRandomStyle extends StatefulWidget {
  final List<NewsModel> modelList;

  const GeneralNewsRandomStyle({super.key, required this.modelList});

  @override
  GeneralNewsRandomStyleState createState() => GeneralNewsRandomStyleState();
}

class GeneralNewsRandomStyleState extends State<GeneralNewsRandomStyle> {
  late final ScrollController scrollController = ScrollController()
    ..addListener(hasMoreGeneralNewsListener);
  late List<NewsModel> newsList;

  @override
  void initState() {
    super.initState();
    newsList = widget.modelList;
  }

  @override
  void dispose() {
    scrollController.removeListener(() {});
    super.dispose();
  }

  void hasMoreGeneralNewsListener() {
    if (scrollController.position.maxScrollExtent == scrollController.offset) {
      if (context.read<GeneralNewsCubit>().hasMoreGeneralNews()) {
        context.read<GeneralNewsCubit>().getMoreGeneralNews(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            latitude:
                SettingsLocalDataRepository().getLocationCityValues().first,
            longitude:
                SettingsLocalDataRepository().getLocationCityValues().last);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CustomTextLabel(
                text: 'latestNews',
                textStyle: TextStyle(
                    fontSize: 20.0,
                    height: 28 / 20,
                    fontWeight: FontWeight.w600,
                    color: UiUtils.getColorScheme(context).primaryContainer)),
            const CustomTextLabel(
                text: 'viewMore',
                textStyle: TextStyle(
                    fontSize: 14.0,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor)),
          ],
        ),
        const SizedBox(height: 12.0),
        ListView.separated(
          controller: scrollController,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: newsList.length,
          separatorBuilder: (BuildContext context, int index) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1.0, color: borderDefaultColor)),
          itemBuilder: (BuildContext context, int index) => listRow(index),
        ),
      ],
    );
  }

  Widget listRow(int index) {
    NewsModel newsModel = newsList[index];
    final bool isVideo = newsModel.type == 'videos';
    String? dateText;
    if (newsModel.date != null && newsModel.date!.isNotEmpty) {
      try {
        dateText = UiUtils.formatDate(newsModel.date!);
      } catch (_) {
        dateText = null;
      }
    }
    return GestureDetector(
      onTap: () {
        List<NewsModel> newList = [];
        newList.addAll(newsList);
        newList.removeAt(index);
        Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
          "model": newsModel,
          "newsList": newList,
          "isFromBreak": false,
          "fromShowMore": false
        });
      },
      child: _LatestNewsCard(
        imageUrl: newsModel.image ?? "",
        isVideo: isVideo,
        categoryName: newsModel.categoryName,
        title: newsModel.title ?? "",
        dateText: dateText,
        viewsText: newsModel.totalViews,
        description: newsModel.shortDesc ?? newsModel.desc,
        onPlayTap: isVideo
            ? () {
                List<NewsModel> allNewsList = List.from(newsList)
                  ..removeAt(index);
                Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
                  "from": 1,
                  "model": newsModel,
                  "otherVideos": allNewsList
                });
              }
            : null,
      ),
    );
  }
}
