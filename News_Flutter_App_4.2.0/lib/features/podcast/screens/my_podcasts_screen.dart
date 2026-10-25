// The author's own channels (Routes.myPodcasts): All / Draft tabs, each card
// carrying an Edit / Delete / Episode menu.

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
import 'package:news/features/podcast/cubits/manage_podcast_cubit.dart';
import 'package:news/features/podcast/cubits/my_podcasts_cubit.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/screens/channel_detail_screen.dart';
import 'package:news/features/podcast/screens/widgets/podcast_card.dart';
import 'package:news/features/podcast/screens/widgets/podcast_owner_menu.dart';
import 'package:news/utils/ui_utils.dart';

class MyPodcastsScreen extends StatefulWidget {
  const MyPodcastsScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const MyPodcastsScreen());
  }

  @override
  State<MyPodcastsScreen> createState() => _MyPodcastsScreenState();
}

class _MyPodcastsScreenState extends State<MyPodcastsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  bool _deleteRequested = false;

  /// Set when an episode write succeeds anywhere below this screen. Episode
  /// counts live on the cards here, so the list is re-fetched on the way back
  /// from either screen that manages episodes — but only when something
  /// actually changed.
  bool _episodesChanged = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      context.read<MyPodcastsCubit>().getMyPodcasts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openChannel(PodcastCardData podcast) async {
    await Navigator.of(context)
        .pushNamed(Routes.podcastChannelDetail, arguments: {
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
        isAuthor: true,
      ),
    });
    // The author can edit and delete episodes from that screen too, and the
    // counts on these cards come from the podcast list.
    if (!mounted || !_episodesChanged) return;
    _episodesChanged = false;
    context.read<MyPodcastsCubit>().getMyPodcasts();
  }

  Future<void> _openForm({PodcastModel? podcast}) async {
    final saved = await Navigator.of(context)
        .pushNamed(Routes.createPodcast, arguments: {"podcast": podcast});
    if (saved == true && mounted) {
      context.read<MyPodcastsCubit>().getMyPodcasts();
    }
  }

  void _createPodcast() => _openForm();

  void _editPodcast(PodcastModel podcast) => _openForm(podcast: podcast);

  Future<void> _deletePodcast(PodcastModel podcast) async {
    if (podcast.id == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: UiUtils.getColorScheme(dialogContext).surface,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        title: const CustomTextLabel(text: 'deletePodcastLbl'),
        titleTextStyle: Theme.of(dialogContext)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w600),
        content: CustomTextLabel(
            text: 'doYouReallyPodcastLbl',
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
    context.read<ManagePodcastCubit>().deletePodcast(podcastId: podcast.id!);
  }

  TextStyle? _dialogActionStyle(BuildContext dialogContext) =>
      Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
          color: UiUtils.getColorScheme(dialogContext).primaryContainer,
          fontWeight: FontWeight.bold);

  Future<void> _openEpisodes(PodcastModel podcast) async {
    await Navigator.of(context)
        .pushNamed(Routes.myEpisodes, arguments: {"podcast": podcast});
    if (!mounted || !_episodesChanged) return;
    _episodesChanged = false;
    context.read<MyPodcastsCubit>().getMyPodcasts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Column(
        children: [
          BlocListener<ManagePodcastCubit, ManagePodcastState>(
            listener: (context, state) {
              if (!_deleteRequested) return;
              if (state is ManagePodcastSuccess) {
                _deleteRequested = false;
                showSnackBar(state.message, context);
                context.read<MyPodcastsCubit>().getMyPodcasts();
              }
              if (state is ManagePodcastFailure) {
                _deleteRequested = false;
                showSnackBar(state.errorMessage, context);
              }
            },
            child: BlocListener<ManageEpisodeCubit, ManageEpisodeState>(
              listener: (context, state) {
                if (state is ManageEpisodeSuccess) _episodesChanged = true;
              },
              child: const SizedBox.shrink(),
            ),
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
              child: _createPodcastBtn(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
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
            title: CustomTextLabel(
                text: 'managePodcastLbl',
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: UiUtils.getColorScheme(context).primaryContainer,
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15)),
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
            Expanded(child: _tab('allPodcastLbl', 0, selected)),
            const SizedBox(width: 10),
            Expanded(child: _tab('draftPodcastLbl', 1, selected)),
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
    return BlocBuilder<MyPodcastsCubit, MyPodcastsState>(
      builder: (context, state) {
        if (state is MyPodcastsFetchInProgress || state is MyPodcastsInitial) {
          return UiUtils.showCircularProgress(
              true, Theme.of(context).primaryColor);
        }
        if (state is MyPodcastsFetchFailure) {
          return ErrorContainerWidget(
              errorMsg:
                  (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                      ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                      : state.errorMessage,
              onRetry: () => context.read<MyPodcastsCubit>().getMyPodcasts());
        }

        final success = state as MyPodcastsFetchSuccess;
        return TabBarView(
          controller: _tabController,
          children: [
            _podcastList(success.published, 'noPodcastLbl'),
            _podcastList(success.drafts, 'noDraftPodcastLbl'),
          ],
        );
      },
    );
  }

  Widget _podcastList(List<PodcastModel> podcasts, String emptyLabelKey) {
    if (podcasts.isEmpty) {
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
      itemCount: podcasts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final podcast = podcasts[index];
        return PodcastCard(
          data: podcast.toCardData(),
          imageSize: 93,
          onTap: () => _openChannel(podcast.toCardData()),
          trailing: PodcastOwnerMenu(
            onEdit: () => _editPodcast(podcast),
            onDelete: () => _deletePodcast(podcast),
            onEpisodes: () => _openEpisodes(podcast),
          ),
        );
      },
    );
  }

  Widget _createPodcastBtn() {
    return InkWell(
        onTap: _createPodcast,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 40.0,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(4.0)),
          child: CustomTextLabel(
              text: 'createPodcastLbl',
              textStyle: const TextStyle(
                  color: secondaryColor,
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.15)),
        ));
  }
}
