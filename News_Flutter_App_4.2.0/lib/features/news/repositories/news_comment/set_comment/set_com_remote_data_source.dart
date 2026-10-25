import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SetCommentRemoteDataSource {
  Future<dynamic> setComment({
    String? parentId,
    required String newsId,
    required String message,
    required String langCode,
  }) async {
    try {
      final body = {
        if (parentId != null) PARENT_ID: parentId,
        NEWS_ID: newsId,
        MESSAGE: message,
        LANGUAGE_CODE: langCode
      };
      final result =
          await Api.sendApiRequest(body: body, url: Api.setCommentApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
