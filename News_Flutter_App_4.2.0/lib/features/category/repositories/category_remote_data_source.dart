import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class CategoryRemoteDataSource {
  Future<dynamic> getCategory(
      {required String limit,
      required String offset,
      required String langCode}) async {
    try {
      final body = {LIMIT: limit, OFFSET: offset, LANGUAGE_CODE: langCode};
      final result = await Api.sendApiRequest(body: body, url: Api.getCatApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
