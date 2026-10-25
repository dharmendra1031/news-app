// Podcast channel detail (Routes.podcastChannelDetail): header plus the channel's
// paged episode list, all from one `get_episode` call.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/podcast/cubits/manage_episode_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_bookmark_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_cubit.dart';
import 'package:news/features/podcast/cubits/podcast_episodes_cubit.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';
import 'package:news/features/podcast/screens/podcast_player_screen.dart';
import 'package:news/features/podcast/screens/widgets/episode_list_tile.dart';
import 'package:news/features/podcast/screens/widgets/podcast_download_action.dart';
import 'package:news/features/podcast/screens/widgets/podcast_owner_menu.dart';
import 'package:news/utils/ui_utils.dart';

class ChannelDetailData {
  final String? id;
  final String? slug;
  final String imageUrl;
  final String tag;
  final String title;
  final String description;
  final String listenersCount;
  final String episodesCount;
  final String authorName;
  final String authorImageUrl;
  final bool isFollowed;

  /// Set by callers that already know the user owns this channel (My Podcasts),
  /// so the listener-only header never flashes before `get_episode` answers.
  /// Ownership is still settled by that response for every other entry point.
  final bool isAuthor;

  const ChannelDetailData({
    this.id,
    this.slug,
    required this.imageUrl,
    required this.tag,
    required this.title,
    required this.description,
    required this.listenersCount,
    required this.episodesCount,
    required this.authorName,
    required this.authorImageUrl,
    this.isFollowed = false,
    this.isAuthor = false,
  });

  ChannelDetailData copyWith({
    String? imageUrl,
    String? title,
    String? description,
    String? listenersCount,
    String? episodesCount,
    String? authorName,
    String? authorImageUrl,
    bool? isFollowed,
  }) =>
      ChannelDetailData(
        id: id,
        slug: slug,
        imageUrl: imageUrl ?? this.imageUrl,
        tag: tag,
        title: title ?? this.title,
        description: description ?? this.description,
        listenersCount: listenersCount ?? this.listenersCount,
        episodesCount: episodesCount ?? this.episodesCount,
        authorName: authorName ?? this.authorName,
        authorImageUrl: authorImageUrl ?? this.authorImageUrl,
        isFollowed: isFollowed ?? this.isFollowed,
        isAuthor: isAuthor,
      );
}

class ChannelDetailScreen extends StatefulWidget {
  final ChannelDetailData channel;

  const ChannelDetailScreen({super.key, required this.channel});

