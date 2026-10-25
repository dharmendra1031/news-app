import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/ad_spaces.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/cubits/adspace/adSpaces_news_details_cubit.dart';
import 'package:news/commons/cubits/font_size_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/cubits/comment_news_cubit.dart';
import 'package:news/features/news/cubits/related_news_cubit.dart';
import 'package:news/features/news/cubits/set_news_views_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';

import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/features/news/screens/news_detail/widgets/Image_view.dart';
import 'package:news/features/news/screens/news_detail/widgets/comment_input_bar.dart';
import 'package:news/features/news/screens/news_detail/widgets/comment_view.dart';
import 'package:news/features/news/screens/news_detail/widgets/desc_view.dart';
import 'package:news/features/news/screens/news_detail/widgets/news_detail_action_bar.dart';
import 'package:news/features/news/screens/news_detail/widgets/news_detail_app_bar.dart';
import 'package:news/features/news/screens/news_detail/widgets/related_news_list.dart';
import 'package:news/features/news/screens/news_detail/widgets/reply_comment_view.dart';
import 'package:news/features/news/screens/news_detail/widgets/set_banner_ads.dart';
import 'package:news/features/news/screens/news_detail/widgets/short_news_card.dart';
import 'package:news/features/news/screens/news_detail/widgets/tag_view.dart';
import 'package:news/features/news/screens/news_detail/widgets/title_view.dart';
import 'package:news/features/news/screens/news_detail/widgets/video_btn.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';

class NewsSubDetails extends StatefulWidget {
  final NewsModel? model;
  final BreakingNewsModel? breakModel;
  final bool fromShowMore;
  final bool isFromBreak;
  final bool fromShortNews;
  final Function(bool) onLockScroll;

  /// Short News "View More" feed: this page is just the inshorts-style card (the
  /// parent pins the app bar above the pager). A story opened from the rail
  /// leaves this off and keeps the standard details screen.
  final bool shortNewsFeed;

  /// Feed only: opens this story's details screen (bookmark / share included).
  final VoidCallback? onOpenShortNews;

  /// Feed only: the story after this one, and the action that pages to it.
  /// They feed the teaser strip at the bottom of the card.
  final NewsModel? nextShortNews;
  final VoidCallback? onNextShortNews;

  const NewsSubDetails(
      {super.key,
      this.model,
      this.breakModel,
      required this.fromShowMore,
      required this.isFromBreak,
      required this.onLockScroll,
      this.fromShortNews = false,
      this.shortNewsFeed = false,
      this.onOpenShortNews,
      this.nextShortNews,
      this.onNextShortNews});

  @override
  NewsSubDetailsState createState() => NewsSubDetailsState();
}

class NewsSubDetailsState extends State<NewsSubDetails> {
  bool comEnabled = false;
  bool isReply = false;
  int? replyComIndex;
  bool isPlaying = false;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  BannerAd? _bannerAd;
  NewsModel? newsModel;
  FlutterTts? _flutterTts;
  bool _isScrollingUp = false;
  bool _shortNewsExpanded = true;
  static const int _shortNewsDescLimit = 300;
  // Distance from the bottom at which the next page of related news loads.
  static const double _relatedNewsLoadMoreExtent = 200.0;

  late final ScrollController controller = ScrollController()
    ..addListener(hasMoreCommScrollListener);

  @override
  void initState() {
    super.initState();
    newsModel = widget.model;
    getComments();
    getRelatedNews();
    initializeTts();
    setNewsViews(isBreakingNews: (widget.isFromBreak) ? true : false);
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1")
      bannerAdsInitialized();
    Future.delayed(Duration.zero, () {
      context.read<AdSpacesNewsDetailsCubit>().getAdspaceForNewsDetails(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          page: "news_details_screen");
    });
    if (widget.fromShortNews) _shortNewsExpanded = false;
  }

  setNewsViews({required bool isBreakingNews}) {
    Future.delayed(Duration.zero, () {
      context.read<SetNewsViewsCubit>().setNewsViews(
          newsId: isBreakingNews
              ? widget.breakModel!.id!
              : (newsModel!.newsId ?? newsModel!.id)!,
          isBreakingNews: isBreakingNews);
    });
  }

