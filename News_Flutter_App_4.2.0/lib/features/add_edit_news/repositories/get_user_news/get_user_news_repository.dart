import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/add_edit_news/repositories/get_user_news/get_user_news_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class GetUserNewsRepository {
  static final GetUserNewsRepository _getUserNewsRepository =
      GetUserNewsRepository._internal();

  late GetUserNewsRemoteDataSource _getUserNewsRemoteDataSource;

  factory GetUserNewsRepository() {
    _getUserNewsRepository._getUserNewsRemoteDataSource =
        GetUserNewsRemoteDataSource();
    return _getUserNewsRepository;
  }

  GetUserNewsRepository._internal();

  Future<dynamic> getGetUserNews(
      {required String offset,
      required String limit,
      String? latitude,
      String? longitude}) async {
    final result = await _getUserNewsRemoteDataSource.getGetUserNews(
        limit: limit, offset: offset, latitude: latitude, longitude: longitude);

    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            "total": result[DATA][TOTAL],
            "GetUserNews": (result[DATA][DATA] as List)
                .map((e) => NewsModel.fromJson(e))
                .toList()
          };
  }
}
