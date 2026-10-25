// Channel search via `get_podcast`'s server-side `search` parameter. Owned by the
// dashboard screen so searching can never filter the shared home list.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class PodcastSearchState {}

class PodcastSearchInitial extends PodcastSearchState {}

class PodcastSearchInProgress extends PodcastSearchState {}

class PodcastSearchSuccess extends PodcastSearchState {
  final String query;
  final List<PodcastModel> podcasts;

  PodcastSearchSuccess({required this.query, required this.podcasts});
}

class PodcastSearchFailure extends PodcastSearchState {
  final String query;
  final String errorMessage;

  PodcastSearchFailure({required this.query, required this.errorMessage});
}

class PodcastSearchCubit extends Cubit<PodcastSearchState> {
  final PodcastRepository _repository;

  int _requestId = 0;

  PodcastSearchCubit(this._repository) : super(PodcastSearchInitial());

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final int id = ++_requestId;

    if (trimmed.isEmpty) {
      emit(PodcastSearchInitial());
      return;
    }

    emit(PodcastSearchInProgress());
    try {
      final podcasts = await _repository.getPodcasts(search: trimmed);
      if (id != _requestId) return;
      emit(PodcastSearchSuccess(query: trimmed, podcasts: podcasts));
    } catch (e) {
      if (id != _requestId) return;
      emit(PodcastSearchFailure(query: trimmed, errorMessage: e.toString()));
    }
  }

  void clear() {
    _requestId++;
    emit(PodcastSearchInitial());
  }
}