  getComments() {
    if (!widget.isFromBreak &&
        context.read<AppConfigurationCubit>().getCommentsMode() == "1") {
      Future.delayed(Duration.zero, () {
        context.read<CommentNewsCubit>().getCommentNews(
            newsId: (newsModel!.newsId != null &&
                    newsModel!.newsId!.trim().isNotEmpty)
                ? newsModel!.newsId!
                : newsModel!.id!);
      });
    }
  }

  String? get _relatedCatId =>
      (newsModel!.categoryId != "0" || newsModel!.categoryId == '')
          ? newsModel!.categoryId
          : null;

  String? get _relatedSubCatId =>
      (newsModel!.subCatId != "0" || newsModel!.subCatId != '')
          ? newsModel!.subCatId
          : null;

  getRelatedNews() {
    if (!widget.isFromBreak) {
      Future.delayed(Duration.zero, () {
        context.read<RelatedNewsCubit>().getRelatedNews(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            catId: _relatedCatId,
            subCatId: _relatedSubCatId);
      });
    }
  }

  void _loadMoreRelatedNews() {
    context.read<RelatedNewsCubit>().getMoreRelatedNews(
        langCode: context.read<AppLocalizationCubit>().state.languageCode,
        catId: _relatedCatId,
        subCatId: _relatedSubCatId);
  }

  @override
  void dispose() {
    _flutterTts!.stop();
    controller.removeListener(hasMoreCommScrollListener);
    controller.dispose();
    super.dispose();
  }

  initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts!.awaitSpeakCompletion(true);
    _flutterTts!.setStartHandler(() async {
      if (mounted) {
        setState(() => isPlaying = true);
      }
    });

    _flutterTts!.setCompletionHandler(() {
      if (mounted) {
        setState(() => isPlaying = false);
      }
    });

