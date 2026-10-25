// The public channel list (`get_podcast`), fetched once and shared by the home
// section and the dashboard's All tab; doubles as the module's channel cache.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class PodcastState {}

class PodcastInitial extends PodcastState {}

class PodcastFetchInProgress extends PodcastState {}

class PodcastFetchSuccess extends PodcastState {
  final List<PodcastModel> podcasts;

  PodcastFetchSuccess({required this.podcasts});
}

class PodcastFetchFailure extends PodcastState {
  final String errorMessage;
  PodcastFetchFailure(this.errorMessage);
}

class PodcastCubit extends Cubit<PodcastState> {
  final PodcastRepository _repository;

  PodcastCubit(this._repository) : super(PodcastInitial());

  Future<void> getPodcasts({String? search}) async {
    try {
      emit(PodcastFetchInProgress());
      final podcasts = await _repository.getPodcasts(search: search);
      emit(PodcastFetchSuccess(podcasts: podcasts));
    } catch (e) {
      emit(PodcastFetchFailure(e.toString()));
    }
  }

  PodcastModel? podcastById(String? podcastId) {
    final current = state;
    if (current is! PodcastFetchSuccess || (podcastId ?? '').isEmpty) {
      return null;
    }
    for (final podcast in current.podcasts) {
      if (podcast.id == podcastId) return podcast;
    }
    return null;
  }

  void setFollowState({required String podcastId, required bool isFollowed}) {
    final current = state;
    if (current is! PodcastFetchSuccess) return;
    final updated = current.podcasts.map((podcast) {
      if (podcast.id != podcastId || podcast.isFollowed == isFollowed) {
        return podcast;
      }
      final count = podcast.followerCount + (isFollowed ? 1 : -1);
      return podcast.copyWith(
          isFollowed: isFollowed, followerCount: count < 0 ? 0 : count);
    }).toList();
    emit(PodcastFetchSuccess(podcasts: updated));
  }
}
