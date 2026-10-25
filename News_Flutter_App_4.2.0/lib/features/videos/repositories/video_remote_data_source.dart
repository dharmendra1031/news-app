import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class VideoRemoteDataSource {
  Future<dynamic> getVideos(
      {required String limit,
      required String offset,
      required String langCode,
      String? latitude,
      String? longitude,
      String? slug}) async {
    try {
      final body = {LIMIT: limit, OFFSET: offset, LANGUAGE_CODE: langCode};
      if (latitude != null && latitude != "null") body[LATITUDE] = latitude;
      if (longitude != null && longitude != "null") body[LONGITUDE] = longitude;
      if (slug != null && slug != "null" && slug.trim().isNotEmpty) {
        body[SLUG] = slug;
      }

      final result =
          await Api.sendApiRequest(body: body, url: Api.getVideosApi);

      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