  static Route<dynamic> route(RouteSettings settings) {
    final arguments = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder: (_) => ChannelDetailScreen(
          channel: arguments!['channel'] as ChannelDetailData),
    );
  }

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  final PodcastRepository _repository = PodcastRepository();

  late ChannelDetailData _channel = widget.channel;
  ChannelDetailData get channel => _channel;

  bool get _isFollowed => _channel.isFollowed;

  /// True when the logged-in user owns the channel being viewed. The owner id
  /// comes from the same `get_episode` response the episodes do, so it holds
  /// however this screen was reached — including a shared deep link.
  ///
  /// Authors get their own channel without the listener affordances: their name
  /// tells them nothing they don't know, and following or sharing their own
  /// channel is not something they do from here.
  late bool _isAuthor = widget.channel.isAuthor;

  /// ManageEpisodeCubit is app-wide, so its states also carry writes made on
  /// other screens. Only a delete started here should refresh this list.
  bool _deleteRequested = false;

  int? _followerCount;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(_hasMoreEpisodesScrollListener);

  @override
  void initState() {
    super.initState();
    final slug = channel.slug;
    if (slug != null && slug.isNotEmpty) {
      context
          .read<PodcastEpisodesCubit>()
          .getEpisodes(slug, isAuthorCheck: _isAuthor);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _hasMoreEpisodesScrollListener() {
    if (_scrollController.offset < _scrollController.position.maxScrollExtent ||
        _scrollController.position.outOfRange) {
      return;
    }
    if (context.read<PodcastEpisodesCubit>().hasMoreEpisodes()) {
      _loadMoreEpisodes();
    }
  }

  void _loadMoreEpisodes() {
    final slug = channel.slug;
    if (slug == null || slug.isEmpty) return;
    context
        .read<PodcastEpisodesCubit>()
        .getMoreEpisodes(slug, isAuthorCheck: _isAuthor);
  }

  void _applyChannel(PodcastModel podcast) {
    final bool newIsAuthor =
        podcast.isOwnedBy(context.read<AuthCubit>().getUserId());
    final bool authorBecameTrue = !_isAuthor && newIsAuthor;
    setState(() {
      _isAuthor = newIsAuthor;
      _followerCount = podcast.followerCount;
      _channel = _channel.copyWith(
        imageUrl: podcast.image,
        title: podcast.title,
        description: podcast.description,
        listenersCount: PodcastModel.compactCount(podcast.followerCount),
        episodesCount: podcast.episodeCount.toString(),
        authorName: podcast.authorName,
        authorImageUrl: podcast.authorImage,
        isFollowed: podcast.hasFollowState ? podcast.isFollowed : null,
      );
    });
    if (authorBecameTrue) {
      _reloadEpisodes();
    }
  }

  void _syncFollowFromList() {
    final id = channel.id;
    if (id == null || id.isEmpty) return;
    final state = context.read<PodcastCubit>().state;
    if (state is! PodcastFetchSuccess) return;
    for (final podcast in state.podcasts) {
      if (podcast.id != id) continue;
      setState(() {
        _followerCount = podcast.followerCount;
        _channel = _channel.copyWith(
          listenersCount: PodcastModel.compactCount(podcast.followerCount),
          isFollowed: podcast.isFollowed,
        );
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final String? description =
        PodcastModel.displayDescription(channel.description);
    return Scaffold(
      appBar: CustomAppBar(
          height: 54,
          isBackBtn: true,
          isConvertText: true,
          label: 'Podcast',
          actionWidget: _isAuthor
              ? null
              : [_shareButton(context), const SizedBox(width: 16)]),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PodcastEpisodesCubit, PodcastEpisodesState>(
            listenWhen: (_, current) =>
                current is PodcastEpisodesSuccess && current.podcast != null,
            listener: (context, state) =>
                _applyChannel((state as PodcastEpisodesSuccess).podcast!),
          ),
          BlocListener<ManageEpisodeCubit, ManageEpisodeState>(
            listener: _onEpisodeDeleted,
          ),
        ],
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomNetworkImage(
                      networkImageUrl: channel.imageUrl,
                      width: 267,
                      height: 267,
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              if (channel.tag.isNotEmpty) ...[
                _tag(context),
                const SizedBox(height: 8),
              ],
              Text(channel.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 18 / 16,
                    letterSpacing: 0.1018,
                    color: colorScheme.primaryContainer,
                  )),
              // A placeholder description ("-") counts as no description: the
              // line and its gap both go, and the stats row moves up.
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(description,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 18 / 14,
                      letterSpacing: 0.1018,
                      color: colorScheme.primaryContainer.withOpacity(0.7),
                    )),
              ],
              const SizedBox(height: 8),
              _divider(context),
              const SizedBox(height: 8),
              Row(
                children: [
                  _stat(context, 'podcast_listeners', channel.listenersCount),
                  const SizedBox(width: 8),
                  _stat(context, 'podcast_episodes', channel.episodesCount),
                ],
              ),
              // Listeners always get this row for the Follow button; whether it
              // also names an author is [_authorRow]'s business.
              if (!_isAuthor) ...[
                const SizedBox(height: 8),
                _divider(context),
                const SizedBox(height: 12),
                _authorRow(context),
              ],
              const SizedBox(height: 12),
              _divider(context),
              const SizedBox(height: 16),
              _episodesHeader(context),
              const SizedBox(height: 16),
              _episodesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _episodesSection(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return BlocBuilder<PodcastEpisodesCubit, PodcastEpisodesState>(
      builder: (context, state) {
        if (state is PodcastEpisodesInProgress) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is PodcastEpisodesFailure) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: Text(state.errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: colorScheme.primaryContainer.withOpacity(0.7)))),
          );
        }
        if (state is PodcastEpisodesSuccess) {
          if (state.episodes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: Text('No episodes yet',
                      style: TextStyle(
                          color:
                              colorScheme.primaryContainer.withOpacity(0.5)))),
            );
          }
          // Everything author-only hangs off [_isAuthor], settled by the same
          // response these episodes came in, so a listener's screen is built
          // exactly as before.
          final PodcastModel? podcast = state.podcast;
          return Column(
            children: [
              for (int i = 0; i < state.episodes.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                EpisodeListTile(
                  data: state.episodes[i].toTileData(
                      fallbackImage: channel.imageUrl,
                      artist: channel.authorName,
                      episodeLabel: 'Episode - ${state.episodes[i].episodeNo}'),
                  // Playing is not a listener-only action — the author gets the
                  // player on their own episodes too, just without the
                  // bookmark / follow affordances inside it.
                  onTap: () => _openPlayer(state.episodes, i),
                  showBookmark: !_isAuthor,
                  onBookmarkTap: _isAuthor
                      ? null
                      : () => _toggleBookmark(state.episodes[i]),
                  onDownloadTap:
                      _isAuthor ? null : () => _download(state.episodes[i]),
                  // Supplying the owner menu takes the row's Download and
                  // Bookmark off the author's rows along with it.
                  trailing: _isAuthor && podcast != null
                      ? PodcastOwnerMenu(
                          onEdit: () =>
                              _editEpisode(podcast, state.episodes[i]),
                          onDelete: () => _deleteEpisode(state.episodes[i]),
                        )
                      : null,
                ),
              ],
              if (state.hasMore) _moreEpisodesIndicator(context, state),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _moreEpisodesIndicator(
      BuildContext context, PodcastEpisodesSuccess state) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: state.hasMoreFetchError
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _loadMoreEpisodes,
                child: Text('Tap to load more',
                    style: TextStyle(
                        color: colorScheme.primaryContainer.withOpacity(0.7))),
              )
            : const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Future<void> _editEpisode(PodcastModel podcast, EpisodeModel episode) async {
    final saved = await Navigator.of(context).pushNamed(Routes.createEpisode,
        arguments: {"podcast": podcast, "episode": episode});
    if (saved != true || !mounted) return;
    _reloadEpisodes();
  }

  Future<void> _deleteEpisode(EpisodeModel episode) async {
    if (episode.id == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: UiUtils.getColorScheme(dialogContext).surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        title: const CustomTextLabel(text: 'deleteEpisodeLbl'),
        titleTextStyle: Theme.of(dialogContext)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w600),
        content: CustomTextLabel(
            text: 'doYouReallyEpisodeLbl',
            textStyle: Theme.of(dialogContext).textTheme.titleMedium),
        actions: <Widget>[
          CustomTextButton(
              textWidget: CustomTextLabel(
                  text: 'noLbl', textStyle: _dialogActionStyle(dialogContext)),
              onTap: () => Navigator.of(dialogContext).pop(false)),
          CustomTextButton(
              textWidget: CustomTextLabel(
                  text: 'yesLbl', textStyle: _dialogActionStyle(dialogContext)),
              onTap: () => Navigator.of(dialogContext).pop(true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _deleteRequested = true;
    context.read<ManageEpisodeCubit>().deleteEpisode(episodeId: episode.id!);
  }

  void _onEpisodeDeleted(BuildContext context, ManageEpisodeState state) {
    if (!_deleteRequested) return;
    if (state is ManageEpisodeSuccess) {
      _deleteRequested = false;
      showSnackBar(state.message, context);
      _reloadEpisodes();
    }
    if (state is ManageEpisodeFailure) {
      _deleteRequested = false;
      showSnackBar(state.errorMessage, context);
    }
  }

  TextStyle? _dialogActionStyle(BuildContext dialogContext) =>
      Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
          color: UiUtils.getColorScheme(dialogContext).primaryContainer,
          fontWeight: FontWeight.bold);

  void _reloadEpisodes() {
    final slug = channel.slug;
    if (slug == null || slug.isEmpty) return;
    context
        .read<PodcastEpisodesCubit>()
        .getEpisodes(slug, isAuthorCheck: _isAuthor);
  }

  Future<void> _toggleBookmark(EpisodeModel episode) async {
    if (context.read<AuthCubit>().getUserId() == "0") {
      UiUtils.loginRequired(context);
      return;
    }
    final nowBookmarked = !episode.isBookmarked;
    setState(() => episode.isBookmarked = nowBookmarked);
    final error = await context.read<PodcastBookmarkCubit>().setBookmark(
          episodeId: episode.id ?? '',
          podcastId: episode.podcastId ?? channel.id ?? '',
          bookmark: nowBookmarked,
        );
    if (!mounted) return;
    if (error != null) setState(() => episode.isBookmarked = !nowBookmarked);
    showSnackBar(
        error ??
            (nowBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks'),
        context);
  }

  Future<void> _download(EpisodeModel episode) => startEpisodeDownload(
        context,
        episode.toPlayableAudio(
            fallbackImage: channel.imageUrl, artist: channel.authorName),
      );

  void _openPlayer(List<EpisodeModel> episodes, int index) {
    final episode = episodes[index];
    if (episode.audioUrl?.isEmpty ?? true) {
      showSnackBar('This episode has no audio to play', context);
      return;
    }
    Navigator.of(context).pushNamed(Routes.podcastPlayer, arguments: {
      "episode": PodcastPlayerData(
        id: episode.id,
        isAuthor: _isAuthor,
        podcastId: episode.podcastId ?? channel.id,
        imageUrl: (episode.image?.isNotEmpty ?? false)
            ? episode.image!
            : channel.imageUrl,
        audioUrl: episode.audioUrl,
        sourceType: episode.sourceType,
        isBookmarked: episode.isBookmarked,
        episodeLabel: 'Episode - ${episode.episodeNo}',
        title: episode.title ?? channel.title,
        description: episode.description ?? channel.description,
        listenersCount: channel.listenersCount,
        followerCount: _followerCount,
        episodeNo: episode.episodeNo,
        durationSeconds: episode.durationSeconds,
        publishedAt: episode.publishedAt,
        authorName: channel.authorName,
        authorImageUrl: channel.authorImageUrl,
        isFollowed: _isFollowed,
      ),
      "episodes": [
        for (final e in episodes)
          e.toTileData(
              fallbackImage: channel.imageUrl,
              artist: channel.authorName,
              episodeLabel: 'Episode - ${e.episodeNo}'),
      ],
    }).then((_) {
      if (mounted) _syncFollowFromList();
    });
  }

  Widget _shareButton(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final slug = channel.slug;
    if (slug == null || slug.isEmpty) return const SizedBox.shrink();
    return Center(
      child: GestureDetector(
        onTap: () => UiUtils.shareNews(
          context: context,
          title: channel.title,
          slug: slug,
          isBreakingNews: false,
          isNews: false,
          isVideo: false,
          videoId: "",
          isReels: false,
          isPodcast: true,
        ),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: colorScheme.primaryContainer.withOpacity(0.4)),
          ),
          child: SvgPictureWidget(
              assetName: 'share',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              assetColor: ColorFilter.mode(
                  colorScheme.primaryContainer, BlendMode.srcIn)),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(channel.tag,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 16 / 11,
            letterSpacing: 0.5,
            color: colorScheme.primaryContainer,
          )),
    );
  }

  /// The author's name and avatar on the left, Follow on the right.
  ///
  /// An admin-created channel carries no `user` block, so it has no author to
  /// name — only that half goes. Following is the listener's action either way,
  /// so the button keeps its place at the end of the row.
  Widget _authorRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (channel.authorName.isNotEmpty)
          Flexible(child: _authorIdentity(context))
        else
          const Spacer(),
        const SizedBox(width: 8),
        _followButton(context),
      ],
    );
  }

  Widget _authorIdentity(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: CustomNetworkImage(
              networkImageUrl: channel.authorImageUrl,
              width: 30,
              height: 30,
              fit: BoxFit.cover),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(channel.authorName,
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
    );
  }

  Future<void> _toggleFollow() async {
    final id = channel.id;
    if (id == null || id.isEmpty) return;
    if (context.read<AuthCubit>().getUserId() == "0") {
      UiUtils.loginRequired(context);
      return;
    }
    final nowFollowed = !_isFollowed;
    final previousCount = _followerCount;
    final previousLabel = _channel.listenersCount;
    int? nextCount;
    if (previousCount != null) {
      final raw = previousCount + (nowFollowed ? 1 : -1);
      nextCount = raw < 0 ? 0 : raw;
    }
    setState(() {
      _followerCount = nextCount;
      _channel = _channel.copyWith(
        isFollowed: nowFollowed,
        listenersCount:
            nextCount == null ? null : PodcastModel.compactCount(nextCount),
      );
    });
    final error =
        await _repository.setFollowPodcast(podcastId: id, follow: nowFollowed);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _followerCount = previousCount;
        _channel = _channel.copyWith(
            isFollowed: !nowFollowed, listenersCount: previousLabel);
      });
      showSnackBar(error, context);
      return;
    }
    context
        .read<PodcastCubit>()
        .setFollowState(podcastId: id, isFollowed: nowFollowed);
  }

  Widget _followButton(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              _isFollowed ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.primaryContainer),
        ),
        child: Text(_isFollowed ? 'Following' : 'Follow',
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