    _flutterTts!.setErrorHandler((err) {
      //print("TTS Error: $err");
      if (mounted) {
        setState(() => isPlaying = false);
      }
    });
  }

  bannerAdsInitialized() {
    if (context.read<AppConfigurationCubit>().checkAdsType() == "unity") {
      UnityAds.init(
          gameId: context.read<AppConfigurationCubit>().unityGameId()!,
          testMode: true, //set it to false @Deployment
          onComplete: () {
            debugPrint('Unity Ads Initialization Completed');
          },
          onFailed: (error, message) {
            debugPrint('Unity Ads Initialization Failed: $error $message');
          });
    }

    if (context.read<AppConfigurationCubit>().checkAdsType() == "google") {
      _createBottomBannerAd();
    }
  }

  void _createBottomBannerAd() {
    if (context.read<AppConfigurationCubit>().bannerId() != "") {
      _bannerAd = BannerAd(
        adUnitId: context.read<AppConfigurationCubit>().bannerId()!,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) {},
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
          },
        ),
      );

      _bannerAd!.load();
    }
  }

  speak(String description) async {
    if (description.isNotEmpty) {
      await _flutterTts!.setVolume(volume);
      await _flutterTts!.setSpeechRate(rate);
      await _flutterTts!.setPitch(pitch);
      await _flutterTts!.setLanguage(() {
        return context.read<AppLocalizationCubit>().state.languageCode;
      }());
      int length = description.length;

      if (length < 4000) {
        setState(() => isPlaying = true);
        await _flutterTts!.speak(description);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            _flutterTts!.stop();
            isPlaying = false;
          });
        });
      } else if (length < 8000) {
        if (Platform.isAndroid) await _flutterTts!.setQueueMode(1);
        String temp1 = description.substring(0, length ~/ 2);
        await _flutterTts!.speak(temp1);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = true;
          });
        });
        String temp2 = description.substring(temp1.length, description.length);
        await _flutterTts!.speak(temp2);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
          });
        });
      } else if (length < 12000) {
        if (Platform.isAndroid) await _flutterTts!.setQueueMode(2);
        String temp1 = description.substring(0, 3999);
        await _flutterTts!.speak(temp1);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = true;
          });
        });
        String temp2 = description.substring(temp1.length, 7999);
        await _flutterTts!.speak(temp2);
        _flutterTts!.setCompletionHandler(() {
          setState(() {});
        });
        String temp3 = description.substring(temp2.length, description.length);
        await _flutterTts!.speak(temp3);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
          });
        });
      } else {
        String temp = description.substring(0, description.length);
        await _flutterTts!.speak(temp);
        _flutterTts!.setCompletionHandler(() {
          setState(() {
            isPlaying = false;
          });
        });
      }
    }
  }

  stop() async {
    var result = await _flutterTts!.stop();
    if (result == 1) setState(() => isPlaying = false);
  }

  onBackPress(bool isTrue) {
    (widget.fromShowMore == true)
        ? Navigator.of(context).popUntil((route) => route.isFirst)
        : Navigator.pop(context);
  }

  /// Compact count e.g. 1000 -> "1K", 1_200_000 -> "1.2M". Matches the Figma
  /// "1K View" chip.
  String _compactCount(String? raw) {
    final int n = int.tryParse(raw ?? '') ?? 0;
    if (n >= 1000000) {
      final v = n / 1000000;
      return "${v.toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M";
    }
    if (n >= 1000) {
      final v = n / 1000;
      return "${v.toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K";
    }
    return "$n";
  }

  /// A single "• label" pill used in the info row (views / reading time). Kept
  /// flex-free so it can be dropped straight into a Row or an Expanded slot.
  Widget _infoChip(String text) {
    final onColor = UiUtils.getColorScheme(context).primaryContainer;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: onColor, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Flexible(
        child: CustomTextLabel(
            text: text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onColor,
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0)),
      ),
    ]);
  }

  Widget showViews() {
    final viewsCount = !widget.isFromBreak
        ? ((newsModel?.totalViews?.isNotEmpty ?? false) &&
                newsModel!.totalViews != "null"
            ? newsModel!.totalViews!
            : "0")
        : ((widget.breakModel?.totalViews?.isNotEmpty ?? false) &&
                widget.breakModel!.totalViews != "null"
            ? widget.breakModel!.totalViews!
            : "0");
    return _infoChip(
        "${_compactCount(viewsCount)} ${UiUtils.getTranslatedLabel(context, 'viewsLbl')}");
  }

  /// FIGMA(3768-8884 light / 3768-9010 dark): the "• 1K View   • 4 Minutes
  /// read" row, 6px between the two chips. [topGap] is the 8px under the author
  /// divider; it is 0 when there is no author, so the row takes the author
  /// row's place instead of leaving a gap.
  Widget _infoRow(int readingTime, String minutesPostfix,
      {double topGap = 8.0}) {
    return Padding(
      padding: EdgeInsetsDirectional.only(top: topGap),
      child: Row(children: [
        Flexible(child: showViews()),
        const SizedBox(width: 6),
        Flexible(
          child: _infoChip(
              "$readingTime $minutesPostfix ${UiUtils.getTranslatedLabel(context, 'read')}"),
        ),
      ]),
    );
  }

  /// Author row shown above the title.
  ///
  /// The identity (name + profile picture) only ever comes from `user`, while
  /// `author` carries just the author record (bio/links/user_id). The backend
  /// sends them independently — admin posts have neither, and posts whose
  /// author account was removed keep `author` with `user` null — so resolve
  /// what is actually available and render nothing when there is no name.
  /// Previously this force-unwrapped `userAthorDetails`, which threw and took
  /// the whole row down whenever only `authorDetails` came back.
  /// FIGMA(3768-8884 light / 3768-9010 dark): author row — 34px avatar, 4px
  /// gap, name in Text/Primary 12, and the publish date in Text/Tertiary 11
  /// ("4 Aug 2026"). Text/Tertiary is #A0A0A0 in light and #676767 in dark.
  Widget showAuthor() {
    final author = newsModel?.userAthorDetails;
    final name = author?.name?.trim() ?? '';
    if (name.isEmpty) return const SizedBox.shrink();

    final authorId =
        author?.id ?? newsModel?.authorDetails?.userId?.toString() ?? "0";
    final profile = author?.profile ?? '';
    final onColor = UiUtils.getColorScheme(context).primaryContainer;
    final dateColor =
        Theme.of(context).brightness == Brightness.dark
            ? textSecondaryColor
            : textTertiaryColor;

    final rawDate = newsModel?.publishDate ?? newsModel?.date;
    String dateText = '';
    if (rawDate != null && rawDate.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) dateText = DateFormat('d MMM yyyy').format(parsed);
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(Routes.authorDetails,
            arguments: {"authorId": authorId});
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: SizedBox(
              width: 34,
              height: 34,
              child: profile.isNotEmpty
                  ? CustomNetworkImage(
                      networkImageUrl: profile,
                      width: 34,
                      height: 34,
                      isVideo: false,
                      fit: BoxFit.cover)
                  : SvgPictureWidget(
                      assetName: 'profile',
                      height: 34,
                      width: 34,
                      assetColor:
                          ColorFilter.mode(onColor, BlendMode.srcIn)),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextLabel(
                  text: name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onColor,
                      fontSize: 12,
                      height: 16 / 12,
                      letterSpacing: 0),
                ),
                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  CustomTextLabel(
                    text: dateText,
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dateColor,
                        fontSize: 11,
                        height: 14 / 11,
                        letterSpacing: 0),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  otherMainDetails() {
    final int readingTime = widget.isFromBreak
        ? (widget.breakModel!.readTime ?? 0)
        : (newsModel!.readTime ?? 0);
    final String minutesPostfix = (readingTime == 1)
        ? UiUtils.getTranslatedLabel(context, 'minute')
        : UiUtils.getTranslatedLabel(context, 'minutes');
    final bool showArticle = !isReply && !comEnabled;
    final bool hasAuthor =
        !widget.isFromBreak &&
            (newsModel?.userAthorDetails?.name?.trim().isNotEmpty ?? false);
    final bool hasTags =
        !widget.isFromBreak && (newsModel?.tagName?.isNotEmpty ?? false);

    return Container(
      padding:
          const EdgeInsetsDirectional.only(start: 16.0, end: 16.0, top: 20.0),
      width: double.maxFinite,
      // FIGMA(3768-8884): article body sits flat on the screen surface — white
      // in light mode, the darkest background in dark mode.
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? darkBackgroundColor
              : Colors.white),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            (_shortNewsExpanded)
                ? BlocBuilder<AdSpacesNewsDetailsCubit,
                    AdSpacesNewsDetailsState>(
                    builder: (context, state) {
                      return (state is AdSpacesNewsDetailsFetchSuccess &&
                              state.adSpaceTopData != null)
                          // Breathing room between the top ad and the
                          // author / "views · minutes read" block below it.
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 16),
                              child: AdSpaces(adsModel: state.adSpaceTopData!))
                          : const SizedBox.shrink();
                    },
                  )
                : const SizedBox.shrink(),
            if (showArticle)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAuthor) ...[
                    showAuthor(),
                    // Figma draws the 1px divider on the row just above its
                    // layout line, i.e. 7px under the author row with the info
                    // row 8px below it (50px from the top of the block).
                    const SizedBox(height: 7),
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? darkBorderDefaultColor
                            : borderDefaultColor),
                  ],
                  _infoRow(readingTime, minutesPostfix,
                      topGap: hasAuthor ? 8.0 : 0.0),
                  if (hasTags) ...[
                    const SizedBox(height: 10),
                    tagView(
                        model: newsModel!,
                        context: context,
                        isFromDetailsScreen: true),
                  ],
                  titleView(
                      title: widget.isFromBreak
                          ? widget.breakModel!.title!
                          : newsModel!.title!,
                      context: context),
                  _buildDescriptionContent(),
                ],
              ),
            if (!widget.isFromBreak && !isReply && comEnabled)
              CommentView(
                  newsId: newsModel!.id!,
                  updateComFun: updateCommentshow,
                  updateIsReplyFun: updateComReply),
            if (!widget.isFromBreak && isReply && comEnabled)
              ReplyCommentView(
                  replyComIndex: replyComIndex!,
                  replyComFun: updateComReply,
                  newsId: newsModel!.id!),
            (_shortNewsExpanded)
                ? BlocBuilder<AdSpacesNewsDetailsCubit,
                    AdSpacesNewsDetailsState>(
                    builder: (context, state) {
                      return (state is AdSpacesNewsDetailsFetchSuccess &&
                              state.adSpaceBottomData != null)
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(bottom: 5),
                              child:
                                  AdSpaces(adsModel: state.adSpaceBottomData!))
                          : const SizedBox.shrink();
                    },
                  )
                : const SizedBox.shrink(),
            if (!widget.isFromBreak &&
                !isReply &&
                !comEnabled &&
                newsModel != null &&
                _shortNewsExpanded)
              RelatedNewsList(
                  model: newsModel!, onLoadMore: _loadMoreRelatedNews),
          ]),
    );
  }

  bool get _isShortNewsCollapsed =>
      !widget.isFromBreak &&
      (newsModel?.isShortNews == true) &&
      !_shortNewsExpanded;

  /// Size this article renders at: always the saved global size, so changes
  /// made here and in Profile > Text Size stay in sync.
  int _effectiveFontSize(FontSizeState globalState) => globalState.fontSize;

  void _updateFontVal(int value) {
    context.read<FontSizeCubit>().changeFontSize(value);
  }

  /// Article body. Listens to [FontSizeCubit] so it picks up the global size.
  Widget _buildDescriptionContent() {
    return BlocBuilder<FontSizeCubit, FontSizeState>(
        builder: (context, fontSizeState) {
      final fontValue = _effectiveFontSize(fontSizeState).toDouble();
      final desc =
          widget.isFromBreak ? widget.breakModel!.desc! : newsModel!.desc!;

      if (!widget.isFromBreak && newsModel?.isShortNews == true) {
        final plainText = (html_parser.parse(desc).body?.text ?? '').trim();
        final showReadMore = plainText.length > _shortNewsDescLimit;
        final displayText = showReadMore && !_shortNewsExpanded
            ? '${plainText.substring(0, _shortNewsDescLimit)}...'
            : plainText;

        if (!_shortNewsExpanded && showReadMore) {
          return Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextLabel(
                  text: displayText,
                  textStyle: TextStyle(fontSize: fontValue),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _shortNewsExpanded = true),
                  child: Text(
                    UiUtils.getTranslatedLabel(context, 'readMoreLbl'),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
              ],
            ),
          );
        }
      }
      return descView(desc: desc, context: context, fontValue: fontValue);
    });
  }

  updateCommentshow(bool comEnabledUpdate) {
    setState(() {
      comEnabled = comEnabledUpdate;
      widget.onLockScroll(comEnabledUpdate);
    });
  }

  updateComReply(bool comReplyUpdate, int comIndex) {
    setState(() {
      isReply = comReplyUpdate;
      replyComIndex = comIndex;
      widget.onLockScroll(false);
    });
  }

  void hasMoreCommScrollListener() {
    if (!widget.isFromBreak && comEnabled && !isReply) {
      if (controller.position.maxScrollExtent == controller.offset) {
        if (context.read<CommentNewsCubit>().hasMoreCommentNews()) {
          context.read<CommentNewsCubit>().getMoreCommentNews(
              newsId: (newsModel!.newsId != null &&
                      newsModel!.newsId!.trim().isNotEmpty)
                  ? newsModel!.newsId!
                  : newsModel!.id!);
        } else {
          //debugPrint("No more Comments");
        }
      }
    }
    // "You might also like" list under the article: pull the next page in
    // before the user reaches the end. A failed page waits for the retry button
    // instead of re-firing on every scroll event.
    if (!widget.isFromBreak &&
        !comEnabled &&
        !isReply &&
        _shortNewsExpanded &&
        controller.position.extentAfter <= _relatedNewsLoadMoreExtent) {
      final relatedState = context.read<RelatedNewsCubit>().state;
      if (relatedState is RelatedNewsFetchSuccess &&
          relatedState.hasMore &&
          !relatedState.hasMoreFetchError) {
        _loadMoreRelatedNews();
      }
    }
    // The controller also drives the article view now, but this top-padding
    // switch is only for the comments area.
    if (widget.isFromBreak || !comEnabled || isReply) return;
    if (controller.position.userScrollDirection == ScrollDirection.forward) {
      // User is scrolling up
      if (!_isScrollingUp) {
        setState(() {
          _isScrollingUp = true;
        });
      }
    } else if (controller.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // User is scrolling down
      if (_isScrollingUp) {
        setState(() {
          _isScrollingUp = false;
        });
      }
    }
  }

  Future<void> _shareNews() async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      UiUtils.shareNews(
          context: context,
          slug: (!widget.isFromBreak)
              ? widget.model!.slug!
              : widget.breakModel!.slug!,
          title: (!widget.isFromBreak)
              ? widget.model!.title!
              : widget.breakModel!.title!,
          isNews: !widget.isFromBreak,
          isVideo: false,
          isReels: false,
          videoId: "",
          isBreakingNews: widget.isFromBreak);
    } else {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'internetmsg'), context);
    }
  }

  /// The floating action bar only belongs to the article view — hidden while the
  /// comment list or a reply thread is open (they dock their own input bar).
  bool get _showActionBar => !comEnabled && !isReply;

  /// FIGMA(3768-8884 light / 3768-9010 dark): hero image card — a 12px-rounded
  /// image with the pager dots baked in by [ImageView] and the play button
  /// centered over it. The 16px all around is the Figma container padding, so
  /// the author row below ends up 36px under the image (16 + its own 20).
  Widget _heroImage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 361 / 221,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageView(
                isFromBreak: widget.isFromBreak,
                model: newsModel,
                breakModel: widget.breakModel,
              ),
              Center(
                child: videoBtn(
                  context: context,
                  isFromBreak: widget.isFromBreak,
                  model: !widget.isFromBreak ? newsModel! : null,
                  breakModel: widget.isFromBreak ? widget.breakModel! : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The Short News feed ("View More") shows each story as the inshorts-style
  /// card only; opening one pushes the standard details screen instead.
  bool get _showShortNewsCard =>
      widget.shortNewsFeed && !widget.isFromBreak && newsModel != null;

  /// Bottom banner ad, or nothing when ads are off or the ad has no unit id.
  Widget _bottomBannerAd() {
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() != "1" &&
        _bannerAd == null) {
      return const SizedBox.shrink();
    }
    final Widget? ad = setBannerAd(context, _bannerAd);
    return ad ?? const SizedBox.shrink();
  }

  Widget _buildShortNewsCardPage() {
    return Column(children: [
      Expanded(
        child: ShortNewsCard(
          news: newsModel!,
          nextNews: widget.nextShortNews,
          onTap: widget.onOpenShortNews ?? () {},
          onNextTap: widget.onNextShortNews,
        ),
      ),
      _bottomBannerAd(),
      // iOS home-indicator clearance; Android's nav strip is already reserved
      // app-wide (see NewsDetailActionBar).
      if (Platform.isIOS)
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_showShortNewsCard) return _buildShortNewsCardPage();
    return PopScope(
      onPopInvoked: (bool isTrue) => onBackPress,
      child: AnimatedPadding(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(
            top: _isScrollingUp ? MediaQuery.of(context).viewPadding.top : 0),
        child: Column(children: [
          NewsDetailAppBar(
            isFromBreak: widget.isFromBreak,
            model: !widget.isFromBreak ? newsModel : null,
            breakModel: widget.isFromBreak ? widget.breakModel : null,
            onBack: () => onBackPress(true),
            onShare: _shareNews,
            // The title follows where the story was opened from:
            //  - a Short News card on the home screen (or a story in the
            //    "View More" feed) sets `fromShortNews`  -> "Short News";
            //  - anything else, e.g. a news item from a list or a related story
            //    opened inside this screen, leaves it off -> "News Details".
            titleKey: widget.fromShortNews ? 'shortNewsLbl' : 'newsDetailsLbl',
          ),
          Expanded(
            flex: (Platform.isAndroid) ? 12 : 9,
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller:
                      !widget.isFromBreak && !isReply ? controller : null,
                  physics: (_isShortNewsCollapsed && !comEnabled && !isReply)
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  child: Column(
                    children: [
                      _heroImage(),
                      otherMainDetails(),
                      // Keeps the last lines of the article clear of the
                      // floating action bar.
                      if (_showActionBar) const SizedBox(height: 92),
                    ],
                  ),
                ),
                if (_showActionBar)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: BlocBuilder<FontSizeCubit, FontSizeState>(
                        builder: (context, fontSizeState) {
                      return NewsDetailActionBar(
                        isFromBreak: widget.isFromBreak,
                        model: !widget.isFromBreak ? newsModel : null,
                        breakModel: widget.isFromBreak
                            ? widget.breakModel
                            : null,
                        fontVal: _effectiveFontSize(fontSizeState),
                        updateFont: _updateFontVal,
                        isPlaying: isPlaying,
                        speak: speak,
                        stop: stop,
                        updateComEnabled: updateCommentshow,
                      );
                    }),
                  ),
              ],
            ),
          ),
          // FIGMA(1500-4501): bottom-docked comment input bar, shown only while
          // the comment list is open (not in the reply view, which has its own
          // inline input). Lives outside the scroll so it stays above the
          // keyboard.
          if (!widget.isFromBreak && comEnabled && !isReply)
            CommentInputBar(newsId: newsModel!.id!),
          if ((context.read<AppConfigurationCubit>().getInAppAdsMode() ==
                  "1") ||
              _bannerAd != null)
            Flexible(child: setBannerAd(context, _bannerAd))
        ]),
      ),
    );
  }
}
