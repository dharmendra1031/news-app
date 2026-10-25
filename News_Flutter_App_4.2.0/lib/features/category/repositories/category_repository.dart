import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/category/repositories/category_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class CategoryRepository {
  static final CategoryRepository _notificationRepository =
      CategoryRepository._internal();

  late CategoryRemoteDataSource _notificationRemoteDataSource;

  factory CategoryRepository() {
    _notificationRepository._notificationRemoteDataSource =
        CategoryRemoteDataSource();
    return _notificationRepository;
  }

  CategoryRepository._internal();

  Future<Map<String, dynamic>> getCategory(
      {required String offset,
      required String limit,
      required String langCode}) async {
    final result = await _notificationRemoteDataSource.getCategory(
        limit: limit, offset: offset, langCode: langCode);

    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            "total": result[DATA][TOTAL],
            "Category": (result[DATA][DATA] as List)
                .map((e) => CategoryModel.fromJson(e))
                .toList()
          };
  }
}
