import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class VideoShortShareState {}

class VideoShortShareInitial extends VideoShortShareState {}

class VideoShortShareInProgress extends VideoShortShareState {}

class VideoShortShareSuccess extends VideoShortShareState {
  final String videoShortsId;

  VideoShortShareSuccess(this.videoShortsId);
}

class VideoShortShareFailure extends VideoShortShareState {
  final String errorMessage;

  VideoShortShareFailure(this.errorMessage);
}

class VideoShortShareCubit extends Cubit<VideoShortShareState> {
  VideoShortShareCubit() : super(VideoShortShareInitial());

  Future<void> setVideoShortShare({required String videoShortsId}) async {
    try {
      emit(VideoShortShareInProgress());

      final result = await Api.sendApiRequest(
        body: {VIDEO_SHORTS_ID: videoShortsId},
        url: Api.setVideoShortSharesApi,
      );

      if (result[ERROR] == true) {
        emit(VideoShortShareFailure(result[MESSAGE]?.toString() ?? ''));
        return;
      }

      emit(VideoShortShareSuccess(videoShortsId));
    } on ApiException catch (e) {
      emit(VideoShortShareFailure(e.errorMessage));
    } catch (e) {
      emit(VideoShortShareFailure(e.toString()));
    }
  }
}
