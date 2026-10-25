import 'package:news/core/constants/strings.dart';
import 'package:news/core/api/api.dart';

class GetSurveyAnsRemoteDataSource {
  Future<dynamic> getSurveyAns({required String langCode}) async {
    try {
      final body = {LANGUAGE_CODE: langCode};
      final result =
          await Api.sendApiRequest(body: body, url: Api.getQueResultApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
