import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/app.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/news/screens/news_detail/widgets/interstitial_ads/google_interstitial_ads.dart';
import 'package:news/features/news/screens/news_detail/widgets/interstitial_ads/unity_interstitial_ads.dart';
import 'package:news/features/news/screens/news_detail/widgets/news_detail_app_bar.dart';
import 'package:news/features/news/screens/news_detail/widgets/news_subdetails_screen.dart';
import 'package:news/features/news/screens/news_detail/widgets/reward_ads/google_reward_ads.dart';
import 'package:news/features/news/screens/news_detail/widgets/reward_ads/unity_reward_ads.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsModel? model;
  final List<NewsModel>? newsList;
  final BreakingNewsModel? breakModel;
  final List<BreakingNewsModel>? breakNewsList;
  final bool isFromBreak;
  final bool fromShowMore;
  final String? slug;
  final bool? fromShortNews;

  /// Opened from the Short News rail's "View More" (not from a single card):
  /// stories page vertically as inshorts-style cards under one pinned app bar.
  final bool shortNewsFeed;

  const NewsDetailScreen(
      {super.key,
      this.model,
      this.breakModel,
      this.breakNewsList,
      this.newsList,
      this.slug,
      required this.isFromBreak,
      required this.fromShowMore,
      this.fromShortNews,
      this.shortNewsFeed = false});

  @override
  NewsDetailsState createState() => NewsDetailsState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => NewsDetailScreen(
            model: arguments['model'],
            breakModel: arguments['breakModel'],
            breakNewsList: arguments['breakNewsList'],
            newsList: arguments['newsList'],
            isFromBreak: arguments['isFromBreak'],
            fromShowMore: arguments['fromShowMore'],
            slug: arguments['slug'],
            fromShortNews: arguments['fromShortNews'] ?? false,
            shortNewsFeed: arguments['shortNewsFeed'] ?? false));
  }
}

class NewsDetailsState extends State<NewsDetailScreen> {
  final PageController pageController = PageController();

  bool isScrollLocked = false;

  void _setScrollLock(bool lock) {
    setState(() {
      isScrollLocked = lock;
    });
  }

  @override
  void initState() {
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1") {
      if (context.read<AppConfigurationCubit>().checkAdsType() == "google") {
        createGoogleInterstitialAd(context);
        createGoogleRewardedAd(context);
      } else {
        if (context.read<AppConfigurationCubit>().unityGameId() != null) {
          UnityAds.init(
            gameId: context.read<AppConfigurationCubit>().unityGameId()!,
            testMode: true, //set it to False @Deployement
            onComplete: () {
              loadUnityInterAd(
                  context.read<AppConfigurationCubit>().interstitialId()!);
              loadUnityRewardAd(
                  context.read<AppConfigurationCubit>().rewardId()!);
            },
            onFailed: (error, message) =>
                debugPrint('Initialization Failed: $error $message'),
          );
        }
      }
    }

    super.initState();

