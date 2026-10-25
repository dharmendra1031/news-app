// One channel's episodes as the AUTHOR sees them, behind MyEpisodesScreen:
// drafts included, no paging. The listener's view is PodcastEpisodesCubit.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class MyEpisodesState {}

class MyEpisodesInitial extends MyEpisodesState {}

class MyEpisodesFetchInProgress extends MyEpisodesState {}

class MyEpisodesFetchSuccess extends MyEpisodesState {
  final List<EpisodeModel> published;

  final List<EpisodeModel> drafts;

  MyEpisodesFetchSuccess({required this.published, required this.drafts});
}

class MyEpisodesFetchFailure extends MyEpisodesState {
  final String errorMessage;

  MyEpisodesFetchFailure(this.errorMessage);
}

class MyEpisodesCubit extends Cubit<MyEpisodesState> {
  final PodcastRepository _repository;

  MyEpisodesCubit(this._repository) : super(MyEpisodesInitial());

  Future<void> getMyEpisodes(PodcastModel podcast) async {
    try {
      emit(MyEpisodesFetchInProgress());
      final lists = await _repository.getMyEpisodesByType(podcast: podcast);
      emit(MyEpisodesFetchSuccess(
          published: lists.published, drafts: lists.drafts));
    } catch (e) {
      emit(MyEpisodesFetchFailure(e.toString()));
    }
  }
}
