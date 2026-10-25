import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/features/app_open_ads/app_open_ad_manager.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/dashboard/widgets/app_bottom_nav_bar.dart';
import 'package:news/features/homepage/screens/homepage.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/commons/cubits/news_by_id_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/commons/cubits/theme_cubit.dart';
import 'package:news/features/podcast/screens/widgets/podcast_mini_player.dart';
import 'package:news/features/profile/profile_screen.dart';
import 'package:news/features/reels/screens/reels_screen.dart';
import 'package:news/features/rss_feed/screens/rssfeed_screen.dart';
import 'package:news/features/videos/screens/video_screen.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';

GlobalKey<HomeScreenState>? homeScreenKey;
GlobalKey<ReelsScreenState>? reelsScreenKey;
bool? isNotificationReceivedInbg, isShared;
String? notificationNewsId;
String? saleNotification;
String? routeSettingsName, newsSlug;
String? pendingDashboardTab;

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  DashBoardState createState() => DashBoardState();

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const DashBoard());
  }
}

class DashBoardState extends State<DashBoard> {
  List<Widget> fragments = [];
  DateTime? currentBackPressTime;
  int _selectedIndex = 0;
  int _reelsIndex = -1;
  List<String> iconList = [];
  List<String> itemName = [];
  bool shouldPopScope = false;

  late final AppOpenAdManager _appOpenAdManager;
  late final AppLifecycleReactor _appLifecycleReactor;

  @override
  void initState() {
    homeScreenKey = GlobalKey<HomeScreenState>();
    reelsScreenKey = GlobalKey<ReelsScreenState>();
    iconList = [
      "home",
      "video",
      //Add only if Reels Mode is enabled From Admin panel.
      if (context.read<AppConfigurationCubit>().getReelsMode() == "1") "reels",
      if (context.read<AppConfigurationCubit>().getRSSFeedMode() == "1") "rss",
      "profile",
    ];
    itemName = [
      'homeLbl',
      'videosLbl',
      if (context.read<AppConfigurationCubit>().getReelsMode() == "1")
        'reelsLbl',
      if (context.read<AppConfigurationCubit>().getRSSFeedMode() == "1")
        'rssFeed',
      'profile'
    ];
    fragments = [
      HomeScreen(key: homeScreenKey),
      const VideoScreen(),
      //Add only if Reels Mode is enabled From Admin panel.
      if (context.read<AppConfigurationCubit>().getReelsMode() == "1")
        ReelsScreen(key: reelsScreenKey),
      //const CategoryScreen(),
      if (context.read<AppConfigurationCubit>().getRSSFeedMode() == "1")
        RSSFeedScreen(),
      const ProfileScreen(),
    ];
    _reelsIndex = fragments.indexWhere((w) => w is ReelsScreen);
    if (pendingDashboardTab == 'reels' && _reelsIndex != -1) {
      _selectedIndex = _reelsIndex;
      pendingDashboardTab = null;
    }
    checkForPengingNotifications();
    checkMaintenanceMode();

    _appOpenAdManager = AppOpenAdManager(context.read<AppConfigurationCubit>())
      ..loadAd();
    _appLifecycleReactor = AppLifecycleReactor(
      appOpenAdManager: _appOpenAdManager,
    )..listenToAppStateChanges();

    super.initState();
  }

  void checkMaintenanceMode() {
    if (context.read<AppConfigurationCubit>().getMaintenanceMode() == "1") {
      //app is in maintenance mode - no function should be performed
      Navigator.of(context).pushReplacementNamed(Routes.maintenance);
    }
  }

