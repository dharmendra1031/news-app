import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/tag_news/tag_news_data_source.dart';
import 'package:news/core/constants/strings.dart';

class TagNewsRepository {
  static final TagNewsRepository _tagNewsRepository =
      TagNewsRepository._internal();

  late TagNewsRemoteDataSource _tagNewsRemoteDataSource;

  factory TagNewsRepository() {
    _tagNewsRepository._tagNewsRemoteDataSource = TagNewsRemoteDataSource();
    return _tagNewsRepository;
  }

  TagNewsRepository._internal();

  Future<Map<String, dynamic>> getTagNews(
      {required String tagId,
      required String langCode,
      String? latitude,
      String? longitude}) async {
    final result = await _tagNewsRemoteDataSource.getTagNews(
        tagId: tagId,
        langCode: langCode,
        latitude: latitude,
        longitude: longitude);

    return {
      "TagNews": (result[DATA][DATA] as List)
          .map((e) => NewsModel.fromJson(e))
          .toList()
    };
  }
}
