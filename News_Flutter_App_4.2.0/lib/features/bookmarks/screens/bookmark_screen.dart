import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/news_card.dart';
import 'package:news/commons/widgets/shimmer_news_list.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/ui_utils.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  BookmarkScreenState createState() => BookmarkScreenState();
}

class BookmarkScreenState extends State<BookmarkScreen> {
  late final ScrollController _controller = ScrollController()
    ..addListener(hasMoreBookmarkScrollListener);

  @override
  void initState() {
    super.initState();
    getBookMark();
  }

  void getBookMark() async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      context.read<BookmarkCubit>().getBookmark(
          langCode: context.read<AppLocalizationCubit>().state.languageCode);
    }
  }

  void hasMoreBookmarkScrollListener() {
    if (_controller.position.maxScrollExtent == _controller.offset) {
      if (context.read<BookmarkCubit>().hasMoreBookmark()) {
        context.read<BookmarkCubit>().getMoreBookmark(
            langCode: context.read<AppLocalizationCubit>().state.languageCode);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            height: 45,
            isBackBtn: true,
            label: 'bookmarkLbl',
            horizontalPad: 15,
            isConvertText: true),
        body: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 10.0),
            child: BlocBuilder<BookmarkCubit, BookmarkState>(
              builder: (context, state) {
                if (state is BookmarkFetchSuccess &&
                    state.bookmark.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 15.0, end: 15.0, top: 10.0, bottom: 10.0),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        getBookMark();
                      },
                      child: ListView.builder(
                          controller: _controller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: state.bookmark.length,
                          itemBuilder: (context, index) {
                            return _buildBookmarkContainer(
                                model: state.bookmark[index],
                                hasMore: state.hasMore,
                                hasMoreBookFetchError: state.hasMoreFetchError,
                                index: index,
                                totalCurrentBook: 6);
                          }),
                    ),
                  );
                } else if (state is BookmarkFetchFailure ||
                    ((state is! BookmarkFetchInProgress))) {
                  if (state is BookmarkFetchFailure) {
                    return ErrorContainerWidget(
                        errorMsg: (state.errorMessage
                                .contains(ErrorMessageKeys.noInternet))
                            ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                            : state.errorMessage,
                        onRetry: getBookMark);
                  } else {
                    return Center(
                        child: ErrorContainerWidget(
                            errorMsg: 'bookmarkNotAvail',
                            onRetry: getBookMark));
                  }
                }
                //default/Processing state
                return Padding(
                    padding: const EdgeInsets.only(
                        bottom: 10.0, left: 10.0, right: 10.0),
                    child: ShimmerNewsList(isNews: false));
              },
            )));
  }

  _buildBookmarkContainer(
      {required NewsModel model,
      required int index,
      required int totalCurrentBook,
      required bool hasMoreBookFetchError,
      required bool hasMore}) {
    if (index == totalCurrentBook - 1 && index != 0 && hasMore) {
      if (hasMoreBookFetchError) {
        return Center(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                child: IconButton(
                    onPressed: () {
                      context.read<BookmarkCubit>().getMoreBookmark(
                          langCode: context
                              .read<AppLocalizationCubit>()
                              .state
                              .languageCode);
                    },
                    icon: Icon(Icons.error,
                        color: Theme.of(context).primaryColor))));
      }
    }

    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 15.0),
        child: NewsCard(
            newsDetail: model,
            showViews: true,
            onTap: () async {
              //Interstitial Ad here
              UiUtils.showInterstitialAds(context: context);
              Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                "model": model,
                "isFromBreak": false,
                "fromShowMore": false
              });
            }));
  }
}
