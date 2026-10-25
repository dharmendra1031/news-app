import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SetSurveyAnsRemoteDataSource {
  Future<dynamic> setSurveyAns(
      {required String queId,
      required String optId,
      required String languageCode}) async {
    try {
      final body = {
        QUESTION_ID: queId,
        OPTION_ID: optId,
        LANGUAGE_CODE: languageCode
      };
      final result =
          await Api.sendApiRequest(body: body, url: Api.setQueResultApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
