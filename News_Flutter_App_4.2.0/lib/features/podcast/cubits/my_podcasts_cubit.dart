// The author's own channels (`my_podcasts`), behind MyPodcastsScreen — unlike
// the public list this also holds drafts and deactivated channels.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class MyPodcastsState {}

class MyPodcastsInitial extends MyPodcastsState {}

class MyPodcastsFetchInProgress extends MyPodcastsState {}

class MyPodcastsFetchSuccess extends MyPodcastsState {
  final List<PodcastModel> published;

  final List<PodcastModel> drafts;

  MyPodcastsFetchSuccess({required this.published, required this.drafts});
}

class MyPodcastsFetchFailure extends MyPodcastsState {
  final String errorMessage;

  MyPodcastsFetchFailure(this.errorMessage);
}

class MyPodcastsCubit extends Cubit<MyPodcastsState> {
  final PodcastRepository _repository;

  MyPodcastsCubit(this._repository) : super(MyPodcastsInitial());

  Future<void> getMyPodcasts({String? search}) async {
    try {
      emit(MyPodcastsFetchInProgress());
      final lists = await _repository.getMyPodcastsByType(search: search);
      emit(MyPodcastsFetchSuccess(
          published: lists.published, drafts: lists.drafts));
    } catch (e) {
      emit(MyPodcastsFetchFailure(e.toString()));
    }
  }
}
