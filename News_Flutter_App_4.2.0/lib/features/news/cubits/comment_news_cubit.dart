import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/comment_model.dart';
import 'package:news/features/news/repositories/comment_news/comm_news_repository.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/strings.dart';

abstract class CommentNewsState {}

class CommentNewsInitial extends CommentNewsState {}

class CommentNewsFetchInProgress extends CommentNewsState {}

class CommentNewsFetchSuccess extends CommentNewsState {
  final List<CommentModel> commentNews;
  final int totalCommentNewsCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  CommentNewsFetchSuccess(
      {required this.commentNews,
      required this.totalCommentNewsCount,
      required this.hasMoreFetchError,
      required this.hasMore});
  CommentNewsFetchSuccess copyWith(
      {List<CommentModel>? commentNews,
      int? totalCommentNewsCount,
      bool? hasMoreFetchError,
      bool? hasMore}) {
    return CommentNewsFetchSuccess(
        commentNews: commentNews ?? this.commentNews,
        totalCommentNewsCount:
            totalCommentNewsCount ?? this.totalCommentNewsCount,
        hasMoreFetchError: hasMoreFetchError ?? this.hasMoreFetchError,
        hasMore: hasMore ?? this.hasMore);
  }
}

class CommentNewsFetchFailure extends CommentNewsState {
  final String errorMessage;

  CommentNewsFetchFailure(this.errorMessage);
}

class CommentNewsCubit extends Cubit<CommentNewsState> {
  final CommentNewsRepository _commentNewsRepository;

  CommentNewsCubit(this._commentNewsRepository) : super(CommentNewsInitial());

  void getCommentNews({required String newsId}) async {
    try {
      emit(CommentNewsFetchInProgress());
      final result = await _commentNewsRepository.getCommentNews(
          limit: limitOfAPIData.toString(), offset: "0", newsId: newsId);

      (!result[ERROR])
          ? emit(CommentNewsFetchSuccess(
              commentNews: result['CommentNews'],
              totalCommentNewsCount: result[TOTAL],
              hasMoreFetchError: false,
              hasMore: ((result['CommentNews'] as List<CommentModel>).length) <
                  result[TOTAL]))
          : emit(CommentNewsFetchFailure(result[MESSAGE]));
    } catch (e) {
      emit(CommentNewsFetchFailure(e.toString()));
    }
  }

  bool hasMoreCommentNews() {
    return (state is CommentNewsFetchSuccess)
        ? (state as CommentNewsFetchSuccess).hasMore
        : false;
  }

  void getMoreCommentNews({required String newsId}) async {
    if (state is CommentNewsFetchSuccess) {
      try {
        final result = await _commentNewsRepository.getCommentNews(
            limit: limitOfAPIData.toString(),
            newsId: newsId,
            offset: (state as CommentNewsFetchSuccess)
                .commentNews
                .length
                .toString());
        List<CommentModel> updatedResults =
            (state as CommentNewsFetchSuccess).commentNews;
        updatedResults.addAll(result['CommentNews'] as List<CommentModel>);
        emit(CommentNewsFetchSuccess(
            commentNews: updatedResults,
            totalCommentNewsCount: result[TOTAL],
            hasMoreFetchError: false,
            hasMore: updatedResults.length < result[TOTAL]));
      } catch (e) {
        emit(CommentNewsFetchSuccess(
            commentNews: (state as CommentNewsFetchSuccess).commentNews,
            hasMoreFetchError: true,
            totalCommentNewsCount:
                (state as CommentNewsFetchSuccess).totalCommentNewsCount,
            hasMore: (state as CommentNewsFetchSuccess).hasMore));
      }
    }
  }

  emitSuccessState(List<CommentModel> commments) {
    emit((state as CommentNewsFetchSuccess).copyWith(commentNews: commments));
  }

  void commentUpdateList(List<CommentModel> commentList, int total) {
    if (state is CommentNewsFetchSuccess || state is CommentNewsFetchFailure) {
      bool haseMore = (state is CommentNewsFetchSuccess)
          ? (state as CommentNewsFetchSuccess).hasMore
          : false;
      emit(CommentNewsFetchSuccess(
          commentNews: commentList,
          hasMore: haseMore,
          hasMoreFetchError: false,
          totalCommentNewsCount: total));
    }
  }

  void deleteComment(int index) {
    if (state is CommentNewsFetchSuccess) {
      List<CommentModel> commentList =
          List.from((state as CommentNewsFetchSuccess).commentNews)
            ..removeAt(index);

      emit(CommentNewsFetchSuccess(
          commentNews: commentList,
          hasMore: (state as CommentNewsFetchSuccess).hasMore,
          hasMoreFetchError: false,
          totalCommentNewsCount:
              (state as CommentNewsFetchSuccess).totalCommentNewsCount - 1));
    }
  }

  void deleteCommentReply(String commentId, int index) {
    if (state is CommentNewsFetchSuccess) {
      List<CommentModel> commentList =
          (state as CommentNewsFetchSuccess).commentNews;
      commentList.forEach((element) {
        if (element.id! == commentId) {
          int commIndex =
              commentList.indexWhere((model) => model.id == commentId);
          commentList[commIndex].replyComList!.removeAt(index);
        }
      });
      emit(CommentNewsFetchSuccess(
          commentNews: commentList,
          hasMore: (state as CommentNewsFetchSuccess).hasMore,
          hasMoreFetchError: false,
          totalCommentNewsCount:
              (state as CommentNewsFetchSuccess).totalCommentNewsCount));
    }
  }
}
