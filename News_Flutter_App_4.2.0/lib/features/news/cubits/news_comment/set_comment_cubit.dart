import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/comment_model.dart';
import 'package:news/features/news/repositories/news_comment/set_comment/set_com_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class SetCommentState {}

class SetCommentInitial extends SetCommentState {}

class SetCommentFetchInProgress extends SetCommentState {}

class SetCommentFetchSuccess extends SetCommentState {
  List<CommentModel> setComment;
  int total;

  SetCommentFetchSuccess({required this.setComment, required this.total});
}

class SetCommentFetchFailure extends SetCommentState {
  final String errorMessage;

  SetCommentFetchFailure(this.errorMessage);
}

class SetCommentCubit extends Cubit<SetCommentState> {
  final SetCommentRepository _setCommentRepository;

  SetCommentCubit(this._setCommentRepository) : super(SetCommentInitial());

  void setComment(
      {String? parentId,
      required String newsId,
      required String message,
      required String langCode}) async {
    emit(SetCommentFetchInProgress());
    try {
      final result = await _setCommentRepository.setComment(
          message: message,
          newsId: newsId,
          parentId: parentId,
          langCode: langCode);
      emit(SetCommentFetchSuccess(
          setComment: result['SetComment'], total: result[TOTAL]));
    } catch (e) {
      emit(SetCommentFetchFailure(e.toString()));
    }
  }
}
