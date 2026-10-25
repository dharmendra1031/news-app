// The user's bookmarked episodes, and the owner of every bookmark change in the
// module. Server-only: no local copy, so an offline toggle simply fails.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class PodcastBookmarkState {}

class PodcastBookmarkInitial extends PodcastBookmarkState {}

class PodcastBookmarkInProgress extends PodcastBookmarkState {}

class PodcastBookmarkSuccess extends PodcastBookmarkState {
  final List<BookmarkedEpisode> episodes;

  late final Set<String> episodeIds =
      episodes.map((e) => e.episode.id ?? '').toSet();

  PodcastBookmarkSuccess({required this.episodes});
}

class PodcastBookmarkFailure extends PodcastBookmarkState {
  final String errorMessage;

  PodcastBookmarkFailure(this.errorMessage);
}

class PodcastBookmarkCubit extends Cubit<PodcastBookmarkState> {
  final PodcastRepository _repository;

  PodcastBookmarkCubit(this._repository) : super(PodcastBookmarkInitial());

  Future<void> getBookmarks({bool showProgress = true}) async {
    try {
      if (showProgress) emit(PodcastBookmarkInProgress());
      final episodes = await _repository.getBookmarkedEpisodes();
      emit(PodcastBookmarkSuccess(episodes: episodes));
    } catch (e) {
      emit(PodcastBookmarkFailure(e.toString()));
    }
  }

  bool isBookmarked(String episodeId) {
    final current = state;
    return current is PodcastBookmarkSuccess &&
        current.episodeIds.contains(episodeId);
  }

  // Null when the change went through, otherwise the API's error message.
  Future<String?> setBookmark({
    required String episodeId,
    required String podcastId,
    required bool bookmark,
  }) async {
    final current = state;
    final wasLoaded = current is PodcastBookmarkSuccess;

    if (!bookmark && wasLoaded) {
      emit(PodcastBookmarkSuccess(
        episodes:
            current.episodes.where((e) => e.episode.id != episodeId).toList(),
      ));
    }

    final error = await _repository.setEpisodeBookmark(
      podcastId: podcastId,
      episodeId: episodeId,
      bookmark: bookmark,
    );

    if (error != null) {
      if (!bookmark && wasLoaded) {
        emit(PodcastBookmarkSuccess(episodes: current.episodes));
      }
      return error;
    }

    if (bookmark) await getBookmarks(showProgress: false);
    return null;
  }
}
