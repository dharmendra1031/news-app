import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:news/commons/widgets/loading_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:location/location.dart' as loc;
import 'package:marqueer/marqueer.dart';
import 'package:news/commons/widgets/ad_spaces.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/deep_link/reels_native_deep_link.dart';
import 'package:news/core/deep_link/share_deep_link.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/cubits/register_token_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/dashboard/dashboard_screen.dart';
import 'package:news/features/dashboard/widgets/app_bottom_nav_bar.dart';
import 'package:news/features/homepage/widgets/featured_section/section_style1.dart';
import 'package:news/features/homepage/widgets/featured_section/section_style2.dart';
import 'package:news/features/homepage/widgets/featured_section/section_style3.dart';
import 'package:news/features/homepage/widgets/featured_section/section_style4.dart';
import 'package:news/features/homepage/widgets/featured_section/section_style5.dart';
import 'package:news/features/homepage/widgets/featured_section/section_style6.dart';
import 'package:news/features/homepage/widgets/general_news_random_style.dart';
import 'package:news/features/homepage/widgets/live_news_home_section.dart';
import 'package:news/features/homepage/widgets/live_with_search_view.dart';
import 'package:news/features/homepage/widgets/short_news_home_section.dart';
import 'package:news/features/live_streaming/cubits/live_stream_cubit.dart';
import 'package:news/features/homepage/widgets/section_shimmer.dart';
import 'package:news/features/homepage/widgets/weather_data.dart';
import 'package:news/features/alerts/cubits/alerts_cubit.dart';
import 'package:news/features/alerts/widgets/alerts_view.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/commons/cubits/adspace/adspace_home_page_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/cubits/breaking_news_cubit.dart';
import 'package:news/features/homepage/cubits/feature_section_cubit.dart';
import 'package:news/features/homepage/cubits/general_news_cubit.dart';
import 'package:news/commons/cubits/get_user_data_by_id_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/language/cubits/language_json_cubit.dart';
import 'package:news/features/dynamic_pages/cubits/other_pages_cubit.dart';
import 'package:news/features/news/cubits/short_news_cubit.dart';
import 'package:news/features/notification/screens/push_notification_service.dart';
import 'package:news/features/profile/widgets/custom_alert_dialog.dart';
import 'package:news/commons/cubits/setting_cubit.dart';
import 'package:news/features/homepage/cubits/weather_cubit.dart';
import 'package:news/features/author/models/author_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/features/authentication/models/auth_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/podcast/cubits/podcast_cubit.dart';
import 'package:news/features/podcast/screens/channel_detail_screen.dart';
import 'package:news/features/podcast/screens/widgets/podcast_card.dart';
import 'package:news/features/podcast/screens/widgets/podcast_home_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  /// Clears the dashboard bottom bar (~60) + system inset + margin; matches scroll content bottom padding.
  static double _homeBottomNavClearance = (Platform.isIOS) ? 100 : 80.0;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late final ScrollController featuredSectionsScrollController =
      ScrollController()..addListener(hasMoreFeaturedSectionsScrollListener);

  final loc.Location _location = loc.Location();
  bool? _serviceEnabled;
  loc.PermissionStatus? _permissionGranted;
  double? lat;
  double? lon;
  bool updateList = false;
  int _selectedCategoryTagIndex = 0;
  Set<String> get locationValue =>
      SettingsLocalDataRepository().getLocationCityValues();
  late final appConfig, authConfig;
  String languageId = "14"; //set it as default language code
  String languageCode = "en"; //set it as default language code

  void getSections() {
    Future.delayed(Duration.zero, () {
      context.read<SectionCubit>().getSection(
          langCode: languageCode,
          latitude: locationValue.first,
          longitude: locationValue.last);
    }).whenComplete(() => getGeneralNews());
  }

  void getCategories() {
    Future.delayed(Duration.zero, () {
      context.read<CategoryCubit>().loadIfFailed(langCode: languageCode);
    });
  }

  void getPodcasts() {
    // Only fetch when the module is enabled from the Admin panel.
    if (context.read<AppConfigurationCubit>().getPodcastMode() != "1") return;
    Future.delayed(Duration.zero, () {
      context.read<PodcastCubit>().getPodcasts();
    });
  }

  void getLiveNews() {
    // Only fetch when the module is enabled from the Admin panel.
    if (context.read<AppConfigurationCubit>().getLiveStreamMode() != "1")
      return;
    Future.delayed(Duration.zero, () {
      context.read<LiveStreamCubit>().getLiveStream(langCode: languageCode);
    });
  }

  void getMarketAlerts() {
    // No Admin-panel flag gates this one (get_settings carries no market-alert
    // mode), so it is always fetched — an empty response hides the section.
    Future.delayed(Duration.zero, () {
      context.read<AlertsCubit>().getMarketAlerts();
    });
  }

  void getBookmark() {
    Future.delayed(Duration.zero, () {
      context.read<BookmarkCubit>().getBookmark(langCode: languageCode);
    });
  }

  void getLikeNews() {
    Future.delayed(Duration.zero, () {
      context.read<LikeAndDisLikeCubit>().getLike(langCode: languageCode);
    });
  }

  void getUserData() {
    Future.delayed(Duration.zero, () {
      context.read<GetUserByIdCubit>().getUserById();
    });
  }

  checkForAppUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.read<AppConfigurationCubit>().state
          is AppConfigurationFetchSuccess) {
        if (context.read<AppConfigurationCubit>().isUpdateRequired()) {
          openUpdateDialog();
        }
      }
    });
  }

  openUpdateDialog() {
    bool isForceUpdate =
        (context.read<AppConfigurationCubit>().getForceUpdateMode() != "" &&
                context.read<AppConfigurationCubit>().getForceUpdateMode() ==
                    "1")
            ? true
            : false;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return PopScope(
              canPop: false,
              child: CustomAlertDialog(
                  isForceAppUpdate: (isForceUpdate) ? true : false,
                  context: context,
                  yesButtonText: 'yesLbl',
                  yesButtonTextPostfix: '',
                  noButtonText: (isForceUpdate) ? 'exitLbl' : 'noLbl',
                  imageName: '',
                  titleWidget: CustomTextLabel(
                      text: (isForceUpdate)
                          ? 'forceUpdateTitleLbl'
                          : 'newVersionAvailableTitleLbl',
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: UiUtils.getColorScheme(context)
                                  .primaryContainer)),
                  messageText: context
                      .read<LanguageJsonCubit>()
                      .getTranslatedLabels((isForceUpdate)
                          ? 'forceUpdateDescLbl'
                          : 'newVersionAvailableDescLbl'),
                  onYESButtonPressed: () => UiUtils.gotoStores(context)),
            );
          });
        });
  }

  showPermissionPopup() async {
    loc.LocationData locationData;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled!) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      SettingsLocalDataRepository().setLocationCityKeys(null, null);
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    locationData = await _location.getLocation();

    // Every await above is a gap the widget can be disposed in (e.g. logout
    // navigates away with pushNamedAndRemoveUntil while this is still
    // pending). Bail before touching state or context.
    if (!mounted) return;

    setState(() {
      lat = locationData.latitude;
      lon = locationData.longitude;
    });
    getLocationPermission();

    return (locationData);
  }

  getLocationPermission() async {
    if (appConfig.getLocationWiseNewsMode() == "1") {
      SettingsLocalDataRepository().setLocationCityKeys(lat, lon);
      //update latitude,longitude - along with token
      if (context.read<SettingsCubit>().getSettings().token != '') {
        context.read<RegisterTokenCubit>().registerToken(
            fcmId: context.read<SettingsCubit>().getSettings().token,
            context: context);
        context
            .read<SettingsCubit>()
            .changeFcmToken(context.read<SettingsCubit>().getSettings().token);
      }
    } else {
      SettingsLocalDataRepository().setLocationCityKeys(null, null);
    }

    if (appConfig.getWeatherMode() == "1") {
      getWeatherData();
    }
  }

  Future<void> getWeatherData() async {
    if (lat != null && lon != null) {
      context.read<WeatherCubit>().getWeatherDetails(
          langId: (Hive.box(settingsBoxKey).get(currentLanguageCodeKey)),
          lat: lat.toString(),
          lon: lon.toString());
    }
  }

  void getBreakingNews() {
    Future.delayed(Duration.zero, () {
      context.read<BreakingNewsCubit>().getBreakingNews(langCode: languageCode);
    });
  }

  void getGeneralNews() {
    context.read<GeneralNewsCubit>().getGeneralNews(
        langCode: languageCode,
        latitude: locationValue.first,
        longitude: locationValue.last);
  }

  @override
  void initState() {
    super.initState();

    final pushNotificationService = PushNotificationService(context: context);
    pushNotificationService.initialise();

    appConfig = context.read<AppConfigurationCubit>();
    authConfig = context.read<AuthCubit>();
    languageId = context.read<AppLocalizationCubit>().state.id;
    languageCode = context.read<AppLocalizationCubit>().state.languageCode;
    getSections();
    getShortNews();
    if (appConfig.getWeatherMode() == "1" ||
        appConfig.getLocationWiseNewsMode() == "1") showPermissionPopup();
    if (authConfig.getUserId() != "0") {
      getUserData();
    }
    getCategories();
    getPodcasts();
    getLiveNews();
    getMarketAlerts();
    if (appConfig.getBreakingNewsMode() == "1") getBreakingNews();
    if (appConfig.getMaintenanceMode() == "1")
      Navigator.of(context).pushReplacementNamed(Routes.maintenance);
    getAdSpaceForHomePage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePendingShareDeepLink();
    });
  }

  Future<void> _handlePendingShareDeepLink() async {
    if (isShared != true || routeSettingsName == null) return;

    final path = ShareDeepLink.isReelsPath(routeSettingsName!)
        ? ShareDeepLink.resolveRouteName(routeSettingsName!)
        : routeSettingsName!;
    final slug = (newsSlug != null && newsSlug!.trim().isNotEmpty)
        ? newsSlug!.trim()
        : (ShareDeepLink.parseSlug(path) ??
            ShareDeepLink.parseSlug(ReelsNativeDeepLink.cachedFullUrl ?? '') ??
            '');

    isShared = false;
    if (slug.isEmpty && ShareDeepLink.isReelsPath(path)) return;
    if (!mounted) return;

    debugPrint('[ShareDeepLink] cold start -> opening $path (slug=$slug)');
    // Same screen a link tapped while the app is in the background goes
    // through. It loads the language list before resolving the link, which the
    // cold start used to skip and then silently dropped the link.
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => LoadingScreen(routeSettingsName: path, newsSlug: slug)));
  }

  @override
  void dispose() {
    featuredSectionsScrollController.dispose();
    super.dispose();
  }

  void getAdSpaceForHomePage() {
    Future.delayed(Duration.zero, () {
      context.read<AdSpaceHomePageCubit>().getAdspaceForHomePage(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          page: "home_page");
    });
  }

  void hasMoreFeaturedSectionsScrollListener() {
    if (featuredSectionsScrollController.position.atEdge) {
      //(featuredSectionsScrollController.offset >= featuredSectionsScrollController.position.maxScrollExtent && !featuredSectionsScrollController.position.outOfRange) {
      if (context.read<SectionCubit>().hasMoreSections()) {
        context.read<SectionCubit>().getMoreSections(
            langCode: languageCode,
            latitude: locationValue.first,
            longitude: locationValue.last);
      } else {
        //debugPrint("No more Featured sections to show");
      }
    }
  }

  Widget breakingNewsMarquee() {
    return BlocBuilder<BreakingNewsCubit, BreakingNewsState>(
        builder: ((context, state) {
      return (state is BreakingNewsFetchSuccess &&
              state.breakingNews.isNotEmpty)
          ? Container(
              margin: const EdgeInsets.only(top: 10),
              color: darkSecondaryColor,
              height: 32,
              child: Marqueer.builder(
                pps: 25.0,
                restartAfterInteractionDuration: const Duration(seconds: 1),
                separatorBuilder: (_, index) => Center(
                    child: Text(' ● ',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.normal))),
                itemBuilder: (context, index) {
                  var multiplier = index ~/ state.breakingNews.length;
                  var i = index;
                  if (multiplier > 0) {
                    i = index - (multiplier * state.breakingNews.length);
                  }
                  final item = state.breakingNews[i];
                  return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: CustomTextLabel(
                          text: item.title!,
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color: secondaryColor,
                                  fontWeight: FontWeight.normal)));
                },
              ),
            )
          : const SizedBox.shrink();
    }));
  }

  Widget getSectionList() {
    return BlocBuilder<GeneralNewsCubit, GeneralNewsState>(
        builder: (context, newsState) {
      return BlocBuilder<SectionCubit, SectionState>(
          builder: (context, sectionState) {
        if (sectionState is SectionFetchSuccess) {
          //if it has only one section and it doesn't have news in it  then show No data found message
          if (sectionState.section.length == 1) {
            final section = sectionState.section.first;

            final bool hasNoData = (section.newsType ==
                        newsTypeToString(NewsType.breakingNews) &&
                    section.breakNewsTotal == 0) ||
                ((section.newsType == newsTypeToString(NewsType.news) ||
                        section.newsType ==
                            newsTypeToString(NewsType.userChoice) ||
                        section.newsType ==
                            newsTypeToString(NewsType.videos)) &&
                    (section.newsTotal ?? -1) == 0) ||
                (section.newsType == newsTypeToString(NewsType.authorNews) &&
                    (section.authorNewsTotal ?? -1) == 0) ||
                (section.newsType == newsTypeToString(NewsType.rssFeedsNews) &&
                    (section.rssFeedTotal ?? -1) == 0);

            if (hasNoData) {
              return ErrorContainerWidget(
                errorMsg: ErrorMessageKeys.noDataMessage,
                onRetry: _refresh,
              );
            }
          }

          // "Video News" is rendered in its fixed slot after Podcast, so drop
          // it here — an empty list item would still add two 16px separators.
          final List<FeatureSectionModel> visibleSections = sectionState.section
              .where((section) => section.title != 'Video News')
              .toList();
          return ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              // 16px gap between feed sections.
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: ((context, index) {
                FeatureSectionModel model = visibleSections[index];
                //check for more featured sections
                if (index == visibleSections.length - 1 && index != 0) {
                  if (sectionState.hasMore) {
                    if (sectionState.hasMoreFetchError) {
                      return const SizedBox.shrink();
                    } else {
                      return Center(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0, vertical: 8.0),
                              child: UiUtils.showCircularProgress(
                                  true, Theme.of(context).primaryColor)));
                    }
                  }
                }

                // Figma places Podcast after the first page of dynamic
                // sections (banner + 4 styled sections), not right after the
                // very first one. Fall back to the last loaded section only
                // when fewer than 5 sections ever load (so index 4 is never
                // reached) — otherwise both branches fire on separate items
                // and Podcast renders twice.
                final int lastIndex = visibleSections.length - 1;
                final bool showPodcastHere = lastIndex < 4
                    ? (!sectionState.hasMore && index == lastIndex)
                    : index == 4;
                // Figma places Short News after the third dynamic section
                // (banner, news list, recent-news cards) and before Travel
                // News, with the same fall-back to the last loaded section as
                // Podcast when fewer than 3 ever load.
                final bool showShortNewsHere = lastIndex < 2
                    ? (!sectionState.hasMore && index == lastIndex)
                    : index == 2;
                return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionData(model: model),
                      if (showShortNewsHere) _buildShortNewsSection(),
                      if (showPodcastHere) ...[
                        _buildLiveNewsSection(),
                        _buildPodcastSection(),
                        _buildVideoNewsSection(),
                      ],
                    ]);
              }),
              itemCount: visibleSections.length);
        }
        if (sectionState is SectionFetchFailure) {
          if (context.read<GeneralNewsCubit>().state
              is GeneralNewsFetchSuccess) {
            return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionData(
                      newsModelList: (context.read<GeneralNewsCubit>().state
                              as GeneralNewsFetchSuccess)
                          .generalNews),
                  _buildShortNewsSection(),
                  _buildLiveNewsSection(),
                  _buildPodcastSection(),
                  _buildVideoNewsSection(),
                ]);
          } else {
            return ErrorContainerWidget(
                errorMsg: (sectionState.errorMessage
                        .contains(ErrorMessageKeys.noInternet))
                    ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                    : sectionState.errorMessage,
                onRetry: _refresh);
          }
        }
        return sectionShimmer(
            context); //state is SectionFetchInProgress || state is SectionInitial
      });
    });
  }

  Widget _buildCategorySection() {
    if (appConfig.getCategoryMode() != "1") {
      return const SizedBox.shrink();
    }

    return BlocBuilder<CategoryCubit, CategoryState>(builder: (context, state) {
      if (state is CategoryFetchFailure) {
        return ErrorContainerWidget(
            errorMsg: (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                : state.errorMessage,
            onRetry: getCategories);
      }

      if (state is! CategoryFetchSuccess) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: UiUtils.showCircularProgress(
              true, Theme.of(context).primaryColor),
        );
      }

      if (state.category.isEmpty) {
        return const SizedBox.shrink();
      }

      // Figma "main container": a compact, borderless-outer 12px-padded row
      // of filter tags (no header/"View More" — that's specific to this block).
      //
      // The 12px side padding is the ListView's own, not a Padding around it,
      // so the tags slide right up to the screen edges (the design runs the
      // last tag off the trailing edge) instead of being clipped 12px short.
      final int tagCount =
          state.category.length > 10 ? 10 : state.category.length;
      // 24px label line + 16px vertical padding + 2px outline = the 42px row,
      // growing with the text scale so a larger font doesn't clip the tags.
      final double tagRowHeight =
          MediaQuery.textScalerOf(context).scale(24.0) + 16.0 + 2.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: SizedBox(
          height: tagRowHeight,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: tagCount,
              separatorBuilder: (_, __) => const SizedBox(width: 12.0),
              itemBuilder: (context, index) {
                final CategoryModel category = state.category[index];
                // Center loosens the row's tight height so each tag keeps its
                // own: 42px outlined, 40px for the borderless selected one,
                // vertically centered in the row as in the design.
                return Center(child: _buildCategoryTag(category, index));
              }),
        ),
      );
    });
  }

  /// Short News rail (Figma node 4170:9559), which replaced the floating Short
  /// News button.
  ///
  /// PLACEMENT: after the third dynamic feed section, before Travel News — see
  /// the `showShortNewsHere` check in getSectionList().
  ///
  /// A card opens the standard Short News details screen on that item, with the
  /// remaining items following it. "View More" opens the Short News feed — the
  /// inshorts-style cards under a pinned app bar — from the first item (there is
  /// no separate Short News list screen). A failed or empty fetch (the cubit
  /// reports an empty list as a failure) simply leaves the section absent.
  Widget _buildShortNewsSection() {
    return BlocBuilder<ShortNewsCubit, ShortNewsState>(
      builder: (context, state) {
        // Hold the space with the shared sectionShimmer while loading, like
        // Podcast, so the rail loads in place.
        if (state is ShortNewsInitial || state is ShortNewsFetchInProgress) {
          return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: sectionShimmer(context));
        }
        if (state is! ShortNewsFetchSuccess || state.shortNews.isEmpty) {
          return const SizedBox.shrink();
        }
        final List<NewsModel> shortNews = state.shortNews;
        // "fromShortNews" tells the details screen this story came from Short
        // News, so its app bar reads "Short News" (regular news opened from
        // anywhere else keeps "News Details"). "shortNewsFeed" is set only by
        // "View More", which opens the card feed instead of a details screen.
        void openShortNews(int index, {bool feed = false}) {
          final List<NewsModel> newsList = List.from(shortNews)
            ..removeAt(index);
          Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
            "model": shortNews[index],
            "newsList": newsList,
            "isFromBreak": false,
            "fromShowMore": false,
            "fromShortNews": true,
            "shortNewsFeed": feed
          });
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ShortNewsHomeSection(
              shortNews: shortNews,
              onViewMoreTap: () => openShortNews(0, feed: true),
              onNewsTap: openShortNews),
        );
      },
    );
  }

  /// Live News module entry point, gated on `live_stream_mode` from the
  /// Admin panel.
  ///
  /// PLACEMENT (Figma "Live news Conatainer", node 3717:7957): directly
  /// before the Podcast Container — inserted at the same point as
  /// _buildPodcastSection(), see the `showPodcastHere` check in
  /// getSectionList().
  Widget _buildLiveNewsSection() {
    if (appConfig.getLiveStreamMode() != "1") {
      return const SizedBox.shrink();
    }

    return BlocBuilder<LiveStreamCubit, LiveStreamState>(
      builder: (context, state) {
        if (state is! LiveStreamFetchSuccess || state.liveStream.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: LiveNewsHomeSection(liveStream: state.liveStream),
        );
      },
    );
  }

  /// Podcast module entry point, gated on `podcast_mode` from the Admin panel.
  /// This is the only way into the module, so hiding it here disables Podcast
  /// app-wide.
  ///
  /// PLACEMENT (Figma "Podcast Container", node 3717:7967): after the first
  /// page of dynamic feed sections (banner + 4 styled sections), before the
  /// remaining sections — see the `showPodcastHere` check in getSectionList().
  ///
  /// "View More" opens Routes.podcastList -> PodcastDashboardScreen
  /// (All / History / Bookmark), which leads on to the channel detail and
  /// player screens. See lib/features/podcast/.
  Widget _buildPodcastSection() {
    if (appConfig.getPodcastMode() != "1") {
      return const SizedBox.shrink();
    }

    return BlocBuilder<PodcastCubit, PodcastState>(
      builder: (context, state) {
        // While loading, hold the space with the same sectionShimmer the feed
        // sections use, so the section loads in place instead of popping into
        // the layout. A failure stays silent — the section is simply absent.
        if (state is PodcastInitial || state is PodcastFetchInProgress) {
          return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: sectionShimmer(context));
        }
        if (state is! PodcastFetchSuccess || state.podcasts.isEmpty) {
          return const SizedBox.shrink();
        }
        final cards = state.podcasts.map((p) => p.toCardData()).toList();
        // Home shows only the first three (Figma 3717:7967); the rest live
        // behind "View More".
        final homeCards = cards.take(3).toList();
        // 16px gap above, same as the Categories block; the enclosing
        // ListView.separated supplies the gap down to the next section.
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: PodcastHomeSection(
              title: 'Podcast',
              podcasts: homeCards,
              onViewMoreTap: () => Navigator.of(context).pushNamed(
                  Routes.podcastList,
                  arguments: {"podcasts": cards}),
              onPodcastTap: _openPodcastChannel),
        );
      },
    );
  }

  /// Video News module entry point — sourced from the same dynamic feed
  /// sections as the styled cards (SectionCubit's "Video News" entry), but
  /// pulled out of its natural list position (hidden in [sectionData]) and
  /// pinned in a fixed slot right after Podcast.
  ///
  /// PLACEMENT (Figma "Video Container", node 3717:7975): directly after the
  /// Podcast Container.
  Widget _buildVideoNewsSection() {
    return BlocBuilder<SectionCubit, SectionState>(
      builder: (context, state) {
        if (state is! SectionFetchSuccess) return const SizedBox.shrink();

        FeatureSectionModel? videoNewsModel;
        for (final section in state.section) {
          if (section.title == 'Video News') {
            videoNewsModel = section;
            break;
          }
        }
        if (videoNewsModel == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _styleSectionContent(model: videoNewsModel, isVideoRail: true),
        );
      },
    );
  }

  /// Figma "Tag": pill-style filter chip. The selected tag fills with the
  /// inverse surface/text pair; others stay outlined in border/default.
  Widget _buildCategoryTag(CategoryModel category, int index) {
    final colorScheme = UiUtils.getColorScheme(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = index == _selectedCategoryTagIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryTagIndex = index);
        Navigator.of(context).pushNamed(Routes.subCat, arguments: {
          "catId": category.id,
          "catName": category.categoryName
        });
      },
      child: Container(
        // No `alignment` here: it would stretch the tag to the row's full
        // height, undoing the 40px / 42px sizing from the design.
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color:
              isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(4.0),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? darkBorderDefaultColor : borderDefaultColor,
                  width: 1.0),
        ),
        child: CustomTextLabel(
            text: category.categoryName ?? "",
            textStyle: TextStyle(
              fontSize: 16.0,
              height: 24 / 16,
              // Figma splits the 24px line's spare space evenly above and
              // below the glyphs; Flutter's default weights it toward the top,
              // which sat the label ~1.5px low in the tag.
              leadingDistribution: TextLeadingDistribution.even,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? colorScheme.surface
                  : colorScheme.primaryContainer,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget sectionData(
      {FeatureSectionModel? model, List<NewsModel>? newsModelList}) {
    // Rendered in a fixed slot after Podcast instead — see
    // _buildVideoNewsSection().
    if (model?.title == 'Video News') return const SizedBox.shrink();
    return _styleSectionContent(model: model, newsModelList: newsModelList);
  }

  /// The ad-space + styleApp-driven rendering shared by every section in the
  /// dynamic feed. Split out of [sectionData] so "Video News" can reuse the
  /// exact same styled rendering (whatever styleApp the Admin panel has it
  /// set to) from its fixed slot after Podcast, without going through the
  /// in-place hide.
  ///
  /// [isVideoRail] marks the Video News slot, so style_5 draws the Figma play
  /// icon even when the section is backed by RSS items.
  Widget _styleSectionContent(
      {FeatureSectionModel? model,
      List<NewsModel>? newsModelList,
      bool isVideoRail = false}) {
    return (model != null)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (model.adSpaceDetails != null) ...[
                AdSpaces(adsModel: model.adSpaceDetails!), //sponsored ads
                // 16px gap between the sponsored block and the section content.
                const SizedBox(height: 16),
              ],
              if (model.styleApp == 'style_1') Style1Section(model: model),
              if (model.styleApp == 'style_2') Style2Section(model: model),
              if (model.styleApp == 'style_3') Style3Section(model: model),
              if (model.styleApp == 'style_4') Style4Section(model: model),
              if (model.styleApp == 'style_5')
                Style5Section(model: model, isVideoRail: isVideoRail),
              if (model.styleApp == 'style_6') Style6Section(model: model),
            ],
          )
        : GeneralNewsRandomStyle(modelList: newsModelList!);
  }

  //refresh function to refresh page
  Future<void> _refresh() async {
    getSections();
    getLocationPermission();
    if (authConfig.getUserId() != "0") {
      getUserData();
      getBookmark();
      getLikeNews();
    }
    getCategories();
    getPodcasts();
    getLiveNews();
    getMarketAlerts();
    getPages();
    getShortNews();
    if (appConfig.getBreakingNewsMode() == "1") getBreakingNews();
    if (appConfig.getMaintenanceMode() == "1")
      Navigator.of(context).pushReplacementNamed(Routes.maintenance);
    if (appConfig.getWeatherMode() == "1") getWeatherData();
    getAdSpaceForHomePage();
  }

  getPages() {
    Future.delayed(Duration.zero, () {
      context.read<OtherPageCubit>().getOtherPage(
          langCode: languageCode,
          defaultLangCode:
              context.read<AppConfigurationCubit>().getDefaultLanguageCode());
    });
  }

  getShortNews() {
    Future.delayed(Duration.zero, () {
      context.read<ShortNewsCubit>().fetchShortNews(langCode: languageCode);
    });
  }

  /// Opens the tapped podcast's channel detail screen (also reachable from the
  /// dashboard "All" tab). The channel screen fetches its own episodes by slug.
  void _openPodcastChannel(PodcastCardData card) {
    Navigator.of(context).pushNamed(Routes.podcastChannelDetail, arguments: {
      "channel": ChannelDetailData(
        id: card.id,
        slug: card.slug,
        imageUrl: card.imageUrl,
        tag: '',
        title: card.title,
        description: card.description ?? '',
        listenersCount: card.listenersCount,
        episodesCount: card.episodesCount,
        authorName: card.authorName,
        authorImageUrl: card.authorImageUrl,
        isFollowed: card.isFollowed,
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Figma "Home Screen" (node 3717:7871), light mode: the frame fill is
      // Surface/Transparent = #FFFFFF, not the app-wide light scaffold grey.
      // Dark mode keeps inheriting the theme's scaffold colour.
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : secondaryColor,
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _refresh(),
        child: BlocListener<GetUserByIdCubit, GetUserByIdState>(
          bloc: context.read<GetUserByIdCubit>(),
          listener: (context, state) {
            if (state is GetUserByIdFetchSuccess) {
              var data = state.result;
              if (data[STATUS] == 0) {
                showSnackBar(UiUtils.getTranslatedLabel(context, 'deactiveMsg'),
                    context);
                Future.delayed(const Duration(seconds: 2), () {
                  UiUtils.userLogOut(contxt: context);
                });
              } else {
                authConfig.updateDetails(
                    authModel: AuthModel(
                        id: data[ID].toString(),
                        name: data[NAME],
                        status: data[STATUS].toString(),
                        mobile: data[MOBILE],
                        email: data[EMAIL],
                        // Keep the stored login provider when the response omits
                        // it; logout needs it to pick the provider to sign out.
                        type: data[TYPE] ?? authConfig.getType(),
                        profile: data[PROFILE],
                        // role: data[ROLE].toString(),
                        jwtToken: data[TOKEN],
                        isAuthor: data[IS_AUTHOR],
                        authorDetails: (data.containsKey(AUTHOR) &&
                                // data[IS_AUTHOR] == 1 &&
                                data[AUTHOR] != null &&
                                data[AUTHOR] != "null" &&
                                data[AUTHOR] != "")
                            ? Author.fromJson(data[AUTHOR])
                            : null));
              }
            }
          },
          child: BottomNavScrollHider(
            child: SingleChildScrollView(
              controller: featuredSectionsScrollController,
              physics:
                  ClampingScrollPhysics(), //To restrict scrolling on Refresh
              child: Column(
                children: [
                  Padding(
                    // The page has no AppBar/SafeArea (edge-to-edge), so the
                    // search bar must clear the status bar itself. 30 was
                    // enough for a slim status bar, but notch / punch-hole /
                    // Dynamic Island devices have a taller inset, so grow with
                    // it and keep 30 as the minimum.
                    padding: EdgeInsetsDirectional.only(
                        start: 16.0,
                        end: 16.0,
                        top: math.max(
                            30.0, MediaQuery.paddingOf(context).top + 8)),
                    child: Column(
                      children: [
                        const LiveWithSearchView(),
                        BlocBuilder<WeatherCubit, WeatherState>(
                            builder: (context, state) {
                          if (state is WeatherFetchSuccess) {
                            return WeatherDataView(
                                weatherData: state.weatherData);
                          }
                          return SizedBox.shrink();
                        }),
                        // Market alerts (get_market_alerts) shown directly below
                        // the Weather Forecast. There is no Admin-panel flag for
                        // this section — an empty list is what hides it. Only the
                        // first two fit the row; "View More" opens the full list
                        // (Routes.alertsList -> AlertsScreen), which reads the
                        // same already-fetched AlertsCubit list.
                        BlocBuilder<AlertsCubit, AlertsState>(
                            builder: (context, state) {
                          if (state is AlertsFetchSuccess &&
                              state.alerts.isNotEmpty) {
                            return AlertsView(
                                alerts: state.alerts.take(2).toList(),
                                onViewMore: () => Navigator.of(context)
                                    .pushNamed(Routes.alertsList));
                          }
                          return SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                  // breakingNewsMarquee(),
                  // Figma: the category tag row sits right after Alerts and
                  // before the first feed section, not after it. The two
                  // Figma frames butt together with no gap between them —
                  // AlertsView's own 8px bottom padding plus this section's
                  // 12px top padding already add up to the full spacing, so
                  // no extra SizedBox is needed here.
                  _buildCategorySection(),
                  Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 16.0,
                        end: 16.0,
                        bottom: MediaQuery.viewPaddingOf(context).bottom +
                            _homeBottomNavClearance,
                      ),
                      child: Column(
                        children: [
                          BlocBuilder<AdSpaceHomePageCubit,
                              AdSpaceHomePageState>(
                            builder: (context, state) {
                              return (state is AdSpaceHomePageFetchSuccess &&
                                      state.adSpaceTopData != null)
                                  // 16px gap below the top ad to keep the same
                                  // rhythm as the gap between feed sections.
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AdSpaces(
                                            adsModel: state.adSpaceTopData!),
                                        const SizedBox(height: 16),
                                      ],
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                          // The Podcast section lives inside getSectionList()
                          // itself — see _buildPodcastSection().
                          getSectionList(),
                          BlocBuilder<AdSpaceHomePageCubit,
                              AdSpaceHomePageState>(
                            builder: (context, state) {
                              return (state is AdSpaceHomePageFetchSuccess &&
                                      state.adSpaceBottomData != null)
                                  // 16px gap above the bottom ad to keep the same
                                  // rhythm as the gap between feed sections.
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        AdSpaces(
                                            adsModel: state.adSpaceBottomData!),
                                      ],
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
