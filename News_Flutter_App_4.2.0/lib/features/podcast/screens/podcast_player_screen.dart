// Full-screen player for one episode (Routes.podcastPlayer). Playback lives in the
// app-wide PodcastPlayerCubit — opening this screen never starts it and closing
// it never stops it; only the play button does either.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_bookmark_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_player_cubit.dart';
import 'package:news/features/podcast/models/playable_audio.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';
import 'package:news/features/podcast/screens/widgets/episode_list_tile.dart';
import 'package:news/features/podcast/screens/widgets/podcast_download_action.dart';
import 'package:news/features/podcast/screens/widgets/podcast_mini_player.dart';
import 'package:news/utils/ui_utils.dart';

class PodcastPlayerData {
  final String? id;
  final String? podcastId;
  final String? audioUrl;
  final String? sourceType;
  final bool isBookmarked;

  /// True when the logged-in user owns this episode's channel. Bookmarking,
  /// following and the author row itself are all listener affordances, so they
  /// are left off the author's own player.
  final bool isAuthor;

  final String imageUrl;
  final String episodeLabel;
  final String title;
  final String description;

  final String listenersCount;

  final int? followerCount;

  final int episodeNo;
  final int durationSeconds;

  final String? publishedAt;

  final String authorName;
  final String authorImageUrl;
  final bool isFollowed;

  const PodcastPlayerData({
    this.id,
    this.podcastId,
    this.audioUrl,
    this.sourceType,
    this.isBookmarked = false,
    this.isAuthor = false,
    required this.imageUrl,
    required this.episodeLabel,
    required this.title,
    required this.description,
    required this.listenersCount,
    this.followerCount,
    this.episodeNo = 0,
    this.durationSeconds = 0,
    this.publishedAt,
    required this.authorName,
    required this.authorImageUrl,
    this.isFollowed = false,
  });

  String get dateLabel => PlayableAudio.formatDate(publishedAt);
}

class PodcastPlayerScreen extends StatefulWidget {
  final PodcastPlayerData episode;
  final List<EpisodeListTileData> episodes;

