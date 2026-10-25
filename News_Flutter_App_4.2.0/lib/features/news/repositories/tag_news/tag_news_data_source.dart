import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class TagNewsRemoteDataSource {
  Future<dynamic> getTagNews(
      {required String tagId,
      required String langCode,
      String? latitude,
      String? longitude}) async {
    try {
      final body = {TAG_ID: tagId, LANGUAGE_CODE: langCode};
      if (latitude != null && latitude != "null") body[LATITUDE] = latitude;
      if (longitude != null && longitude != "null") body[LONGITUDE] = longitude;

      final result = await Api.sendApiRequest(body: body, url: Api.getNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
