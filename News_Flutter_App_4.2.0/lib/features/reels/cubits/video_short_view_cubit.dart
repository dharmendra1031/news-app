import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class VideoShortViewState {}

class VideoShortViewInitial extends VideoShortViewState {}

class VideoShortViewInProgress extends VideoShortViewState {}

class VideoShortViewSuccess extends VideoShortViewState {
  final String videoShortsId;

  VideoShortViewSuccess(this.videoShortsId);
}

class VideoShortViewFailure extends VideoShortViewState {
  final String errorMessage;

  VideoShortViewFailure(this.errorMessage);
}

class VideoShortViewCubit extends Cubit<VideoShortViewState> {
  VideoShortViewCubit() : super(VideoShortViewInitial());

  final Set<String> _viewedShortIds = {};

  Future<void> setVideoShortView({required String videoShortsId}) async {
    if (videoShortsId.isEmpty || _viewedShortIds.contains(videoShortsId)) {
      return;
    }
    _viewedShortIds.add(videoShortsId);

    try {
      emit(VideoShortViewInProgress());

      final result = await Api.sendApiRequest(
        body: {VIDEO_SHORTS_ID: videoShortsId},
        url: Api.setVideoShortViewApi,
      );

      if (result[ERROR] == true) {
        _viewedShortIds.remove(videoShortsId);
        emit(VideoShortViewFailure(result[MESSAGE]?.toString() ?? ''));
        return;
      }

      emit(VideoShortViewSuccess(videoShortsId));
    } on ApiException catch (e) {
      _viewedShortIds.remove(videoShortsId);
      emit(VideoShortViewFailure(e.errorMessage));
    } catch (e) {
      _viewedShortIds.remove(videoShortsId);
      emit(VideoShortViewFailure(e.toString()));
    }
  }

  void resetViewTracking() => _viewedShortIds.clear();
}