  void checkForPengingNotifications() async {
    if (isNotificationReceivedInbg != null &&
        notificationNewsId != null &&
        notificationNewsId != "0" &&
        isNotificationReceivedInbg!) {
      context
          .read<NewsByIdCubit>()
          .getNewsById(
              newsId: notificationNewsId!,
              langCode: context.read<AppLocalizationCubit>().state.languageCode)
          .then((value) {
        if (value.isNotEmpty) {
          Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
            "model": value[0],
            "isFromBreak": false,
            "fromShowMore": false
          });
        }
      });
    }
  }

  void openReelsTab() {
    if (_reelsIndex != -1) {
      bottomNavExpanded.value = true;
      setState(() => _selectedIndex = _reelsIndex);
    }
  }

  void changeTab(int index) {
    if (index >= 0 && index < fragments.length) {
      // A tab may have shrunk the bar; every tab starts with it at full size.
      bottomNavExpanded.value = true;
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// Returns the fragments list with the Reels tab replaced by an empty
  /// placeholder whenever it isn't the active tab. Swapping the widget at
  /// the reels index causes [IndexedStack] to dispose the previous
  /// [ReelsScreen] (and its [VideoPlayContainer]) so playback fully stops
  /// on tab change, then re-mounts when the user returns to the tab.
  List<Widget> _buildActiveFragments() {
    if (_reelsIndex == -1 || _selectedIndex == _reelsIndex) {
      return fragments;
    }
    final active = List<Widget>.from(fragments);
    active[_reelsIndex] = const SizedBox.shrink();
    return active;
  }

  /// Handles Android system back / iOS back gesture for all dashboard tabs.
  void _onDashboardPopInvoked(bool didPop) {
    if (didPop) return;

    if (_selectedIndex == _reelsIndex && _reelsIndex != -1) {
      final handled = reelsScreenKey?.currentState?.handleBackPress() ?? false;
      if (handled) return;
    }

    if (_selectedIndex != 0) {
      bottomNavExpanded.value = true;
      setState(() {
        _selectedIndex = 0;
        shouldPopScope = false;
      });
      return;
    }

    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      showSnackBar(UiUtils.getTranslatedLabel(context, 'exitWR'), context);
      setState(() => shouldPopScope = false);
      return;
    }

    setState(() => shouldPopScope = true);
  }

  Widget bottomBar() {
    // Shrinks while any tab is scrolled toward its end and returns to full size
    // on scroll-back, driven by [bottomNavExpanded] (see the
    // [BottomNavScrollHider] around the tab body in build()). Reels included: it
    // follows the same scroll rule as every other tab.
    return BottomNavShrinkTransition(
      child: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: changeTab,
        items: [
          for (var i = 0; i < iconList.length; i++)
            AppBottomNavBarItemData.forKey(iconList[i], labelKey: itemName[i]),
        ],
      ),
    );
  }

  SystemUiOverlayStyle dashboardOverlayStyle() {
    // The bar floats, so the system navigation area behind it reads as the
    // screen background rather than a bar colour.
    final navBarColor = Theme.of(context).scaffoldBackgroundColor;
    final iconBrightness =
        ThemeData.estimateBrightnessForColor(navBarColor) == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
    final appTheme = context.read<ThemeCubit>().state.appTheme;

    return UiUtils.overlayStyleForTheme(appTheme).copyWith(
      systemNavigationBarColor: navBarColor,
      systemNavigationBarDividerColor: navBarColor,
      systemNavigationBarIconBrightness: iconBrightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  @override
  void dispose() {
    _appLifecycleReactor.dispose();
    _appOpenAdManager.dispose();
    PodcastMiniPlayer.setSuppressed(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The Reels tab runs immersive (it hides the system navigation bar), so the
    // podcast mini player stands down while it is the active tab rather than
    // floating over the video.
    PodcastMiniPlayer.setSuppressed(
        _reelsIndex != -1 && _selectedIndex == _reelsIndex);
    // Must subscribe to the inset (`viewInsetsOf`). Reading it off
    // `View.of(context)` doesn't rebuild on keyboard changes, so a dashboard
    // first built while the keyboard was still closing (Skip / social login
    // pushing home with a login field focused) kept `keyboardOpen == true`
    // forever and never mounted the bottom bar.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: shouldPopScope,
      onPopInvoked: _onDashboardPopInvoked,
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Future.delayed(Duration.zero, () {
              context.read<BookmarkCubit>().getBookmark(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode);
              context.read<LikeAndDisLikeCubit>().getLike(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode);
            });
          }
        },
        builder: (context, state) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: dashboardOverlayStyle(),
            child: Scaffold(
              extendBody: true,
              extendBodyBehindAppBar: true,
              // backgroundColor: UiUtils.getColorScheme(context).secondary,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              bottomNavigationBar: keyboardOpen ? null : bottomBar(),
              // Keep the loaded tab content mounted at all times. Losing the
              // internet connection no longer wipes the whole dashboard — the
              // already-loaded data stays visible. Only an actual failed API
              // call (refresh, pagination, or opening a not-yet-loaded screen)
              // surfaces a "No Internet" error, and only on that screen/action.
              //
              // One scroll listener over the whole tab body keeps the bottom
              // bar's shrink/restore identical on every tab, Reels included.
              body: BottomNavScrollHider(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _buildActiveFragments(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
