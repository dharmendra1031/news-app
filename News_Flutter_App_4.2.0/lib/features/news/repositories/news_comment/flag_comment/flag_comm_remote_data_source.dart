import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SetFlagRemoteDataSource {
  Future<dynamic> setFlag(
      {required String commId,
      required String newsId,
      required String message}) async {
    try {
      final body = {COMMENT_ID: commId, NEWS_ID: newsId, MESSAGE: message};
      final result = await Api.sendApiRequest(body: body, url: Api.setFlagApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