    if (widget.model != null) {
      firebaseAnalytics.logEvent(
        name: 'news_opened',
        parameters: {
          'news_id': widget.model?.newsId ?? '',
          'category': widget.model?.categoryId ?? '',
          'title': widget.model?.title ?? '',
        },
      );
      debugPrint(
          'FirebaseAnalytics: logged news_opened ${widget.model?.newsId}');
    }
    if (widget.breakModel != null) {
      firebaseAnalytics.logEvent(
        name: 'breaking_news_opened',
        parameters: {
          'breaking_news_id': widget.breakModel?.id ?? '',
          'category': '',
          'title': widget.breakModel?.title ?? '',
        },
      );
      debugPrint(
          'FirebaseAnalytics: logged breaking_news_opened ${widget.breakModel?.id}');
    }
  }

  Widget showBreakingNews() {
    return PageView.builder(
        controller: pageController,
        onPageChanged: (index) async {
          if (await InternetConnectivity.isNetworkAvailable()) {
            if (index % rewardAdsIndex == 0) showRewardAds();
            UiUtils.showInterstitialAds(context: context);
          }
        },
        itemCount:
            (widget.breakNewsList == null || widget.breakNewsList!.isEmpty)
                ? 1
                : widget.breakNewsList!.length + 1,
        itemBuilder: (context, index) {
          return NewsSubDetails(
              onLockScroll:
                  (p0) {}, //no change for breaking news , No comments widget
              breakModel: (index == 0)
                  ? widget.breakModel
                  : widget.breakNewsList![index - 1],
              fromShowMore: widget.fromShowMore,
              isFromBreak: widget.isFromBreak,
              model: widget.model);
        });
  }

  void showRewardAds() {
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1") {
      if (context.read<AppConfigurationCubit>().checkAdsType() == "google") {
        showGoogleRewardedAd(context);
      } else {
        showUnityRewardAds(context.read<AppConfigurationCubit>().rewardId()!);
      }
    }
  }

  bool get _isShortNews => widget.shortNewsFeed;

  /// Page i shows newsList[i - 1]; page 0 is `model`.
  NewsModel? _newsAt(int index) =>
      index == 0 ? widget.model : widget.newsList![index - 1];

  /// Short News feed: tapping a story opens the standard Short News details
  /// screen on it — the same one a card on the home screen opens, with the
  /// bookmark / share bar — with the other stories following it.
  void _openShortNewsDetail(int index) {
    final List<NewsModel> stories = [
      if (widget.model != null) widget.model!,
      ...?widget.newsList,
    ];
    final List<NewsModel> rest = List.of(stories)..removeAt(index);
    Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
      "model": stories[index],
      "newsList": rest,
      "isFromBreak": false,
      "fromShowMore": false,
      "fromShortNews": true,
    });
  }

  Widget showNews() {
    final Widget pager = PageView.builder(
        controller: pageController,
        // Short News scrolls up and down between stories, like inshorts.
        scrollDirection: _isShortNews ? Axis.vertical : Axis.horizontal,
        physics: isScrollLocked
            ? NeverScrollableScrollPhysics()
            : AlwaysScrollableScrollPhysics(),
        onPageChanged: (index) async {
          if (await InternetConnectivity.isNetworkAvailable() &&
              widget.fromShortNews != true) {
            if (index % rewardAdsIndex == 0) showRewardAds();
            UiUtils.showInterstitialAds(context: context);
          }
        },
        itemCount: (widget.newsList == null || widget.newsList!.isEmpty)
            ? 1
            : widget.newsList!.length + 1,
        itemBuilder: (context, index) {
          // The story after this page is newsList[index], when there is one.
          final bool hasNext = _isShortNews &&
              widget.newsList != null &&
              index < widget.newsList!.length;
          return NewsSubDetails(
              onLockScroll: _setScrollLock,
              model: _newsAt(index),
              fromShowMore: widget.fromShowMore,
              isFromBreak: widget.isFromBreak,
              breakModel: widget.breakModel,
              fromShortNews: widget.fromShortNews ?? false,
              shortNewsFeed: _isShortNews,
              onOpenShortNews: () => _openShortNewsDetail(index),
              nextShortNews: hasNext ? widget.newsList![index] : null,
              onNextShortNews: () => pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut));
        });
    if (!_isShortNews) return pager;

    // Short News feed: one app bar above the pager, so only the story scrolls.
    // It is just back + title; bookmark and share live on the details screen a
    // story opens.
    return Column(children: [
      NewsDetailAppBar(
        isFromBreak: false,
        titleKey: 'shortNewsLbl',
        showBookmark: false,
        showShare: false,
        onBack: () => Navigator.of(context).pop(),
        onShare: () {},
      ),
      Expanded(child: pager),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // FIGMA(3768-8884): the redesigned news-details screen sits on a plain
        // white surface in light mode (Surface/Transparent); dark keeps the
        // darkest screen background.
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? darkBackgroundColor
            : Colors.white,
        body: widget.isFromBreak ? showBreakingNews() : showNews());
  }
}
