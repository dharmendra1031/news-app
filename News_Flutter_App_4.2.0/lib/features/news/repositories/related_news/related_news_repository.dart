import 'package:news/features/news/repositories/related_news/related_news_data_source.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/constants/strings.dart';

class RelatedNewsRepository {
  static final RelatedNewsRepository _relatedNewsRepository =
      RelatedNewsRepository._internal();

  late RelatedNewsRemoteDataSource _relatedNewsRemoteDataSource;

  factory RelatedNewsRepository() {
    _relatedNewsRepository._relatedNewsRemoteDataSource =
        RelatedNewsRemoteDataSource();
    return _relatedNewsRepository;
  }

  RelatedNewsRepository._internal();

  Future<Map<String, dynamic>> getRelatedNews(
      {required String langCode,
      required String offset,
      required String perPage,
      String? catId,
      String? subCatId,
      String? latitude,
      String? longitude}) async {
    final result = await _relatedNewsRemoteDataSource.getRelatedNews(
        langCode: langCode,
        catId: catId,
        subCatId: subCatId,
        latitude: latitude,
        longitude: longitude,
        offset: offset,
        perPage: perPage);

    return {
      "RelatedNews": (result[DATA][DATA] as List)
          .map((e) => NewsModel.fromJson(e))
          .toList(),
      "total": result[DATA][TOTAL]
    };
  }
}
