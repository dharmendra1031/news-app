import 'package:news/features/news/repositories/news_comment/set_comment/set_com_remote_data_source.dart';
import 'package:news/features/news/models/comment_model.dart';
import 'package:news/core/constants/strings.dart';

class SetCommentRepository {
  static final SetCommentRepository _setCommentRepository =
      SetCommentRepository._internal();

  late SetCommentRemoteDataSource _setCommentRemoteDataSource;

  factory SetCommentRepository() {
    _setCommentRepository._setCommentRemoteDataSource =
        SetCommentRemoteDataSource();
    return _setCommentRepository;
  }
  SetCommentRepository._internal();
  Future<Map<String, dynamic>> setComment(
      {String? parentId,
      required String newsId,
      required String message,
      required String langCode}) async {
    final result = await _setCommentRemoteDataSource.setComment(
        parentId: parentId,
        newsId: newsId,
        message: message,
        langCode: langCode);
    return {
      "SetComment": (result[DATA][DATA] as List)
          .map((e) => CommentModel.fromJson(e))
          .toList(),
      "total": result[DATA][TOTAL]
    };
  }
}
