import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class LanguageJsonRemoteDataSource {
  Future<dynamic> getLanguageJson({required String lanCode}) async {
    try {
      final body = {LANGUAGE_CODE: lanCode, PLATFORM_TYPE: "app"};
      final result =
          await Api.sendApiRequest(body: body, url: Api.getLangJsonDataApi);

      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
