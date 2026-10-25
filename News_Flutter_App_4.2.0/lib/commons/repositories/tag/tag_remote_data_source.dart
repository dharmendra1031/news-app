import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class TagRemoteDataSource {
  Future<dynamic> getTag(
      {required String langCode,
      required String offset,
      required String limit}) async {
    try {
      final body = {LANGUAGE_CODE: langCode, LIMIT: limit, OFFSET: offset};
      final result = await Api.sendApiRequest(body: body, url: Api.getTagsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
