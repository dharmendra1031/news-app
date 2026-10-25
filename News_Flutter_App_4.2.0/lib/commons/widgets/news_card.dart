import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class NewsCard extends StatefulWidget {
  NewsModel newsDetail;
  bool showViews;
  bool showTags;

  /// Meta row like the home section cards: the date as "11 Sep 2025" (not the
  /// full "September 11,2025") followed by the eye icon and view count. Unlike
  /// [showViews], this does not add the bookmark overlay.
  bool homeMeta;
  Function()? onTap;
  NewsCard(
      {super.key,
      required this.newsDetail,
      this.showViews = false,
      this.showTags = false,
      this.homeMeta = false,
      required this.onTap});

  @override
  State<NewsCard> createState() => NewsCardState();
}

class NewsCardState extends State<NewsCard> {
  List<String> tagList = [];
  List<String> tagId = [];
  late NewsModel newsData;

  @override
  void initState() {
    super.initState();

    newsData = widget.newsDetail;

    if (newsData.tagName! != "") {
      final tagName = newsData.tagName!;
      tagList = tagName.split(',');
    }

    if (newsData.tagId != null && newsData.tagId! != "") {
      tagId = newsData.tagId!.split(",");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: UiUtils.getColorScheme(context).surface,
          borderRadius: BorderRadius.circular(8)),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [setImage(), setContent()],
            ),
            (widget.showViews) ? setBookmarkIconButton() : SizedBox.shrink()
          ],
        ),
      ),
    );
  }

  Widget setContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          //title
          CustomTextLabel(
              text: widget.newsDetail.title!,
              textStyle: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            spacing: 10,
            children: [
              (widget.newsDetail.date != null &&
                      widget.newsDetail.date!.isNotEmpty)
                  ? setDate()
                  : SizedBox.shrink(),
              if (widget.showViews)
                setViews()
              else if (widget.homeMeta)
                setHomeViews()
            ],
          ),
        ],
      ),
    );
  }

  Widget setBookmarkIconButton() {
    return BlocListener<UpdateBookmarkStatusCubit, UpdateBookmarkStatusState>(
      listener: (context, state) {
        if (state is UpdateBookmarkStatusSuccess) {
          context.read<BookmarkCubit>().getBookmark(
              langCode:
                  context.read<AppLocalizationCubit>().state.languageCode);
        }
      },
      child: Positioned.directional(
          textDirection: Directionality.of(context),
          end: 10,
          top: 10,
          child: GestureDetector(
              onTap: () {
                context
                    .read<UpdateBookmarkStatusCubit>()
                    .setBookmarkNews(news: widget.newsDetail, status: "0");
              },
              child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      color: UiUtils.getColorScheme(context).surface),
                  child: Icon(Icons.bookmark_outlined,
                      color: UiUtils.getColorScheme(context).onPrimary,
                      size: 20)))),
    );
  }

  Widget setViews() {
    // FIGMA(1592-5532): date/view meta row is white@70% (#ffffffb2) in dark.
    // primaryContainer = white in dark / navy in light, so .withOpacity(0.7)
    // matches the design on both themes.
    final metaColor =
        UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7);
    return Row(spacing: 8, children: [
      Icon(Icons.remove_red_eye_rounded, size: 20, color: metaColor),
      CustomTextLabel(
          text:
              "${widget.newsDetail.totalViews} ${UiUtils.getTranslatedLabel(context, 'viewsLbl')}",
          textStyle: TextStyle(fontSize: 12, color: metaColor))
    ]);
  }

  /// Eye icon + the plain view count, as on the home section cards. Hidden when
  /// the count is missing.
  Widget setHomeViews() {
    final String views = widget.newsDetail.totalViews?.trim() ?? '';
    if (views.isEmpty || views == 'null') return const SizedBox.shrink();
    final metaColor =
        UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7);
    return Row(spacing: 8, children: [
      SvgPictureWidget(
          assetName: 'eye_outline',
          height: 20,
          width: 20,
          assetColor: ColorFilter.mode(metaColor, BlendMode.srcIn)),
      CustomTextLabel(
          text: views,
          textStyle: TextStyle(
              fontSize: 12, color: metaColor, fontWeight: FontWeight.w400))
    ]);
  }

  /// "11 Sep 2025" from the first of `publishDate` / `date` that parses, in the
  /// device's timezone — the same as the home section cards. Falls back to the
  /// full date when [NewsCard.homeMeta] is off.
  String dateText() {
    if (widget.homeMeta) {
      for (final String? raw in <String?>[
        widget.newsDetail.publishDate,
        widget.newsDetail.date
      ]) {
        final DateTime? parsed =
            (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
        if (parsed != null) {
          return DateFormat('d MMM yyyy').format(parsed.toLocal());
        }
      }
    }
    return UiUtils.formatDate(widget.newsDetail.date ?? '');
  }

  Widget setDate() {
    final metaColor =
        UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7);
    return Row(
      spacing: 8,
      children: [
        SvgPictureWidget(
            assetName: 'calendar',
            height: 20,
            width: 20,
            assetColor: ColorFilter.mode(metaColor, BlendMode.srcIn)),
        CustomTextLabel(
            text: dateText(),
            textStyle: TextStyle(
                fontSize: 12, color: metaColor, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget setTags() {
    return Positioned.directional(
        textDirection: Directionality.of(context),
        bottom: 15.0,
        start: 7.0,
        child: widget.newsDetail.tagName! != ""
            ? SizedBox(
                height: 30.0,
                child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: tagList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                            start: index == 0 ? 0 : 5.5),
                        child: InkWell(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  height: 25.0,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 7.0,
                                      end: 7.0,
                                      top: 1.0,
                                      bottom: 1.0),
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(15)),
                                      color: UiUtils.getColorScheme(context)
                                          .secondary
                                          .withOpacity(0.85)),
                                  child: CustomTextLabel(
                                      text: tagList[index],
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: UiUtils.getColorScheme(
                                                      context)
                                                  .primaryContainer,
                                              fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true)),
                            ],
                          ),
                          onTap: () async {
                            if (index >= tagId.length || tagId[index].isEmpty)
                              return;
                            Navigator.of(context).pushNamed(Routes.tagScreen,
                                arguments: {
                                  "tagId": tagId[index],
                                  "tagName": tagList[index]
                                });
                          },
                        ),
                      );
                    }))
            : const SizedBox.shrink());
  }

  Widget setImage() {
    return Stack(
      children: [
        Container(
            height: 192,
            color: borderColor,
            child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          darkSecondaryColor.withOpacity(0.6),
                          darkSecondaryColor.withOpacity(0.6)
                        ]).createShader(rect),
                blendMode: BlendMode.darken,
                child: Container(
                  color: primaryColor.withAlpha(5),
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height / 3.3,
                  child: CustomNetworkImage(
                      width: double.maxFinite,
                      networkImageUrl: widget.newsDetail.image ?? ''),
                ))),
        //tags
        if (widget.showTags) setTags()
      ],
    );
  }
}
