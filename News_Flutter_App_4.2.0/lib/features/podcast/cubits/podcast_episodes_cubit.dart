// One channel + its episodes by slug (ChannelDetailScreen) — the LISTENER's view:
// published only, paged. A single `get_episode` returns both parts together.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class PodcastEpisodesState {}

class PodcastEpisodesInitial extends PodcastEpisodesState {}

class PodcastEpisodesInProgress extends PodcastEpisodesState {}

class PodcastEpisodesSuccess extends PodcastEpisodesState {
  final List<EpisodeModel> episodes;

  final PodcastModel? podcast;

  final int totalEpisodeCount;
  final bool hasMore;
  final bool hasMoreFetchError;

  PodcastEpisodesSuccess({
    required this.episodes,
    this.podcast,
    this.totalEpisodeCount = 0,
    this.hasMore = false,
    this.hasMoreFetchError = false,
  });
}

class PodcastEpisodesFailure extends PodcastEpisodesState {
  final String errorMessage;
  PodcastEpisodesFailure(this.errorMessage);
}

class PodcastEpisodesCubit extends Cubit<PodcastEpisodesState> {
  final PodcastRepository _repository;

  PodcastEpisodesCubit(this._repository) : super(PodcastEpisodesInitial());

  Future<void> getEpisodes(String podcastSlug, {bool isAuthorCheck = false}) async {
    try {
      emit(PodcastEpisodesInProgress());
      final result = await _repository.getEpisodes(
          podcastSlug: podcastSlug,
          offset: "0",
          limit: limitOfPodcastEpisodes.toString(),
          isAuthorCheck: isAuthorCheck);
      final total = result.podcast?.episodeCount ?? result.episodes.length;
      emit(PodcastEpisodesSuccess(
        episodes: result.episodes,
        podcast: result.podcast,
        totalEpisodeCount: total,
        hasMore: result.episodes.isNotEmpty && result.episodes.length < total,
      ));
    } catch (e) {
      emit(PodcastEpisodesFailure(e.toString()));
    }
  }

  bool hasMoreEpisodes() => (state is PodcastEpisodesSuccess)
      ? (state as PodcastEpisodesSuccess).hasMore
      : false;

  Future<void> getMoreEpisodes(String podcastSlug, {bool isAuthorCheck = false}) async {
    final current = state;
    if (current is! PodcastEpisodesSuccess) return;
    try {
      final result = await _repository.getEpisodes(
          podcastSlug: podcastSlug,
          offset: current.episodes.length.toString(),
          limit: limitOfPodcastEpisodes.toString(),
          isAuthorCheck: isAuthorCheck);
      final episodes = [...current.episodes, ...result.episodes];
      final total = result.podcast?.episodeCount ?? current.totalEpisodeCount;
      emit(PodcastEpisodesSuccess(
        episodes: episodes,
        podcast: result.podcast ?? current.podcast,
        totalEpisodeCount: total,
        hasMore: result.episodes.isNotEmpty && episodes.length < total,
      ));
    } catch (_) {
      emit(PodcastEpisodesSuccess(
        episodes: current.episodes,
        podcast: current.podcast,
        totalEpisodeCount: current.totalEpisodeCount,
        hasMore: current.hasMore,
        hasMoreFetchError: true,
      ));
    }
  }
}
