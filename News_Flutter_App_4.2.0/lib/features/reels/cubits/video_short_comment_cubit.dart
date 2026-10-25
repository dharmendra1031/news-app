import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/reels/models/video_short_comment_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class VideoShortCommentState {}

class VideoShortCommentInitial extends VideoShortCommentState {}

class VideoShortCommentFetchInProgress extends VideoShortCommentState {}

class VideoShortCommentFetchSuccess extends VideoShortCommentState {
  final String videoShortsId;
  final List<VideoShortCommentModel> comments;
  final int totalCount;

  VideoShortCommentFetchSuccess({
    required this.videoShortsId,
    required this.comments,
    required this.totalCount,
  });
}

class VideoShortCommentFetchFailure extends VideoShortCommentState {
  final String errorMessage;
  final String? videoShortsId;

  VideoShortCommentFetchFailure(this.errorMessage, {this.videoShortsId});
}

class VideoShortCommentCubit extends Cubit<VideoShortCommentState> {
  VideoShortCommentCubit() : super(VideoShortCommentInitial());

  List<VideoShortCommentModel> _parseComments(dynamic raw) {
    if (raw == null) return [];

    List<dynamic> items = [];
    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map[DATA] is List) {
        items = map[DATA] as List;
      } else if (map[DATA] is Map) {
        final inner = Map<String, dynamic>.from(map[DATA]);
        if (inner[DATA] is List) {
          items = inner[DATA] as List;
        }
      } else if (map['comments'] is List) {
        items = map['comments'] as List;
      }
    }

    return items
        .whereType<Map>()
        .map((e) =>
            VideoShortCommentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  int _parseTotal(dynamic raw, int fallback) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map[TOTAL] != null) {
        return int.tryParse(map[TOTAL].toString()) ?? fallback;
      }
      if (map[DATA] is Map) {
        final inner = Map<String, dynamic>.from(map[DATA]);
        if (inner[TOTAL] != null) {
          return int.tryParse(inner[TOTAL].toString()) ?? fallback;
        }
      }
    }
    return fallback;
  }

  Future<void> getVideoShortComments({
    required String videoShortsId,
  }) async {
    try {
      emit(VideoShortCommentFetchInProgress());

      final result = await Api.sendApiRequest(
        body: {VIDEO_SHORTS_ID: videoShortsId},
        url: Api.getVideoShortCommentApi,
      );

      if (result[ERROR] == true) {
        emit(VideoShortCommentFetchFailure(
          result[MESSAGE]?.toString() ?? '',
          videoShortsId: videoShortsId,
        ));
        return;
      }

      final comments = _parseComments(result[DATA][DATA]);
      emit(VideoShortCommentFetchSuccess(
        videoShortsId: videoShortsId,
        comments: comments,
        totalCount: _parseTotal(result[DATA][DATA], comments.length),
      ));
    } on ApiException catch (e) {
      emit(VideoShortCommentFetchFailure(
        e.errorMessage,
        videoShortsId: videoShortsId,
      ));
    } catch (e) {
      emit(VideoShortCommentFetchFailure(
        e.toString(),
        videoShortsId: videoShortsId,
      ));
    }
  }

  void prependComment(VideoShortCommentModel comment) {
    if (state is! VideoShortCommentFetchSuccess) return;
    final current = state as VideoShortCommentFetchSuccess;
    emit(VideoShortCommentFetchSuccess(
      videoShortsId: current.videoShortsId,
      comments: [comment, ...current.comments],
      totalCount: current.totalCount + 1,
    ));
  }
}
