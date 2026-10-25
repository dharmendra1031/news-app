import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class ShortNewsRemoteDataSource {
  Future<dynamic> getShortNews({required String langCode}) async {
    try {
      final body = <String, dynamic>{LANGUAGE_CODE: langCode};

      final result =
          await Api.sendApiRequest(body: body, url: Api.getShortNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
