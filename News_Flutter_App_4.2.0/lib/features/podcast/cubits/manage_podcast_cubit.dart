// Write actions for the author's channels: save (create + update) and delete.
// Reading the list is MyPodcastsCubit's job.

import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

abstract class ManagePodcastState {}

class ManagePodcastInitial extends ManagePodcastState {}

class ManagePodcastInProgress extends ManagePodcastState {}

class ManagePodcastSuccess extends ManagePodcastState {
  final String message;

  ManagePodcastSuccess({required this.message});
}

class ManagePodcastFailure extends ManagePodcastState {
  final String errorMessage;

  ManagePodcastFailure(this.errorMessage);
}

class ManagePodcastCubit extends Cubit<ManagePodcastState> {
  final PodcastRepository _repository;

  ManagePodcastCubit(this._repository) : super(ManagePodcastInitial());

  Future<void> savePodcast({
    String? podcastId,
    required String title,
    required String slug,
    required String description,
    required DateTime publishDate,
    required bool isDraft,
    String metaTitle = '',
    String metaDescription = '',
    String metaKeyword = '',
    String schemaMarkup = '',
    File? image,
  }) async {
    try {
      emit(ManagePodcastInProgress());
      final message = await _repository.savePodcast(
        podcastId: podcastId,
        title: title,
        slug: slug,
        description: description,
        publishDate: publishDate,
        isDraft: isDraft,
        metaTitle: metaTitle,
        metaDescription: metaDescription,
        metaKeyword: metaKeyword,
        schemaMarkup: schemaMarkup,
        image: image,
      );
      emit(ManagePodcastSuccess(message: message));
    } catch (e) {
      emit(ManagePodcastFailure(e.toString()));
    }
  }

  Future<void> deletePodcast({required String podcastId}) async {
    try {
      emit(ManagePodcastInProgress());
      final message = await _repository.deletePodcast(podcastId: podcastId);
      emit(ManagePodcastSuccess(message: message));
    } catch (e) {
      emit(ManagePodcastFailure(e.toString()));
    }
  }
}
