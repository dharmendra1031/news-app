import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/reels/cubits/video_shorts_cubit.dart';
import 'package:news/features/dashboard/dashboard_screen.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/reels/widgets/reels_card.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/system_ui_helper.dart';
import 'package:news/utils/ui_utils.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => ReelsScreenState();
}

class ReelsScreenState extends State<ReelsScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  /// Page that currently owns a live player. It deliberately lags
  /// [_currentIndex]: onPageChanged fires halfway through a drag, and swapping
  /// players there tears down one video (a WebView, for YouTube reels) and
  /// builds another in the middle of the gesture, which drops frames right when
  /// the finger is still moving. Updating it on scroll-end keeps the outgoing
  /// reel playing for the whole swipe and mounts the next one once the page has
  /// settled.
  int _playerIndex = 0;

  /// Page cleared to load its video ahead of the swipe ([ReelsCard.preload]):
  /// the one after the live reel. Cleared on every swipe. The first preload
  /// after the list loads starts at once, since that is the one a quick first
  /// swipe needs. After a swipe it waits [_preloadDelay], so the reel that just
  /// landed isn't starting up while another player is being created, and a fast
  /// flick through several reels doesn't spin up a player for each one it passes.
  int? _preloadIndex;
  Timer? _preloadTimer;
  static const Duration _preloadDelay = Duration(milliseconds: 300);

  /// The reel just left, when it is the page right next to the live one. It is
  /// kept open (paused, rewound and hidden) so swiping back to it starts at
  /// once instead of loading again. Only one page behind is kept, and it is set
  /// with no delay: its player already exists, so waiting would only tear it
  /// down and rebuild it.
  int? _keepIndex;

  bool _commentsOpen = false;
  int _commentsDismissToken = 0;

  static const double bottomNavHeight = 72;

  /// Returns true when back was consumed (e.g. comments panel was open).
  bool handleBackPress() {
    if (!_commentsOpen) return false;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      setState(() {
        _commentsOpen = false;
        _commentsDismissToken++;
      });
    }
    return true;
  }

  // Reels is a bottom-nav tab, not a pushed route, so "back" means leaving the
  // tab rather than popping a route — mirrors the dashboard's own hardware
  // back-button handling for this tab (_onDashboardPopInvoked).
  void _onBackPressed() {
    if (handleBackPress()) return;
    context.findAncestorStateOfType<DashBoardState>()?.changeTab(0);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchVideoShorts();
    _schedulePreload(delay: Duration.zero);
    // Keep the system navigation bar visible and theme-coloured on Reels too,
    // matching the rest of the app. The top status bar uses light icons because
    // the reel content behind it is dark. The nav bar colour is driven by the
    // dashboard's themed overlay style (see UiUtils.overlayStyleForTheme).
    SystemUiHelper.showNavBar();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _fetchVideoShorts({bool force = false}) {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      final cubit = context.read<VideoShortsCubit>();
      if (!force && cubit.state is VideoShortsFetchSuccess) {
        reelsLog('tab opened: list already loaded, no API call');
        return;
      }
      cubit
          .getVideoShorts(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
          )
          .whenComplete(() => _schedulePreload(delay: Duration.zero));
    });
  }

  void _schedulePreload({Duration delay = _preloadDelay}) {
    if (!mounted) return;
    _preloadIndex = null;
    _preloadTimer?.cancel();
    _preloadTimer = Timer(delay, () {
      if (!mounted) return;
      reelsLog('preload: page ${_playerIndex + 1} cleared to load');
      setState(() => _preloadIndex = _playerIndex + 1);
    });
  }

  /// The list is being replaced while this screen is up (a share link opened
  /// another reel with Reels already showing). The new list starts at its first
  /// page, so the page / player indexes kept for the old one have to go too —
  /// otherwise the shared reel is built as "not the live page" and never plays.
  void _onReelsListReplaced() {
    setState(() {
      _currentIndex = 0;
      _playerIndex = 0;
      _keepIndex = null;
      _commentsOpen = false;
    });
    _schedulePreload(delay: Duration.zero);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _commentsOpen = false;
    });
    // Keep the nav bar visible while scrolling reels (flick shows both bars on
    // each reel's init; the dashboard overlay keeps it theme-coloured).
    SystemUiHelper.showNavBar();

    final cubit = context.read<VideoShortsCubit>();

    final state = cubit.state;
    if (state is VideoShortsFetchSuccess &&
        index >= state.videoShorts.length - 1) {
      cubit.loadNextBatch(
        context.read<AppLocalizationCubit>().state.languageCode,
      );
    }
  }

  /// Hands the settled page its player. Called on scroll-end so a fast
  /// multi-page flick only mounts one player, at the page it lands on.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollEndNotification &&
        _playerIndex != _currentIndex) {
      final leftIndex = _playerIndex;
      setState(() {
        _playerIndex = _currentIndex;
        _keepIndex = (leftIndex - _currentIndex).abs() == 1 ? leftIndex : null;
      });
      reelsLog('swipe landed on page $_playerIndex');
      _schedulePreload();
    }
    return false;
  }

  Future<void> _refreshVideoShorts() async {
    if (!mounted) return;
    await context.read<VideoShortsCubit>().getVideoShorts(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
        );
    _keepIndex = null;
    _schedulePreload(delay: Duration.zero);
  }

  @override
  void dispose() {
    _preloadTimer?.cancel();
    _pageController.dispose();
    // Reset to the app's default visible/edge-to-edge nav-bar mode (flick may
    // have switched the Flutter SystemUiMode while playing).
    SystemUiHelper.showNavBar();
    super.dispose();
  }

  Widget _buildBackButton(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topInset + 8,
      left: 4,
      child: GestureDetector(
        onTap: _onBackPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          BlocConsumer<VideoShortsCubit, VideoShortsState>(
            listenWhen: (_, state) => state is VideoShortsFetchInProgress,
            listener: (context, state) => _onReelsListReplaced(),
            builder: (context, state) {
              if (state is VideoShortsFetchInProgress ||
                  state is VideoShortsInitial) {
                return Center(
                  child: UiUtils.showCircularProgress(
                    true,
                    Theme.of(context).primaryColor,
                  ),
                );
              }

              if (state is VideoShortsFetchFailure) {
                return ErrorContainerWidget(
                  errorMsg:
                      state.errorMessage.contains(ErrorMessageKeys.noInternet)
                          ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                          : state.errorMessage,
                  onRetry: () => _fetchVideoShorts(force: true),
                );
              }

              if (state is VideoShortsFetchSuccess) {
                if (state.videoShorts.isEmpty) {
                  return ErrorContainerWidget(
                    errorMsg: ErrorMessageKeys.noDataMessage,
                    onRetry: () => _fetchVideoShorts(force: true),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshVideoShorts,
                  color: Theme.of(context).primaryColor,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        clipBehavior: Clip.hardEdge,
                        // Keeps the neighbouring pages built, which is what lets
                        // the next reel start loading before the swipe (see
                        // [ReelsCard.preload]). Without it a page only builds
                        // once the finger has started dragging it in.
                        allowImplicitScrolling: true,
                        physics: _commentsOpen
                            ? const NeverScrollableScrollPhysics()
                            : const PageScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                        onPageChanged: _onPageChanged,
                        itemCount: state.videoShorts.length,
                        itemBuilder: (context, index) {
                          return ReelsCard(
                            model: state.videoShorts[index],
                            isActive: index == _currentIndex,
                            canPlay: index == _playerIndex,
                            preload:
                                index == _preloadIndex || index == _keepIndex,
                            dismissCommentsToken: index == _currentIndex
                                ? _commentsDismissToken
                                : 0,
                            onCommentsVisibilityChanged: index == _currentIndex
                                ? (open) => setState(() => _commentsOpen = open)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          _buildBackButton(context),
        ],
      ),
    );
  }
}
