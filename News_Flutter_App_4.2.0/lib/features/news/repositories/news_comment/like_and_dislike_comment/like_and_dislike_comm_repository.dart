import 'package:news/features/news/models/comment_model.dart';
import 'package:news/features/news/repositories/news_comment/like_and_dislike_comment/like_and_dislike_comm_data_source.dart';
import 'package:news/core/constants/strings.dart';

class LikeAndDislikeCommRepository {
  static final LikeAndDislikeCommRepository _likeAndDislikeCommRepository =
      LikeAndDislikeCommRepository._internal();
  late LikeAndDislikeCommRemoteDataSource _likeAndDislikeCommRemoteDataSource;

  factory LikeAndDislikeCommRepository() {
    _likeAndDislikeCommRepository._likeAndDislikeCommRemoteDataSource =
        LikeAndDislikeCommRemoteDataSource();
    return _likeAndDislikeCommRepository;
  }

  LikeAndDislikeCommRepository._internal();

  Future<Map<String, dynamic>> setLikeAndDislikeComm(
      {required String langCode,
      required String commId,
      required String status}) async {
    final result = await _likeAndDislikeCommRemoteDataSource.likeAndDislikeComm(
        langCode: langCode, commId: commId, status: status);

    if (result[ERROR]) {
      return {ERROR: result[ERROR], MESSAGE: result[MESSAGE]};
    } else {
      final List<CommentModel> commentsList = (result[DATA][DATA] as List)
          .map((e) => CommentModel.fromJson(e))
          .toList();
      CommentModel? updatedComment;

      commentsList.forEach((element) {
        if (element.id! == commId) {
          updatedComment = element;
        } else if (element.replyComList!
                .any((sublist) => sublist.id == commId) ==
            true) {
          updatedComment = element;
        }
      });
      return {
        ERROR: result[ERROR],
        "total": result[DATA][TOTAL],
        "updatedComment": updatedComment ?? CommentModel.fromJson({})
      };
    }
  }
}
