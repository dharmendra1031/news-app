import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/shimmer_news_list.dart';
import 'package:news/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/news/cubits/tag_news_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/features/news/repositories/like_and_dislike_news/like_and_dislike_news_repository.dart';

class NewsTag extends StatefulWidget {
  final String tagId;
  final String tagName;

  const NewsTag({super.key, required this.tagId, required this.tagName});

  @override
  NewsTagState createState() => NewsTagState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) =>
            NewsTag(tagId: arguments['tagId'], tagName: arguments['tagName']));
  }
}

class NewsTagState extends State<NewsTag> {
  @override
  void initState() {
    super.initState();
    getTagWiseNews();
  }

  getTagWiseNews() {
    Future.delayed(Duration.zero, () {
      context.read<TagNewsCubit>().getTagNews(
          tagId: widget.tagId,
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          latitude: SettingsLocalDataRepository().getLocationCityValues().first,
          longitude:
              SettingsLocalDataRepository().getLocationCityValues().last);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            isConvertText: false,
            height: 45,
            isBackBtn: true,
            label: widget.tagName,
            horizontalPad: 15),
        body: viewContent());
  }

  newsItem(NewsModel model, int index) {
    List<String> tagList = [];
    List<String> tagId = [];

    DateTime time1 = DateTime.parse(model.publishDate ?? model.date!);

    if (model.tagName! != "") {
      final tagName = model.tagName!;
      tagList = tagName.split(',');
    }

    if (model.tagId! != "") tagId = model.tagId!.split(",");

    return Builder(builder: (context) {
      return Padding(
          padding: EdgeInsetsDirectional.only(
              top: index == 0 ? 0 : MediaQuery.of(context).size.height / 25.0),
          child: Column(children: <Widget>[
            InkWell(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 4.2,
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: CustomNetworkImage(
                                networkImageUrl: model.image ?? "",
                                width: double.maxFinite,
                                height:
                                    MediaQuery.of(context).size.height / 4.2,
                                isVideo: false,
                                fit: BoxFit.cover)),
                        if (model.tagName! != "")
                          Container(
                            margin: const EdgeInsets.only(
                                bottom: 5.0, left: 5.0, right: 5.0),
                            child: SizedBox(
                                height: 16,
                                child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
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
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .only(
                                                        start: 3.0,
                                                        end: 3.0,
                                                        top: 1.0,
                                                        bottom: 1.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                  10.0),
                                                          topRight:
                                                              Radius.circular(
                                                                  10.0)),
                                                  color: UiUtils.getColorScheme(
                                                          context)
                                                      .primaryContainer
                                                      .withOpacity(0.85),
                                                ),
                                                child: CustomTextLabel(
                                                    text: tagList[index],
                                                    textStyle: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                            color: UiUtils
                                                                    .getColorScheme(
                                                                        context)
                                                                .secondary,
                                                            fontSize: 9.5),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: true)),
                                            onTap: () async {
                                              if (index >= tagId.length ||
                                                  tagId[index].isEmpty) return;
                                              Navigator.of(context).pushNamed(
                                                  Routes.tagScreen,
                                                  arguments: {
                                                    "tagId": tagId[index],
                                                    "tagName": tagList[index]
                                                  });
                                            },
                                          ));
                                    })),
                          )
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsetsDirectional.only(
                        top: 4.0, start: 5.0, end: 5.0),
                    child: CustomTextLabel(
                        text: model.title ?? "",
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.9)),
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 4.0, start: 5.0, end: 5.0),
                            child: CustomTextLabel(
                                text: UiUtils.convertToAgo(context, time1, 0)!,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withOpacity(0.6)))),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 13.0),
                            child: InkWell(
                              child: const Icon(Icons.share_rounded),
                              onTap: () async {
                                if (await InternetConnectivity
                                    .isNetworkAvailable()) {
                                  UiUtils.shareNews(
                                      context: context,
                                      slug: model.slug ?? "",
                                      title: model.title!,
                                      isVideo: false,
                                      isReels: false,
                                      videoId: "",
                                      isBreakingNews: false,
                                      isNews: true);
                                } else {
                                  showSnackBar(
                                      UiUtils.getTranslatedLabel(
                                          context, 'internetmsg'),
                                      context);
                                }
                              },
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width / 99.0),
                          BlocProvider(
                              create: (context) => UpdateBookmarkStatusCubit(
                                  BookmarkRepository()),
                              child: BlocSelector<BookmarkCubit, BookmarkState,
                                      bool>(
                                  selector: (state) => context
                                      .read<BookmarkCubit>()
                                      .isNewsBookmark(model.id!),
                                  builder: (context, isBookmark) {
                                    return BlocConsumer<
                                            UpdateBookmarkStatusCubit,
                                            UpdateBookmarkStatusState>(
                                        bloc: context
                                            .read<UpdateBookmarkStatusCubit>(),
                                        listener: ((context, state) {
                                          if (state
                                              is UpdateBookmarkStatusSuccess) {
                                            if (state.wasBookmarkNewsProcess) {
                                              context
                                                  .read<BookmarkCubit>()
                                                  .addBookmarkNews(state.news);
                                            } else {
                                              context
                                                  .read<BookmarkCubit>()
                                                  .removeBookmarkNews(
                                                      state.news);
                                            }
                                          }
                                        }),
                                        builder: (context, state) {
                                          return InkWell(
                                              onTap: () {
                                                if (context
                                                        .read<AuthCubit>()
                                                        .getUserId() !=
                                                    "0") {
                                                  if (state
                                                      is UpdateBookmarkStatusInProgress) {
                                                    return;
                                                  }
                                                  context
                                                      .read<
                                                          UpdateBookmarkStatusCubit>()
                                                      .setBookmarkNews(
                                                          news: model,
                                                          status: (isBookmark)
                                                              ? "0"
                                                              : "1");
                                                } else {
                                                  UiUtils.loginRequired(
                                                      context);
                                                }
                                              },
                                              child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .zero,
                                                  child: InkWell(
                                                      child: state
                                                              is UpdateBookmarkStatusInProgress
                                                          ? SizedBox(
                                                              height: 15,
                                                              width: 15,
                                                              child: UiUtils
                                                                  .showCircularProgress(
                                                                      true,
                                                                      Theme.of(
                                                                              context)
                                                                          .primaryColor))
                                                          : Icon(isBookmark
                                                              ? Icons
                                                                  .bookmark_added_rounded
                                                              : Icons
                                                                  .bookmark_add_outlined))));
                                        });
                                  })),
                          SizedBox(
                              width: MediaQuery.of(context).size.width / 99.0),
                          BlocProvider(
                              create: (context) =>
                                  UpdateLikeAndDisLikeStatusCubit(
                                      LikeAndDisLikeRepository()),
                              child: BlocSelector<LikeAndDisLikeCubit,
                                      LikeAndDisLikeState, bool>(
                                  selector: (state) => context
                                      .read<LikeAndDisLikeCubit>()
                                      .isNewsLikeAndDisLike(model.id!),
                                  builder: (context, isLike) {
                                    return BlocConsumer<
                                            UpdateLikeAndDisLikeStatusCubit,
                                            UpdateLikeAndDisLikeStatusState>(
                                        bloc: context.read<
                                            UpdateLikeAndDisLikeStatusCubit>(),
                                        listener: ((context, state) {
                                          if (state
                                              is UpdateLikeAndDisLikeStatusSuccess) {
                                            if (state
                                                .wasLikeAndDisLikeNewsProcess) {
                                              context
                                                  .read<LikeAndDisLikeCubit>()
                                                  .addLikeNews(state.news);
                                            } else {
                                              context
                                                  .read<LikeAndDisLikeCubit>()
                                                  .removeLikeNews(state.news);
                                            }
                                            state.news.totalLikes = (!isLike)
                                                ? (int.parse(state
                                                            .news.totalLikes
                                                            .toString()) +
                                                        1)
                                                    .toString()
                                                : (state.news.totalLikes!
                                                        .isNotEmpty)
                                                    ? (int.parse(state
                                                                .news.totalLikes
                                                                .toString()) -
                                                            1)
                                                        .toString()
                                                    : "0";
                                          }
                                        }),
                                        builder: (context, state) {
                                          return InkWell(
                                              splashColor: Colors.transparent,
                                              onTap: () {
                                                if (context
                                                        .read<AuthCubit>()
                                                        .getUserId() !=
                                                    "0") {
                                                  if (state
                                                      is UpdateLikeAndDisLikeStatusInProgress) {
                                                    return;
                                                  }
                                                  context
                                                      .read<
                                                          UpdateLikeAndDisLikeStatusCubit>()
                                                      .setLikeAndDisLikeNews(
                                                          news: model,
                                                          status: (isLike)
                                                              ? "0"
                                                              : "1");
                                                } else {
                                                  UiUtils.loginRequired(
                                                      context);
                                                }
                                              },
                                              child: (state
                                                      is UpdateLikeAndDisLikeStatusInProgress)
                                                  ? SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: UiUtils
                                                          .showCircularProgress(
                                                              true,
                                                              Theme.of(context)
                                                                  .primaryColor))
                                                  : isLike
                                                      ? const Icon(
                                                          Icons.thumb_up_alt)
                                                      : const Icon(Icons
                                                          .thumb_up_off_alt));
                                        });
                                  })),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                UiUtils.showInterstitialAds(context: context);
                Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                  "model": model,
                  "isFromBreak": false,
                  "fromShowMore": false
                });
              },
            ),
          ]));
    });
  }

  viewContent() {
    return BlocBuilder<TagNewsCubit, TagNewsState>(builder: (context, state) {
      if (state is TagNewsFetchSuccess) {
        return Padding(
            padding: const EdgeInsetsDirectional.only(
                top: 10.0, bottom: 10.0, start: 13.0, end: 13.0),
            child: ListView.builder(
                itemCount: state.tagNews.length,
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 20),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: ((context, index) {
                  return newsItem((state).tagNews[index], index);
                })));
      }
      if (state is TagNewsFetchFailure) {
        return ErrorContainerWidget(
            errorMsg: (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                : state.errorMessage,
            onRetry: getTagWiseNews);
      }
      return ShimmerNewsList(isNews: true);
    });
  }
}
