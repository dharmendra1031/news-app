import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/like_and_dislike_news/like_and_dislike_news_data_source.dart';
import 'package:news/core/constants/strings.dart';

class LikeAndDisLikeRepository {
  static final LikeAndDisLikeRepository _LikeAndDisLikeRepository =
      LikeAndDisLikeRepository._internal();
  late LikeAndDisLikeRemoteDataSource _LikeAndDisLikeRemoteDataSource;

  factory LikeAndDisLikeRepository() {
    _LikeAndDisLikeRepository._LikeAndDisLikeRemoteDataSource =
        LikeAndDisLikeRemoteDataSource();
    return _LikeAndDisLikeRepository;
  }

  LikeAndDisLikeRepository._internal();

  Future<Map<String, dynamic>> getLike(
      {required String offset,
      required String limit,
      required String langCode}) async {
    final result = await _LikeAndDisLikeRemoteDataSource.getLike(
        perPage: limit, offset: offset, langCode: langCode);

    return {
      "total": result[DATA][TOTAL],
      "LikeAndDisLike": (result[DATA][DATA] as List)
          .map((e) => NewsModel.fromJson(e))
          .toList()
    };
  }

  Future setLike({required String newsId, required String status}) async {
    final result = await _LikeAndDisLikeRemoteDataSource.addAndRemoveLike(
        status: status, newsId: newsId);
    return result;
  }
}