  const PodcastPlayerScreen(
      {super.key, required this.episode, required this.episodes});

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map<String, dynamic>?;
    _lastArguments = arguments;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => PodcastPlayerScreen(
        episode: arguments!['episode'] as PodcastPlayerData,
        episodes:
            (arguments['episodes'] as List<EpisodeListTileData>?) ?? const [],
      ),
    );
  }

  // What this screen was last opened with, kept so the persistent mini player
  // can re-open it on the same episode list the user came from.
  static Map<String, dynamic>? _lastArguments;

  /// Route arguments that re-open this screen on [audio].
  ///
  /// The queue auto-advances while the user is elsewhere in the app, so the
  /// episode the screen was opened with is not necessarily the one playing now.
  /// When they differ the header is rebuilt from the stored episode list, so the
  /// screen opens on what is playing rather than on a stale episode.
  static Map<String, dynamic> launchArgumentsFor(PlayableAudio audio) {
    final stored = _lastArguments;
    final episodes =
        (stored?['episodes'] as List<EpisodeListTileData>?) ?? const [];
    final storedEpisode = stored?['episode'] as PodcastPlayerData?;

    final bool storedIsCurrent = storedEpisode != null &&
        (storedEpisode.id?.isNotEmpty ?? false) &&
        storedEpisode.id == audio.id;
    if (storedIsCurrent) {
      return {'episode': storedEpisode, 'episodes': episodes};
    }

    final int index = episodes.indexWhere((row) => row.audio?.id == audio.id);
    final EpisodeListTileData? row = index < 0 ? null : episodes[index];
    final bool sameChannel = storedEpisode != null &&
        audio.podcastId != null &&
        storedEpisode.podcastId == audio.podcastId;

    return {
      'episode': PodcastPlayerData(
        id: audio.id,
        podcastId: audio.podcastId ?? storedEpisode?.podcastId,
        audioUrl: audio.url,
        sourceType: audio.sourceType,
        isBookmarked: row?.isBookmarked ?? false,
        isAuthor: sameChannel && storedEpisode.isAuthor,
        imageUrl: row?.imageUrl ?? audio.artUri ?? '',
        episodeLabel: row?.episodeLabel ?? audio.episodeLabel ?? '',
        title: row?.title ?? audio.title,
        description: row?.description ?? '',
        listenersCount: sameChannel ? storedEpisode.listenersCount : '',
        followerCount: sameChannel ? storedEpisode.followerCount : null,
        episodeNo: audio.episodeNo,
        durationSeconds: audio.durationSeconds,
        publishedAt: audio.publishedAt,
        authorName:
            sameChannel ? storedEpisode.authorName : (audio.artist ?? ''),
        authorImageUrl: sameChannel ? storedEpisode.authorImageUrl : '',
        isFollowed: sameChannel && storedEpisode.isFollowed,
      ),
      'episodes': episodes,
    };
  }

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  late PodcastPlayerData _episode = widget.episode;

  late final PodcastPlayerCubit _playerCubit =
      context.read<PodcastPlayerCubit>();

  bool get _hasAudio => _episode.audioUrl?.isNotEmpty ?? false;

  /// Whether the engine is loaded with the episode on screen. Until it is, the
  /// controls describe this episode without touching whatever else is playing.
  bool get _isCurrentEpisode =>
      _hasAudio && _playerCubit.isCurrent(_playableAudio());

  /// Auto-advance may move the header, but only once playback started here —
  /// otherwise an episode playing in the background would hijack the screen.
  bool _followsPlayer = false;

  /// Whether this episode's channel is known — the id is what following needs.
  /// It is not the author's name: an admin-created channel has none, and that
  /// is still a channel a listener can follow.
  bool get _hasChannel => _episode.podcastId?.isNotEmpty ?? false;

  // A sheet listing the one episode already on screen is noise, so it only
  // appears when there is something else to switch to.
  bool get _hasEpisodesSheet => widget.episodes.length > 1;

  late bool _isBookmarked = _episode.isBookmarked;
  late bool _isAuthor = _episode.isAuthor;
  late bool _isFollowed = _episode.isFollowed;
  late String _listenersCount = _episode.listenersCount;

  late int? _followerCount = _episode.followerCount ?? _cachedFollowerCount;

  int? get _cachedFollowerCount => context
      .read<PodcastCubit>()
      .podcastById(_episode.podcastId)
      ?.followerCount;

  /// How much of the description shows before Read more takes over.
  static const int _descriptionMaxLines = 3;

  bool _descriptionExpanded = false;

  final GlobalKey _activeRowKey = GlobalKey();

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _sheetOpen = false;
  bool _pendingActiveRowScroll = false;

  final PodcastRepository _repository = PodcastRepository();

  @override
  void initState() {
    super.initState();
    PodcastMiniPlayer.setPlayerScreenEpisode(_episode.id);
    _followsPlayer = _isCurrentEpisode;
    _sheetController.addListener(_onSheetSizeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep the mini player above the collapsed episodes sheet, not over it.
    PodcastMiniPlayer.setBottomInset(_hasEpisodesSheet
        ? MediaQuery.sizeOf(context).height * _sheetCollapsed
        : 0);
  }

  @override
  void dispose() {
    PodcastMiniPlayer.clearPlayerScreenEpisode(_episode.id);
    PodcastMiniPlayer.setBottomInset(0);
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    super.dispose();
  }

  PlayableAudio _playableAudio() => PlayableAudio(
        id: _episode.id ?? '',
        url: _episode.audioUrl ?? '',
        title: _episode.title,
        artist: _episode.authorName,
        artUri: _episode.imageUrl,
        podcastId: _episode.podcastId,
        sourceType: _episode.sourceType,
        episodeNo: _episode.episodeNo,
        durationSeconds: _episode.durationSeconds,
        publishedAt: _episode.publishedAt,
      );

  void _showEpisode(PodcastPlayerData episode, {bool scrollSheet = true}) {
    // Keep the mini player's re-open target on the episode actually showing.
    PodcastPlayerScreen._lastArguments = {
      'episode': episode,
      'episodes': widget.episodes,
    };
    PodcastMiniPlayer.setPlayerScreenEpisode(episode.id);
    setState(() {
      _episode = episode;
      _isBookmarked = episode.isBookmarked;
      _isAuthor = episode.isAuthor;
      _isFollowed = episode.isFollowed;
      _listenersCount = episode.listenersCount;
      _followerCount = episode.followerCount ?? _cachedFollowerCount;
      // A new episode's description starts collapsed, however far the previous
      // one was opened.
      _descriptionExpanded = false;
    });
    if (scrollSheet && _sheetOpen) _scrollSheetToActiveRow();
  }

  void _playFromSheet(EpisodeListTileData data) {
    final audio = data.audio;
    if (audio == null || audio.url.isEmpty) {
      showSnackBar('This episode has no audio to play', context);
      return;
    }
    _followsPlayer = true;
    _showEpisode(_headerDataFor(data, audio), scrollSheet: false);
    // Already loaded: the tap had only the header left to move.
    if (!_playerCubit.isCurrent(audio)) _startPlayback(audio);
  }

  /// The play button: loads this episode the first time, toggles from then on.
  /// A load that failed is loaded again rather than toggled — the tap is a retry.
  void _onPlayTap() {
    if (!_hasAudio) {
      showSnackBar('This episode has no audio to play', context);
      return;
    }
    if (_isCurrentEpisode && _playerCubit.state is! PodcastPlayerFailure) {
      _playerCubit.togglePlayPause();
      return;
    }
    _startPlayback(_playableAudio());
  }

  void _startPlayback(PlayableAudio audio) {
    _followsPlayer = true;
    // The queue is claimed here, not on open — browsing an episode must not
    // rewrite what the episode already playing advances into.
    _playerCubit.setQueue([
      for (final episode in widget.episodes)
        if (episode.audio != null) episode.audio!,
    ]);
    _playerCubit.play(audio);
  }

  void _onPlayerState(BuildContext context, PodcastPlayerState state) {
    if (state is PodcastPlayerFailure &&
        _hasAudio &&
        state.audio?.id == _playableAudio().id) {
      showSnackBar(state.errorMessage, context);
      return;
    }
    final PlayableAudio? audio = state is PodcastPlayerLoading
        ? state.audio
        : (state is PodcastPlayerReady ? state.audio : null);
    if (audio == null || audio.id.isEmpty) return;
    if (audio.id == _episode.id) {
      _followsPlayer = true;
      return;
    }
    if (!_followsPlayer) return;
    final index =
        widget.episodes.indexWhere((row) => row.audio?.id == audio.id);
    // The player left this screen's list — stop tracking it.
    if (index < 0) {
      _followsPlayer = false;
      return;
    }
    final row = widget.episodes[index];
    _showEpisode(_headerDataFor(row, row.audio!));
  }

  PodcastPlayerData _headerDataFor(
      EpisodeListTileData data, PlayableAudio audio) {
    final String? podcastId = audio.podcastId ?? _episode.podcastId;
    final bool sameChannel =
        podcastId != null && podcastId == _episode.podcastId;
    final channel = context.read<PodcastCubit>().podcastById(podcastId);
    return PodcastPlayerData(
      id: audio.id,
      podcastId: podcastId,
      audioUrl: audio.url,
      sourceType: audio.sourceType,
      isBookmarked: data.isBookmarked,
      isAuthor: sameChannel
          ? _isAuthor
          : (channel?.isOwnedBy(context.read<AuthCubit>().getUserId()) ??
              false),
      imageUrl: data.imageUrl,
      episodeLabel: data.episodeLabel ?? audio.episodeLabel ?? '',
      title: data.title,
      description: data.description ?? channel?.description ?? '',
      listenersCount: sameChannel
          ? _listenersCount
          : (channel == null
              ? ''
              : PodcastModel.compactCount(channel.followerCount)),
      followerCount: sameChannel ? _followerCount : channel?.followerCount,
      episodeNo: audio.episodeNo,
      durationSeconds: audio.durationSeconds,
      publishedAt: audio.publishedAt,
      authorName:
          sameChannel ? _episode.authorName : (channel?.authorName ?? ''),
      authorImageUrl:
          sameChannel ? _episode.authorImageUrl : (channel?.authorImage ?? ''),
      isFollowed: sameChannel ? _isFollowed : (channel?.isFollowed ?? false),
    );
  }

  void _onSheetSizeChanged() {
    if (!_sheetController.isAttached) return;
    final bool open = _sheetController.size > _sheetCollapsed + 0.05;
    if (open == _sheetOpen) return;
    _sheetOpen = open;
    _pendingActiveRowScroll = open;
  }

  bool _onSheetScrollEnd(ScrollEndNotification notification) {
    if (_pendingActiveRowScroll && _sheetOpen) {
      _pendingActiveRowScroll = false;
      _scrollSheetToActiveRow();
    }
    return false;
  }

  void _scrollSheetToActiveRow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rowContext = _activeRowKey.currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(rowContext,
          alignment: 0, duration: const Duration(milliseconds: 250));
    });
  }

  Future<void> _downloadFromSheet(EpisodeListTileData data) async {
    final audio = data.audio;
    if (audio == null) {
      showSnackBar('This episode has no audio to download', context);
      return;
    }
    await startEpisodeDownload(context, audio);
  }

  Future<void> _toggleFollow() async {
    final id = _episode.podcastId;
    if (id == null || id.isEmpty) return;
    if (context.read<AuthCubit>().getUserId() == "0") {
      UiUtils.loginRequired(context);
      return;
    }
    final nowFollowed = !_isFollowed;
    final previousCount = _followerCount;
    final previousLabel = _listenersCount;
    setState(() {
      _isFollowed = nowFollowed;
      if (previousCount != null) {
        final raw = previousCount + (nowFollowed ? 1 : -1);
        _followerCount = raw < 0 ? 0 : raw;
        _listenersCount = PodcastModel.compactCount(_followerCount!);
      }
    });
    final error =
        await _repository.setFollowPodcast(podcastId: id, follow: nowFollowed);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isFollowed = !nowFollowed;
        _followerCount = previousCount;
        _listenersCount = previousLabel;
      });
      showSnackBar(error, context);
      return;
    }
    context
        .read<PodcastCubit>()
        .setFollowState(podcastId: id, isFollowed: nowFollowed);
  }

  Future<void> _toggleBookmark() async {
    if (context.read<AuthCubit>().getUserId() == "0") {
      UiUtils.loginRequired(context);
      return;
    }
    final nowBookmarked = !_isBookmarked;
    setState(() => _isBookmarked = nowBookmarked);
    final error = await context.read<PodcastBookmarkCubit>().setBookmark(
          episodeId: _episode.id ?? '',
          podcastId: _episode.podcastId ?? '',
          bookmark: nowBookmarked,
        );
    if (!mounted) return;
    if (error != null) setState(() => _isBookmarked = !nowBookmarked);
    showSnackBar(
        error ??
            (nowBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks'),
        context);
  }

  static const double _sheetCollapsed = 0.11;
  static const double _sheetExpanded = 0.9;

  @override
  Widget build(BuildContext context) {
    // Builds too, not just listens: the controls switch between this episode's
    // idle state and the live one as the engine picks it up.
    return BlocConsumer<PodcastPlayerCubit, PodcastPlayerState>(
      listener: _onPlayerState,
      builder: (context, _) => _screen(context),
    );
  }

  Widget _screen(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          height: 54,
          isBackBtn: true,
          isConvertText: true,
          label: _episode.episodeLabel),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomNetworkImage(
                        networkImageUrl: _episode.imageUrl,
                        width: 267,
                        height: 267,
                        fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 17),
                _infoBlock(context),
                const SizedBox(height: 8),
                _divider(context),
                const SizedBox(height: 8),
                _metaRow(context),
                const SizedBox(height: 8),
                _divider(context),
                // The author already knows whose channel this is, and following
                // your own channel is not an action — the whole row is theirs
                // to skip.
                if (_hasChannel && !_isAuthor) ...[
                  const SizedBox(height: 8),
                  _authorRow(context),
                  const SizedBox(height: 8),
                  _divider(context),
                ],
                const SizedBox(height: 16),
                _seekBar(context),
                const SizedBox(height: 24),
                _transportControls(context),
                // Room for the collapsed sheet when it is there.
                SizedBox(height: _hasEpisodesSheet ? 120 : 24),
              ],
            ),
          ),
          if (_hasEpisodesSheet) _episodesSheet(context),
        ],
      ),
    );
  }

  Widget _infoBlock(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final String? description =
        PodcastModel.displayDescription(_episode.description);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_episode.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 34 / 22,
              letterSpacing: 0.1018,
              color: colorScheme.primaryContainer,
            )),
        // An episode with no real description keeps neither the line nor the
        // gap above it — the block ends at the title and the meta row moves up.
        if (description != null) ...[
          const SizedBox(height: 8),
          _description(context, description),
        ],
      ],
    );
  }

  Widget _description(BuildContext context, String description) {
    final colorScheme = UiUtils.getColorScheme(context);
    final TextStyle style = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 18 / 14,
      letterSpacing: 0.1018,
      color: colorScheme.primaryContainer.withOpacity(0.7),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // A description that already fits gets no toggle — measured against the
        // width it will actually be laid out at.
        final bool canExpand = _exceedsMaxLines(
            description, style, constraints.maxWidth, _descriptionMaxLines);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description,
                maxLines: _descriptionExpanded ? null : _descriptionMaxLines,
                overflow: _descriptionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: style),
            if (canExpand) ...[
              const SizedBox(height: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(
                    () => _descriptionExpanded = !_descriptionExpanded),
                child: Text(
                  UiUtils.getTranslatedLabel(context,
                      _descriptionExpanded ? 'readLessLbl' : 'readMoreLbl'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 18 / 14,
                    letterSpacing: 0.1018,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _exceedsMaxLines(
      String text, TextStyle style, double maxWidth, int maxLines) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  Widget _metaRow(BuildContext context) {
    // Downloading is a listener action — the author already has the episode.
    final bool canDownload = !_isAuthor && _playableAudio().isDownloadable;
    final String listeners = _listenersCount;
    return Row(
      children: [
        if (listeners.isNotEmpty) ...[
          _stat(context, 'podcast_listeners', listeners),
          const SizedBox(width: 8),
        ],
        _stat(context, 'calendar', _episode.dateLabel),
        const Spacer(),
        if (canDownload) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => startEpisodeDownload(context, _playableAudio()),
            child: _iconAction(context, 'podcast_download'),
          ),
          const SizedBox(width: 8),
        ],
        if (!_isAuthor) _bookmarkAction(context),
      ],
    );
  }

  Widget _bookmarkAction(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleBookmark,
      child: _iconAction(context,
          _isBookmarked ? 'podcast_bookmark' : 'podcast_bookmark_outline'),
    );
  }

  Widget _iconAction(BuildContext context, String iconName) {
    final colorScheme = UiUtils.getColorScheme(context);
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: SvgPictureWidget(
            assetName: iconName,
            width: 24.615,
            height: 24.615,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(
                colorScheme.primaryContainer, BlendMode.srcIn)),
      ),
    );
  }

  /// Author on the left, Follow on the right. A channel with no author to name
  /// (admin-created) drops that half and keeps the button.
  Widget _authorRow(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return SizedBox(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_episode.authorName.isNotEmpty)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: CustomNetworkImage(
                        networkImageUrl: _episode.authorImageUrl,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(_episode.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 16 / 16,
                          letterSpacing: 0.5,
                          color: colorScheme.primaryContainer,
                        )),
                  ),
                ],
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleFollow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isFollowed
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primaryContainer),
              ),
              child: Text(_isFollowed ? 'Unfollow' : 'Follow',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 16 / 14,
                    letterSpacing: 0.5,
                    color: _isFollowed
                        ? colorScheme.surface
                        : colorScheme.primaryContainer,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seekBar(BuildContext context) {
    // Not loaded yet: show where this episode was left off against its own
    // length, which is exactly where play() will resume from.
    if (!_isCurrentEpisode) {
      final total = Duration(seconds: _episode.durationSeconds);
      final saved = Duration(
          milliseconds: _repository.getResumePositionMs(_episode.id ?? ''));
      final position = saved > total ? total : saved;
      final totalMs = total.inMilliseconds;
      final fraction = totalMs == 0 ? 0.0 : position.inMilliseconds / totalMs;
      return _seekBarUI(context, fraction, position, total, (_) {});
    }
    return StreamBuilder<PositionData>(
      stream: _playerCubit.positionDataStream,
      initialData: _playerCubit.currentPositionData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const PositionData();
        final totalMs = data.duration.inMilliseconds;
        final fraction = totalMs == 0
            ? 0.0
            : (data.position.inMilliseconds / totalMs).clamp(0.0, 1.0);
        return _seekBarUI(
            context,
            fraction,
            data.position,
            data.duration,
            (value) => _playerCubit
                .seek(Duration(milliseconds: (value * totalMs).round())));
      },
    );
  }

  Widget _seekBarUI(BuildContext context, double fraction, Duration elapsed,
      Duration total, ValueChanged<double> onChanged) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: colorScheme.primaryContainer,
            inactiveTrackColor: colorScheme.primaryContainer.withOpacity(0.1),
            thumbColor: colorScheme.brightness == Brightness.dark
                ? Theme.of(context).primaryColor
                : colorScheme.surface,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(value: fraction.clamp(0.0, 1.0), onChanged: onChanged),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(elapsed), style: _timeStyle(context)),
              Text(_format(total), style: _timeStyle(context)),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _timeStyle(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        color:
            UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7),
      );

  String _format(Duration duration) {
    final two = (int n) => n.toString().padLeft(2, '0');
    final minutes = two(duration.inMinutes.remainder(60));
    final seconds = two(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${two(duration.inHours)}.$minutes.$seconds'
        : '$minutes.$seconds';
  }

  Widget _transportControls(BuildContext context) {
    // Skipping moves the loaded episode, so it waits until this one is loaded.
    final bool canSkip = _isCurrentEpisode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canSkip ? () => _playerCubit.skipBackward() : null,
          child: Opacity(
            opacity: canSkip ? 1 : 0.4,
            child: _transportIcon(context, 'podcast_backward'),
          ),
        ),
        const SizedBox(width: 30),
        _playButton(context),
        const SizedBox(width: 30),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canSkip ? () => _playerCubit.skipForward() : null,
          child: Opacity(
            opacity: canSkip ? 1 : 0.4,
            child: _transportIcon(context, 'podcast_forward'),
          ),
        ),
      ],
    );
  }

  Widget _playButton(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return GestureDetector(
      onTap: _onPlayTap,
      child: Opacity(
        opacity: _hasAudio ? 1 : 0.4,
        child: SizedBox(
          width: 80,
          height: 80,
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: colorScheme.primaryContainer, shape: BoxShape.circle),
              child: _playGlyph(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playGlyph(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final play = Transform.translate(
      offset: const Offset(3, 0),
      child: SvgPictureWidget(
          assetName: 'podcast_play',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
          assetColor: ColorFilter.mode(colorScheme.surface, BlendMode.srcIn)),
    );
    if (!_isCurrentEpisode) return play;
    // The enclosing BlocConsumer rebuilds this on every player state.
    final state = _playerCubit.state;
    if (state is PodcastPlayerLoading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
            strokeWidth: 2.5, color: colorScheme.surface),
      );
    }
    final playing = (state is PodcastPlayerReady) && state.playing;
    return playing
        ? Icon(Icons.pause_rounded, size: 34, color: colorScheme.surface)
        : play;
  }

  Widget _transportIcon(BuildContext context, String iconName) {
    final colorScheme = UiUtils.getColorScheme(context);
    return SizedBox(
      width: 30,
      height: 30,
      child: Center(
        child: SvgPictureWidget(
            assetName: iconName,
            width: 25,
            height: 25,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(
                colorScheme.primaryContainer, BlendMode.srcIn)),
      ),
    );
  }

  Widget _episodesSheet(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return NotificationListener<ScrollEndNotification>(
      onNotification: _onSheetScrollEnd,
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _sheetCollapsed,
        minChildSize: _sheetCollapsed,
        maxChildSize: _sheetExpanded,
        snap: true,
        snapSizes: const [_sheetCollapsed, _sheetExpanded],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 4),
              ],
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Center(child: _sheetHandle()),
                const SizedBox(height: 29),
                _episodesHeader(context),
                const SizedBox(height: 16),
                for (int i = 0; i < widget.episodes.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _sheetRow(widget.episodes[i], isActive: i == _activeRowIndex),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.28),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  int get _activeRowIndex {
    final String? id = _episode.id;
    if (id == null || id.isEmpty) return -1;
    return widget.episodes.indexWhere((row) => row.audio?.id == id);
  }

  Widget _sheetRow(EpisodeListTileData data, {required bool isActive}) {
    return EpisodeListTile(
      key: isActive ? _activeRowKey : null,
      data: data,
      isActive: isActive,
      showBookmark: !_isAuthor,
      onTap: () => _playFromSheet(data),
      // Both rows of the menu are listener actions, so the author's rows end up
      // with no menu button at all.
      onDownloadTap: _isAuthor ? null : () => _downloadFromSheet(data),
    );
  }

  Widget _episodesHeader(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: colorScheme.primaryContainer.withOpacity(0.1)),
      ),
      child: Text('Episodes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 18 / 16,
            letterSpacing: 0.1018,
            color: colorScheme.primaryContainer,
          )),
    );
  }

  Widget _divider(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Container(
        height: 1, color: colorScheme.primaryContainer.withOpacity(0.1));
  }

  Widget _stat(BuildContext context, String iconName, String value) {
    final colorScheme = UiUtils.getColorScheme(context);
    final mutedColor = colorScheme.primaryContainer.withOpacity(0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPictureWidget(
            assetName: iconName,
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(mutedColor, BlendMode.srcIn)),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 16 / 14,
              letterSpacing: 0.5,
              color: mutedColor,
            )),
      ],
    );
  }
}
