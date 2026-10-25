import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/comment_model.dart';
import 'package:news/features/news/repositories/news_comment/like_and_dislike_comment/like_and_dislike_comm_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class LikeAndDislikeCommState {}

class LikeAndDislikeCommInitial extends LikeAndDislikeCommState {}

class LikeAndDislikeCommInProgress extends LikeAndDislikeCommState {}

class LikeAndDislikeCommSuccess extends LikeAndDislikeCommState {
  final CommentModel comment;
  final bool wasLikeAndDislikeCommNewsProcess;
  final bool fromLike;

  LikeAndDislikeCommSuccess(
      this.comment, this.wasLikeAndDislikeCommNewsProcess, this.fromLike);
}

class LikeAndDislikeCommFailure extends LikeAndDislikeCommState {
  final String errorMessage;

  LikeAndDislikeCommFailure(this.errorMessage);
}

class LikeAndDislikeCommCubit extends Cubit<LikeAndDislikeCommState> {
  final LikeAndDislikeCommRepository _likeAndDislikeCommRepository;

  LikeAndDislikeCommCubit(this._likeAndDislikeCommRepository)
      : super(LikeAndDislikeCommInitial());

  void setLikeAndDislikeComm(
      {required String langCode,
      required String commId,
      required String status,
      required bool fromLike}) async {
    try {
      emit(LikeAndDislikeCommInProgress());
      final result = await _likeAndDislikeCommRepository.setLikeAndDislikeComm(
          langCode: langCode, commId: commId, status: status);

      (!result[ERROR])
          ? emit(LikeAndDislikeCommSuccess(
              result['updatedComment'], true, fromLike))
          : emit(LikeAndDislikeCommFailure(result[MESSAGE]));
    } catch (e) {
      emit(LikeAndDislikeCommFailure(e.toString()));
    }
  }
}
