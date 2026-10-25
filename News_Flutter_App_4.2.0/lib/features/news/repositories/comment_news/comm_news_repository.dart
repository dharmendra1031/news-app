import 'package:news/features/news/models/comment_model.dart';
import 'package:news/features/news/repositories/comment_news/comm_news_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class CommentNewsRepository {
  static final CommentNewsRepository _commentNewsRepository =
      CommentNewsRepository._internal();

  late CommentNewsRemoteDataSource _commentNewsRemoteDataSource;

  factory CommentNewsRepository() {
    _commentNewsRepository._commentNewsRemoteDataSource =
        CommentNewsRemoteDataSource();
    return _commentNewsRepository;
  }

  CommentNewsRepository._internal();

  Future<Map<String, dynamic>> getCommentNews(
      {required String offset,
      required String limit,
      required String newsId}) async {
    final result = await _commentNewsRemoteDataSource.getCommentNews(
        limit: limit, offset: offset, newsId: newsId);
    if (result[ERROR]) {
      return {ERROR: result[ERROR], MESSAGE: result[MESSAGE]};
    } else {
      final List<CommentModel> commentsList = (result[DATA][DATA] as List)
          .map((e) => CommentModel.fromJson(e))
          .toList();
      final List<ReplyModel> replyList = [];
      for (var i in commentsList) {
        replyList.addAll(i.replyComList as List<ReplyModel>);
      }
      return {
        ERROR: result[ERROR],
        "total": result[DATA][TOTAL],
        "CommentNews": commentsList
      };
    }
  }
}
