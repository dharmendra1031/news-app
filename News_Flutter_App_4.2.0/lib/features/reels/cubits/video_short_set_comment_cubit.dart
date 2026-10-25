import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class VideoShortSetCommentState {}

class VideoShortSetCommentInitial extends VideoShortSetCommentState {}

class VideoShortSetCommentInProgress extends VideoShortSetCommentState {}

class VideoShortSetCommentSuccess extends VideoShortSetCommentState {
  final String videoShortsId;
  final String comment;
  final String? message;

  VideoShortSetCommentSuccess({
    required this.videoShortsId,
    required this.comment,
    this.message,
  });
}

class VideoShortSetCommentFailure extends VideoShortSetCommentState {
  final String errorMessage;

  VideoShortSetCommentFailure(this.errorMessage);
}

class VideoShortSetCommentCubit extends Cubit<VideoShortSetCommentState> {
  VideoShortSetCommentCubit() : super(VideoShortSetCommentInitial());

  Future<void> setVideoShortComment({
    required String videoShortsId,
    required String comment,
  }) async {
    try {
      emit(VideoShortSetCommentInProgress());

      final result = await Api.sendApiRequest(
        body: {
          VIDEO_SHORTS_ID: videoShortsId,
          COMMENT: comment,
        },
        url: Api.setVideoShortCommentApi,
      );

      if (result[ERROR] == true) {
        emit(VideoShortSetCommentFailure(
          result[MESSAGE]?.toString() ?? '',
        ));
        return;
      }

      emit(VideoShortSetCommentSuccess(
        videoShortsId: videoShortsId,
        comment: comment,
        message: result[MESSAGE]?.toString(),
      ));
    } on ApiException catch (e) {
      emit(VideoShortSetCommentFailure(e.errorMessage));
    } catch (e) {
      emit(VideoShortSetCommentFailure(e.toString()));
    }
  }

  void reset() => emit(VideoShortSetCommentInitial());
}
