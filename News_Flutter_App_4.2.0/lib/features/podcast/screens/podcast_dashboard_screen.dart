// The listener's podcast home (Routes.podcastList): All / History / Bookmark tabs
// plus channel search. History and Bookmark are refetched whenever it reopens.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_bookmark_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_history_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_search_cubit.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';
import 'package:news/features/podcast/screens/channel_detail_screen.dart';
import 'package:news/features/podcast/screens/podcast_player_screen.dart';
import 'package:news/features/podcast/screens/widgets/episode_list_tile.dart';
import 'package:news/features/podcast/screens/widgets/podcast_card.dart';
import 'package:news/features/podcast/screens/widgets/podcast_download_action.dart';
import 'package:news/utils/ui_utils.dart';

class PodcastDashboardScreen extends StatefulWidget {
  final List<PodcastCardData> podcasts;

  const PodcastDashboardScreen({super.key, required this.podcasts});

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder: (_) => PodcastDashboardScreen(
          podcasts:
              (arguments?['podcasts'] as List<PodcastCardData>?) ?? const []),
    );
  }

  @override
  State<PodcastDashboardScreen> createState() => _PodcastDashboardScreenState();
}

class _PodcastDashboardScreenState extends State<PodcastDashboardScreen>
    with TickerProviderStateMixin {
  static const List<String> _tabs = ['All', 'History', 'Bookmark'];
  late final TabController _tabController =
      TabController(length: _tabs.length, vsync: this);

  final PodcastRepository _repository = PodcastRepository();

  late final PodcastSearchCubit _searchCubit = PodcastSearchCubit(_repository);

  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  bool get _isSearchActive =>
      _isSearching && _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    context.read<PodcastHistoryCubit>().getHistory();
    context.read<PodcastBookmarkCubit>().getBookmarks();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _searchCubit.close();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _setBookmark({
    required String episodeId,
    required String podcastId,
    required bool bookmark,
  }) async {
    if (context.read<AuthCubit>().getUserId() == "0") {
      UiUtils.loginRequired(context);
      return;
    }
    final error = await context.read<PodcastBookmarkCubit>().setBookmark(
          episodeId: episodeId,
          podcastId: podcastId,
          bookmark: bookmark,
        );
    if (!mounted) return;
    showSnackBar(
        error ?? (bookmark ? 'Added to bookmarks' : 'Removed from bookmarks'),
        context);
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    if (_tabController.index != 0) _tabController.animateTo(0);
  }

  void _closeSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _searchFocus.unfocus();
    _searchCubit.clear();
    setState(() => _isSearching = false);
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    if (value.trim().isEmpty) {
      _searchCubit.clear();
      return;
    }
    _debounce = Timer(_debounceDuration, () => _searchCubit.search(value));
  }

  void _onQuerySubmitted(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) return;
    _searchCubit.search(value);
  }

  void _openChannel(PodcastCardData podcast) {
    final channel = context.read<PodcastCubit>().podcastById(podcast.id);
    final isAuthor =
        channel?.isOwnedBy(context.read<AuthCubit>().getUserId()) ?? false;
    Navigator.of(context).pushNamed(Routes.podcastChannelDetail, arguments: {
      "channel": ChannelDetailData(
        id: podcast.id,
        slug: podcast.slug,
        imageUrl: podcast.imageUrl,
        tag: '',
        title: podcast.title,
        description: podcast.description ?? '',
        listenersCount: podcast.listenersCount,
        episodesCount: podcast.episodesCount,
        authorName: podcast.authorName,
        authorImageUrl: podcast.authorImageUrl,
        isFollowed: podcast.isFollowed,
        isAuthor: isAuthor,
      ),
    }).then((_) {
      if (!mounted) return;
      context.read<PodcastHistoryCubit>().getHistory(showProgress: false);
      context.read<PodcastBookmarkCubit>().getBookmarks(showProgress: false);
    });
  }

  void _openPlayer({
    required EpisodeModel episode,
    required PodcastModel? podcast,
    required bool isBookmarked,
    required List<EpisodeListTileData> queue,
  }) {
    final String podcastId = episode.podcastId ?? podcast?.id ?? '';
    final channel =
        podcast ?? context.read<PodcastCubit>().podcastById(podcastId);
    Navigator.of(context).pushNamed(Routes.podcastPlayer, arguments: {
      "episode": PodcastPlayerData(
        id: episode.id,
        podcastId: podcastId.isEmpty ? null : podcastId,
        isAuthor:
            channel?.isOwnedBy(context.read<AuthCubit>().getUserId()) ?? false,
        imageUrl: (episode.image?.isNotEmpty ?? false)
            ? episode.image!
            : (channel?.image ?? ''),
        audioUrl: episode.audioUrl,
        sourceType: episode.sourceType,
        isBookmarked: isBookmarked,
        episodeLabel:
            episode.episodeNo > 0 ? 'Episode - ${episode.episodeNo}' : '',
        title: episode.title ?? channel?.title ?? '',
        description: episode.description ?? channel?.description ?? '',
        listenersCount: channel == null
            ? ''
            : PodcastModel.compactCount(channel.followerCount),
        followerCount: channel?.followerCount,
        episodeNo: episode.episodeNo,
        durationSeconds: episode.durationSeconds,
        publishedAt: episode.publishedAt,
        authorName: channel?.authorName ?? '',
        authorImageUrl: channel?.authorImage ?? '',
        isFollowed: channel?.isFollowed ?? false,
      ),
      "episodes": queue,
    }).then((_) {
      if (!mounted) return;
      context.read<PodcastHistoryCubit>().getHistory(showProgress: false);
      context.read<PodcastBookmarkCubit>().getBookmarks(showProgress: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _closeSearch();
      },
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      appBar: _isSearching
          ? _searchAppBar(context)
          : CustomAppBar(
              height: 54,
              isBackBtn: true,
              isConvertText: true,
              label: 'Podcast',
              actionWidget: [
                IconButton(
                  padding: const EdgeInsetsDirectional.only(end: 7),
                  onPressed: _openSearch,
                  icon: Icon(Icons.search_rounded,
                      color: UiUtils.getColorScheme(context).primaryContainer),
                ),
              ],
            ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tabBar(context),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _scrollableTab(_podcastList(), onRefresh: _refreshPodcasts),
                  _scrollableTab(_historyList(), onRefresh: _refreshHistory),
                  _scrollableTab(_bookmarkList(), onRefresh: _refreshBookmarks),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _searchAppBar(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: UiUtils.applyBoxShadow(
        context: context,
        child: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: _onQuerySubmitted,
              style: TextStyle(color: colorScheme.primaryContainer),
              cursorColor: colorScheme.primaryContainer,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: UiUtils.getTranslatedLabel(context, 'search'),
                hintStyle: TextStyle(
                    color: colorScheme.primaryContainer.withOpacity(0.7)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          actions: [
            IconButton(
              padding: const EdgeInsetsDirectional.only(end: 7),
              onPressed: _closeSearch,
              icon: Icon(Icons.close, color: colorScheme.primaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  // Pull-to-refresh keeps the tab's own content on screen while it reloads, so
  // the spinner replaces it only on the very first load.
  Future<void> _refreshPodcasts() {
    if (_isSearchActive) return _searchCubit.search(_searchController.text);
    return context.read<PodcastCubit>().getPodcasts();
  }

  Future<void> _refreshHistory() =>
      context.read<PodcastHistoryCubit>().getHistory(showProgress: false);

  Future<void> _refreshBookmarks() =>
      context.read<PodcastBookmarkCubit>().getBookmarks(showProgress: false);

  Widget _scrollableTab(Widget child,
      {required Future<void> Function() onRefresh}) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        // A short list (or an empty one) still has to accept the drag.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: child,
      ),
    );
  }

  Widget _tabBar(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: colorScheme.surface, borderRadius: BorderRadius.circular(8)),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, _) {
          final int selected = _tabController.animation!.value.round();
          return Row(
            children: [
              for (int i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _tab(context, i, selected)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tab(BuildContext context, int index, int selectedIndex) {
    final colorScheme = UiUtils.getColorScheme(context);
    final bool isSelected = index == selectedIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(_tabs[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isSelected
                  ? colorScheme.surface
                  : colorScheme.primaryContainer,
            )),
      ),
    );
  }

  Widget _loader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget _message(String text, {VoidCallback? onTap}) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colorScheme.primaryContainer
                      .withOpacity(onTap == null ? 0.5 : 0.7))),
        ),
      ),
    );
  }

  Widget _tileColumn(List<Widget> tiles) {
    return Column(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          tiles[i],
        ],
      ],
    );
  }

  EpisodeListTileData _tileData(EpisodeModel episode, PodcastModel? podcast,
          {double? progress, bool? isBookmarked}) =>
      episode.toTileData(
        fallbackImage: podcast?.image,
        artist: podcast?.authorName,
        episodeLabel:
            episode.episodeNo > 0 ? 'Episode - ${episode.episodeNo}' : null,
        progress: progress,
        isBookmarked: isBookmarked,
      );

  Widget _episodeTile({
    required EpisodeModel episode,
    required PodcastModel? podcast,
    required EpisodeListTileData data,
    required bool isBookmarked,
    required List<EpisodeListTileData> queue,
  }) {
    final audio = episode.toPlayableAudio(
        fallbackImage: podcast?.image, artist: podcast?.authorName);
    return EpisodeListTile(
      data: data,
      onTap: () => _openPlayer(
        episode: episode,
        podcast: podcast,
        isBookmarked: isBookmarked,
        queue: queue,
      ),
      onDownloadTap: () => startEpisodeDownload(context, audio),
      onBookmarkTap: () => _setBookmark(
        episodeId: episode.id ?? '',
        podcastId: episode.podcastId ?? podcast?.id ?? '',
        bookmark: !isBookmarked,
      ),
    );
  }

  Widget _historyList() {
    return BlocBuilder<PodcastHistoryCubit, PodcastHistoryState>(
      builder: (context, state) {
        if (state is PodcastHistoryFailure) {
          return _message('Could not load history.\nTap to retry',
              onTap: () => context.read<PodcastHistoryCubit>().getHistory());
        }
        if (state is! PodcastHistorySuccess) return _loader();
        if (state.episodes.isEmpty) return _message('No history yet');

        return BlocBuilder<PodcastBookmarkCubit, PodcastBookmarkState>(
          builder: (context, _) {
            final bookmarks = context.read<PodcastBookmarkCubit>();
            final items = state.episodes;
            final tiles = [
              for (final item in items)
                _tileData(
                  item.episode,
                  item.podcast,
                  progress: item.progress,
                  isBookmarked:
                      bookmarks.isBookmarked(item.episode.id ?? ''),
                ),
            ];
            return _tileColumn([
              for (int i = 0; i < items.length; i++)
                _episodeTile(
                  episode: items[i].episode,
                  podcast: items[i].podcast,
                  data: tiles[i],
                  isBookmarked:
                      bookmarks.isBookmarked(items[i].episode.id ?? ''),
                  queue: tiles,
                ),
            ]);
          },
        );
      },
    );
  }

  Widget _bookmarkList() {
    return BlocBuilder<PodcastBookmarkCubit, PodcastBookmarkState>(
      builder: (context, state) {
        if (state is PodcastBookmarkFailure) {
          return _message('Could not load bookmarks.\nTap to retry',
              onTap: () => context.read<PodcastBookmarkCubit>().getBookmarks());
        }
        if (state is! PodcastBookmarkSuccess) return _loader();
        if (state.episodes.isEmpty) return _message('No bookmarks yet');

        return BlocBuilder<PodcastHistoryCubit, PodcastHistoryState>(
          builder: (context, _) {
            final history = context.read<PodcastHistoryCubit>();
            final items = state.episodes;
            final tiles = [
              for (final item in items)
                _tileData(
                  item.episode,
                  item.podcast,
                  // The bookmark row carries its own listening history; the
                  // History tab is only a fallback, since it is a separate
                  // request that may not have landed (or may have failed) by
                  // the time this tab is drawn.
                  progress: item.episode.listeningProgress ??
                      history.progressOf(item.episode.id ?? ''),
                  isBookmarked: true,
                ),
            ];
            return _tileColumn([
              for (int i = 0; i < items.length; i++)
                _episodeTile(
                  episode: items[i].episode,
                  podcast: items[i].podcast,
                  data: tiles[i],
                  isBookmarked: true,
                  queue: tiles,
                ),
            ]);
          },
        );
      },
    );
  }

  Widget _podcastList() {
    if (_isSearchActive) return _searchResults();
    return BlocBuilder<PodcastCubit, PodcastState>(
      // A refresh must not drop the list back to the snapshot we were opened
      // with; the indicator is already showing that work is in flight.
      buildWhen: (_, current) => current is! PodcastFetchInProgress,
      builder: (context, state) {
        final podcasts = state is PodcastFetchSuccess
            ? state.podcasts.map((p) => p.toCardData()).toList()
            : widget.podcasts;
        if (podcasts.isEmpty) return const SizedBox.shrink();
        return _cardColumn(podcasts);
      },
    );
  }

  Widget _searchResults() {
    return BlocBuilder<PodcastSearchCubit, PodcastSearchState>(
      bloc: _searchCubit,
      builder: (context, state) {
        if (state is PodcastSearchFailure) {
          return _message('Could not search podcasts.\nTap to retry',
              onTap: () => _searchCubit.search(_searchController.text));
        }
        if (state is! PodcastSearchSuccess) return _loader();
        if (state.podcasts.isEmpty) {
          return _message('No podcasts found for "${state.query}"');
        }
        return _cardColumn(state.podcasts.map((p) => p.toCardData()).toList());
      },
    );
  }

  Widget _cardColumn(List<PodcastCardData> podcasts) {
    return Column(
      children: [
        for (int i = 0; i < podcasts.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          PodcastCard(
              data: podcasts[i],
              imageSize: 93,
              onTap: () => _openChannel(podcasts[i])),
        ],
      ],
    );
  }
}
