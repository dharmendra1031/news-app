import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class GetUserNewsRemoteDataSource {
  Future<dynamic> getGetUserNews(
      {required String limit,
      required String offset,
      String? latitude,
      String? longitude}) async {
    try {
      final body = {LIMIT: limit, OFFSET: offset, USER_NEWS: 1};
      if (latitude != null && latitude != "null") body[LATITUDE] = latitude;
      if (longitude != null && longitude != "null") body[LONGITUDE] = longitude;
      final result = await Api.sendApiRequest(body: body, url: Api.getNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
