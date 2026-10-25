// The user's listening history: the History tab and the resume bars on episode
// rows. Server-only; the player writes positions through PodcastRepository.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class PodcastHistoryState {}

class PodcastHistoryInitial extends PodcastHistoryState {}

class PodcastHistoryInProgress extends PodcastHistoryState {}

class PodcastHistorySuccess extends PodcastHistoryState {
  final List<ListenedEpisode> episodes;

  late final Map<String, double> progressById = {
    for (final item in episodes)
      if ((item.episode.id ?? '').isNotEmpty) item.episode.id!: item.progress
  };

  PodcastHistorySuccess({required this.episodes});
}

class PodcastHistoryFailure extends PodcastHistoryState {
  final String errorMessage;

  PodcastHistoryFailure(this.errorMessage);
}

class PodcastHistoryCubit extends Cubit<PodcastHistoryState> {
  final PodcastRepository _repository;

  PodcastHistoryCubit(this._repository) : super(PodcastHistoryInitial());

  Future<void> getHistory({bool showProgress = true}) async {
    try {
      if (showProgress) emit(PodcastHistoryInProgress());
      final episodes = await _repository.getListeningHistory();
      emit(PodcastHistorySuccess(episodes: episodes));
    } catch (e) {
      emit(PodcastHistoryFailure(e.toString()));
    }
  }

  double? progressOf(String episodeId) {
    final current = state;
    return current is PodcastHistorySuccess
        ? current.progressById[episodeId]
        : null;
  }
}
