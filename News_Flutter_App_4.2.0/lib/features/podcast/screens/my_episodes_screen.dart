// One channel's episodes as the author manages them (Routes.myEpisodes): All /
// Draft tabs. Tapping a row plays it in the full player; Edit and Delete live in
// the row's menu.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/podcast/cubits/manage_episode_cubit.dart';
import 'package:news/features/podcast/cubits/my_episodes_cubit.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/screens/podcast_player_screen.dart';
import 'package:news/features/podcast/screens/widgets/episode_list_tile.dart';
import 'package:news/features/podcast/screens/widgets/podcast_owner_menu.dart';
import 'package:news/utils/ui_utils.dart';

class MyEpisodesScreen extends StatefulWidget {
  final PodcastModel podcast;

  const MyEpisodesScreen({super.key, required this.podcast});

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) =>
            MyEpisodesScreen(podcast: arguments['podcast'] as PodcastModel));
  }

  @override
  State<MyEpisodesScreen> createState() => _MyEpisodesScreenState();
}

class _MyEpisodesScreenState extends State<MyEpisodesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  bool _deleteRequested = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      context.read<MyEpisodesCubit>().getMyEpisodes(widget.podcast);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openForm({EpisodeModel? episode}) async {
    final saved = await Navigator.of(context).pushNamed(Routes.createEpisode,
        arguments: {"podcast": widget.podcast, "episode": episode});
    if (saved == true && mounted) {
      context.read<MyEpisodesCubit>().getMyEpisodes(widget.podcast);
    }
  }

  void _createEpisode() => _openForm();

  void _editEpisode(EpisodeModel episode) => _openForm(episode: episode);

  EpisodeListTileData _tileData(EpisodeModel episode) => episode.toTileData(
      fallbackImage: widget.podcast.image,
      artist: widget.podcast.authorName,
      episodeLabel: 'Episode - ${episode.episodeNo}');

  /// Plays [episode] in the full player, with the rest of the same tab behind it
  /// as the queue. A draft can still be sitting there without its audio, and the
  /// player has nothing to play then.
  void _openPlayer(List<EpisodeModel> episodes, int index) {
    final episode = episodes[index];
    if (episode.audioUrl?.isEmpty ?? true) {
      showSnackBar('This episode has no audio to play', context);
      return;
    }
    final PodcastModel podcast = widget.podcast;
    Navigator.of(context).pushNamed(Routes.podcastPlayer, arguments: {
      "episode": PodcastPlayerData(
        id: episode.id,
        // These are the author's own episodes, so the player drops bookmarking
        // and the follow row the same way the channel screen does.
        isAuthor: true,
        podcastId: episode.podcastId ?? podcast.id,
        imageUrl: (episode.image?.isNotEmpty ?? false)
            ? episode.image!
            : (podcast.image ?? ''),
        audioUrl: episode.audioUrl,
        sourceType: episode.sourceType,
        isBookmarked: episode.isBookmarked,
        episodeLabel: 'Episode - ${episode.episodeNo}',
        title: episode.title ?? podcast.title ?? '',
        description: episode.description ?? podcast.description ?? '',
        listenersCount: PodcastModel.compactCount(podcast.followerCount),
        followerCount: podcast.followerCount,
        episodeNo: episode.episodeNo,
        durationSeconds: episode.durationSeconds,
        publishedAt: episode.publishedAt,
        authorName: podcast.authorName ?? '',
        authorImageUrl: podcast.authorImage ?? '',
      ),
      // Only what can actually be played belongs in the queue — an entry with no
      // url would stall the auto-advance on it.
      "episodes": [
        for (final e in episodes)
          if (e.audioUrl?.isNotEmpty ?? false) _tileData(e),
      ],
    });
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

  TextStyle? _dialogActionStyle(BuildContext dialogContext) =>
      Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
          color: UiUtils.getColorScheme(dialogContext).primaryContainer,
          fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Column(
        children: [
          BlocListener<ManageEpisodeCubit, ManageEpisodeState>(
            listener: (context, state) {
              if (!_deleteRequested) return;
              if (state is ManageEpisodeSuccess) {
                _deleteRequested = false;
                showSnackBar(state.message, context);
                context.read<MyEpisodesCubit>().getMyEpisodes(widget.podcast);
              }
              if (state is ManageEpisodeFailure) {
                _deleteRequested = false;
                showSnackBar(state.errorMessage, context);
              }
            },
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          _tabBar(),
          Expanded(child: _body()),
          SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 16.0, end: 16.0, top: 8, bottom: 8),
              child: _createEpisodeBtn(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    final String title = widget.podcast.title ?? '';
    return PreferredSize(
        preferredSize: const Size(double.infinity, 54),
        child: UiUtils.applyBoxShadow(
          context: context,
          child: AppBar(
            toolbarHeight: 54,
            centerTitle: false,
            backgroundColor: Colors.transparent,
            leadingWidth: 40,
            titleSpacing: 12,
            title: title.isEmpty
                ? CustomTextLabel(text: 'episodeLbl', textStyle: _titleStyle())
                : Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle()),
            leading: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16.0),
              child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Icon(Icons.arrow_back,
                      size: 24,
                      color: UiUtils.getColorScheme(context).primaryContainer)),
            ),
          ),
        ));
  }

  TextStyle? _titleStyle() => Theme.of(context).textTheme.titleMedium?.copyWith(
      color: UiUtils.getColorScheme(context).primaryContainer,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15);

  Widget _tabBar() {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 16, end: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: UiUtils.getColorScheme(context).surface),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, _) {
          final int selected = _tabController.animation!.value.round();
          return Row(children: [
            Expanded(child: _tab('allEpisodeLbl', 0, selected)),
            const SizedBox(width: 10),
            Expanded(child: _tab('draftEpisodeLbl', 1, selected)),
          ]);
        },
      ),
    );
  }

  Widget _tab(String labelKey, int index, int selectedIndex) {
    final bool isSelected = index == selectedIndex;
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isSelected
                ? UiUtils.getColorScheme(context).primaryContainer
                : Colors.transparent),
        child: CustomTextLabel(
            text: labelKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            textStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? UiUtils.getColorScheme(context).surface
                    : UiUtils.getColorScheme(context).primaryContainer)),
      ),
    );
  }

  Widget _body() {
    return BlocBuilder<MyEpisodesCubit, MyEpisodesState>(
      builder: (context, state) {
        if (state is MyEpisodesFetchInProgress || state is MyEpisodesInitial) {
          return UiUtils.showCircularProgress(
              true, Theme.of(context).primaryColor);
        }
        if (state is MyEpisodesFetchFailure) {
          return ErrorContainerWidget(
              errorMsg:
                  (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                      ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                      : state.errorMessage,
              onRetry: () => context
                  .read<MyEpisodesCubit>()
                  .getMyEpisodes(widget.podcast));
        }

        final success = state as MyEpisodesFetchSuccess;
        return TabBarView(
          controller: _tabController,
          children: [
            _episodeList(success.published, 'noEpisodeLbl'),
            _episodeList(success.drafts, 'noDraftEpisodeLbl'),
          ],
        );
      },
    );
  }

  Widget _episodeList(List<EpisodeModel> episodes, String emptyLabelKey) {
    if (episodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomTextLabel(
              text: emptyLabelKey,
              textAlign: TextAlign.center,
              textStyle: TextStyle(
                  color: UiUtils.getColorScheme(context)
                      .primaryContainer
                      .withOpacity(0.5))),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: episodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final episode = episodes[index];
        return EpisodeListTile(
          data: _tileData(episode),
          onTap: () => _openPlayer(episodes, index),
          trailing: PodcastOwnerMenu(
            onEdit: () => _editEpisode(episode),
            onDelete: () => _deleteEpisode(episode),
          ),
        );
      },
    );
  }

  Widget _createEpisodeBtn() {
    return InkWell(
        onTap: _createEpisode,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 40.0,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(4.0)),
          child: CustomTextLabel(
              text: 'createEpisodeLbl',
              textStyle: const TextStyle(
                  color: secondaryColor,
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15)),
        ));
  }
}
