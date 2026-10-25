import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class BreakingNewsRemoteDataSource {
  Future<dynamic> getBreakingNews({required String langCode}) async {
    try {
      final body = {LANGUAGE_CODE: langCode};
      final result =
          await Api.sendApiRequest(body: body, url: Api.getBreakingNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
