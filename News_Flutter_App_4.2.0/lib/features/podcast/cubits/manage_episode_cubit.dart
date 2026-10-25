// Write actions for the author's episodes: save (create + update) and delete.
// Reading the list is MyEpisodesCubit's job.

import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class ManageEpisodeState {}

class ManageEpisodeInitial extends ManageEpisodeState {}

class ManageEpisodeInProgress extends ManageEpisodeState {}

class ManageEpisodeSuccess extends ManageEpisodeState {
  final String message;

  ManageEpisodeSuccess({required this.message});
}

class ManageEpisodeFailure extends ManageEpisodeState {
  final String errorMessage;

  ManageEpisodeFailure(this.errorMessage);
}

class ManageEpisodeCubit extends Cubit<ManageEpisodeState> {
  final PodcastRepository _repository;

  ManageEpisodeCubit(this._repository) : super(ManageEpisodeInitial());

  Future<void> saveEpisode({
    String? episodeId,
    required String podcastId,
    required String episodeNo,
    required String title,
    required String slug,
    required String description,
    required DateTime publishDate,
    required String sourceType,
    required bool isDraft,
    String? audioUrl,
    File? audioFile,
    File? image,
  }) async {
    try {
      emit(ManageEpisodeInProgress());
      final bool isUpload = sourceType == 'upload';
      final message = await _repository.saveEpisode(
        episodeId: episodeId,
        podcastId: podcastId,
        episodeNo: episodeNo,
        title: title,
        slug: slug,
        description: description,
        publishDate: publishDate,
        sourceType: sourceType,
        isDraft: isDraft,
        audioUrl: isUpload ? null : audioUrl,
        audioFile: isUpload ? audioFile : null,
        image: image,
      );
      emit(ManageEpisodeSuccess(message: message));
    } catch (e) {
      emit(ManageEpisodeFailure(e.toString()));
    }
  }

  Future<void> deleteEpisode({required String episodeId}) async {
    try {
      emit(ManageEpisodeInProgress());
      final message = await _repository.deleteEpisode(episodeId: episodeId);
      emit(ManageEpisodeSuccess(message: message));
    } catch (e) {
      emit(ManageEpisodeFailure(e.toString()));
    }
  }
}
