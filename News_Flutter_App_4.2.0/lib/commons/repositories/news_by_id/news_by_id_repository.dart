import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/repositories/news_by_id/news_by_id_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class NewsByIdRepository {
  static final NewsByIdRepository _newsByIdRepository =
      NewsByIdRepository._internal();

  late NewsByIdRemoteDataSource _newsByIdRemoteDataSource;

  factory NewsByIdRepository() {
    _newsByIdRepository._newsByIdRemoteDataSource = NewsByIdRemoteDataSource();
    return _newsByIdRepository;
  }

  NewsByIdRepository._internal();

  Future<Map<String, dynamic>> getNewsById(
      {required String newsId, required String langCode}) async {
    final result = await _newsByIdRemoteDataSource.getNewsById(
        newsId: newsId, langCode: langCode);

    return {
      "NewsById": (result[DATA][DATA] as List)
          .map((e) => NewsModel.fromJson(e))
          .toList()
    };
  }
}
