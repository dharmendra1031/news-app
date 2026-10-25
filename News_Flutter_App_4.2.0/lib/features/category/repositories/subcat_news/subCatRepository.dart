import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/category/repositories/subcat_news/subCatNewsRemoteDataSource.dart';
import 'package:news/core/constants/strings.dart';

class SubCatNewsRepository {
  static final SubCatNewsRepository _subCatNewsRepository =
      SubCatNewsRepository._internal();

  late SubCatNewsRemoteDataSource _subCatNewsRemoteDataSource;

  factory SubCatNewsRepository() {
    _subCatNewsRepository._subCatNewsRemoteDataSource =
        SubCatNewsRemoteDataSource();
    return _subCatNewsRepository;
  }

  SubCatNewsRepository._internal();

  Future<Map<String, dynamic>> getSubCatNews(
      {required String offset,
      required String limit,
      String? catId,
      String? subCatId,
      String? latitude,
      String? longitude,
      required String langCode}) async {
    final result = await _subCatNewsRemoteDataSource.getSubCatNews(
        limit: limit,
        offset: offset,
        langCode: langCode,
        subCatId: subCatId,
        catId: catId,
        latitude: latitude,
        longitude: longitude);

    if (result[ERROR]) {
      return {ERROR: result[ERROR]};
    } else {
      return {
        ERROR: result[ERROR],
        "total": result[DATA][TOTAL],
        "SubCatNews": (result[DATA][DATA] as List)
            .map((e) => NewsModel.fromJson(e))
            .toList()
      };
    }
  }
}
