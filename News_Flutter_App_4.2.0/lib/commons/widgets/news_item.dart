import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/news_card.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/like_and_dislike_news/like_and_dislike_news_repository.dart';

class NewsItem extends StatefulWidget {
  final NewsModel model;
  final int index;
  final List<NewsModel> newslist;
  final bool fromShowMore;

  /// Passed to [NewsCard.homeMeta].
  final bool homeMeta;

  const NewsItem(
      {super.key,
      required this.model,
      required this.index,
      required this.newslist,
      required this.fromShowMore,
      this.homeMeta = false});

  @override
  NewsItemState createState() => NewsItemState();
}

class NewsItemState extends State<NewsItem> {
  late BannerAd bannerAd;

  @override
  void initState() {
    super.initState();
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1" &&
        (context.read<AppConfigurationCubit>().getAdsType() != "unity" ||
            context.read<AppConfigurationCubit>().getIOSAdsType() != "unity"))
      bannerAd = UiUtils.createBannerAd(context: context);
  }

  Widget setButton({required Widget childWidget}) {
    return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: UiUtils.getColorScheme(context).secondary),
        child: childWidget);
  }

  Widget setNewsImage() {
    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ShaderMask(
            shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      darkSecondaryColor.withOpacity(0.9)
                    ]).createShader(rect),
            blendMode: BlendMode.darken,
            child: Container(
                color: primaryColor.withAlpha(5),
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height / 3.3,
                child: CustomNetworkImage(
                    networkImageUrl: widget.model.image!,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height / 4.2,
                    fit: BoxFit.cover,
                    isVideo: false))));
  }

  Widget setTagsList(
      {required List<String> tagList, required List<String> tagId}) {
    return Positioned.directional(
        textDirection: Directionality.of(context),
        bottom: 80.0,
        start: 7.0,
        child: widget.model.tagName! != ""
            ? SizedBox(
                height: 16.0,
                child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: tagList.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                            start: index == 0 ? 0 : 5.5),
                        child: InkWell(
                          child: Container(
                              height: 20.0,
                              width: 65,
                              alignment: Alignment.center,
                              padding: const EdgeInsetsDirectional.only(
                                  start: 3.0, end: 3.0, top: 1.0, bottom: 1.0),
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(10.0),
                                      topRight: Radius.circular(10.0)),
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer
                                      .withOpacity(0.85)),
                              child: CustomTextLabel(
                                  text: tagList[index],
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .secondary,
                                          fontSize: 8.5),
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true)),
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

  Widget setTitleAndDate() {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      bottom: 20,
      start: 10,
      end: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsetsDirectional.only(
                  top: 4.0, start: 5.0, end: 5.0),
              child: CustomTextLabel(
                  text: widget.model.title!,
                  textStyle: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: secondaryColor),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis)),
          Padding(
              padding: const EdgeInsetsDirectional.only(
                  top: 4.0, start: 5.0, end: 5.0),
              child: CustomTextLabel(
                  text: UiUtils.convertToAgo(
                      context,
                      DateTime.parse(
                          widget.model.publishDate ?? widget.model.date!),
                      0)!,
                  textStyle: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: secondaryColor.withOpacity(0.6)))),
        ],
      ),
    );
  }

  Widget shareButton() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 13.0),
      child: InkWell(
        child:
            setButton(childWidget: const Icon(Icons.share_rounded, size: 20)),
        onTap: () async {
          if (await InternetConnectivity.isNetworkAvailable()) {
            UiUtils.shareNews(
                context: context,
                slug: widget.model.slug!,
                title: widget.model.title!,
                isVideo: false,
                isReels: false,
                videoId: "",
                isBreakingNews: false,
                isNews: true);
          } else {
            showSnackBar(
                UiUtils.getTranslatedLabel(context, 'internetmsg'), context);
          }
        },
      ),
    );
  }

  Widget bookmarkButton() {
    return BlocProvider(
      create: (context) => UpdateBookmarkStatusCubit(BookmarkRepository()),
      child: BlocBuilder<BookmarkCubit, BookmarkState>(
          bloc: context.read<BookmarkCubit>(),
          builder: (context, bookmarkState) {
            bool isBookmark =
                context.read<BookmarkCubit>().isNewsBookmark(widget.model.id!);
            return BlocConsumer<UpdateBookmarkStatusCubit,
                    UpdateBookmarkStatusState>(
                bloc: context.read<UpdateBookmarkStatusCubit>(),
                listener: ((context, state) {
                  if (state is UpdateBookmarkStatusSuccess) {
                    (state.wasBookmarkNewsProcess)
                        ? context
                            .read<BookmarkCubit>()
                            .addBookmarkNews(state.news)
                        : context
                            .read<BookmarkCubit>()
                            .removeBookmarkNews(state.news);
                  }
                }),
                builder: (context, state) {
                  return InkWell(
                      onTap: () {
                        if (context.read<AuthCubit>().getUserId() != "0") {
                          if (state is UpdateBookmarkStatusInProgress) return;
                          context
                              .read<UpdateBookmarkStatusCubit>()
                              .setBookmarkNews(
                                  news: widget.model,
                                  status: (isBookmark) ? "0" : "1");
                        } else {
                          UiUtils.loginRequired(context);
                        }
                      },
                      child: setButton(
                          childWidget: (state is UpdateBookmarkStatusInProgress)
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: UiUtils.showCircularProgress(
                                      true, Theme.of(context).primaryColor))
                              : ((isBookmark)
                                  ? const Icon(Icons.bookmark_added_rounded,
                                      size: 20)
                                  : const Icon(Icons.bookmark_add_outlined,
                                      size: 20))));
                });
          }),
    );
  }

  Widget likeButton() {
    bool isLike = context
        .read<LikeAndDisLikeCubit>()
        .isNewsLikeAndDisLike(widget.model.id!);

    return BlocProvider(
        create: (context) =>
            UpdateLikeAndDisLikeStatusCubit(LikeAndDisLikeRepository()),
        child: BlocConsumer<LikeAndDisLikeCubit, LikeAndDisLikeState>(
            bloc: context.read<LikeAndDisLikeCubit>(),
            listener: ((context, state) {
              if (state is LikeAndDisLikeFetchSuccess) {
                isLike = context
                    .read<LikeAndDisLikeCubit>()
                    .isNewsLikeAndDisLike(widget.model.id!);
              }
            }),
            builder: (context, likeAndDislikeState) {
              return BlocConsumer<UpdateLikeAndDisLikeStatusCubit,
                      UpdateLikeAndDisLikeStatusState>(
                  bloc: context.read<UpdateLikeAndDisLikeStatusCubit>(),
                  listener: ((context, state) {
                    if (state is UpdateLikeAndDisLikeStatusSuccess) {
                      context.read<LikeAndDisLikeCubit>().getLike(
                          langCode: context
                              .read<AppLocalizationCubit>()
                              .state
                              .languageCode);
                      widget.model.totalLikes = (!isLike)
                          ? (int.parse(widget.model.totalLikes.toString()) + 1)
                              .toString()
                          : (widget.model.totalLikes!.isNotEmpty)
                              ? (int.parse(widget.model.totalLikes.toString()) -
                                      1)
                                  .toString()
                              : "0";
                    }
                  }),
                  builder: (context, state) {
                    return InkWell(
                        splashColor: Colors.transparent,
                        onTap: () {
                          if (context.read<AuthCubit>().getUserId() != "0") {
                            if (state is UpdateLikeAndDisLikeStatusInProgress) {
                              return;
                            }
                            context
                                .read<UpdateLikeAndDisLikeStatusCubit>()
                                .setLikeAndDisLikeNews(
                                    news: widget.model,
                                    status: (isLike) ? "0" : "1");
                          } else {
                            UiUtils.loginRequired(context);
                          }
                        },
                        child: setButton(
                            childWidget: (state
                                    is UpdateLikeAndDisLikeStatusInProgress)
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: UiUtils.showCircularProgress(
                                        true, Theme.of(context).primaryColor))
                                : ((isLike)
                                    ? const Icon(Icons.thumb_up_alt, size: 20)
                                    : const Icon(Icons.thumb_up_off_alt,
                                        size: 20))));
                  });
            }));
  }

  Widget setShareBookmarkLikeOptions() {
    return Positioned.directional(
      end: 5,
      bottom: 5,
      textDirection: Directionality.of(context),
      child: Row(
        children: [
          shareButton(),
          SizedBox(width: MediaQuery.of(context).size.width / 98.0),
          bookmarkButton(),
          SizedBox(width: MediaQuery.of(context).size.width / 98.0),
          likeButton()
        ],
      ),
    );
  }

  Widget newsData() {
    return Builder(builder: (context) {
      return Padding(
          padding: EdgeInsetsDirectional.only(
              top: widget.index == 0 ? 0 : 15.0, start: 15, end: 15),
          child: Column(children: [
            if (context.read<AppConfigurationCubit>().getInAppAdsMode() ==
                    "1" &&
                (context.read<AppConfigurationCubit>().getAdsType() !=
                        "unity" ||
                    context.read<AppConfigurationCubit>().getIOSAdsType() !=
                        "unity"))
              nativeAdsShow(context: context, index: widget.index),
            NewsCard(
                newsDetail: widget.model,
                showTags: true,
                homeMeta: widget.homeMeta,
                onTap: () {
                  List<NewsModel> newsList = [];
                  newsList.addAll(widget.newslist);
                  newsList.removeAt(widget.index);
                  Navigator.of(context)
                      .pushNamed(Routes.newsDetails, arguments: {
                    "model": widget.model,
                    "newsList": newsList,
                    "isFromBreak": false,
                    "fromShowMore": widget.fromShowMore
                  });
                })
          ]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return newsData();
  }
}
