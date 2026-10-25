import 'package:news/core/constants/strings.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/error_handler/error_message_keys.dart';

class LikeAndDisLikeRemoteDataSource {
  Future<dynamic> getLike(
      {required String langCode,
      required String offset,
      required String perPage}) async {
    try {
      final body = {LANGUAGE_CODE: langCode, OFFSET: offset, LIMIT: perPage};

      final result =
          await Api.sendApiRequest(body: body, url: Api.getLikeNewsApi);

      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future addAndRemoveLike(
      {required String newsId, required String status}) async {
    try {
      final body = {NEWS_ID: newsId, STATUS: status};
      final result =
          await Api.sendApiRequest(body: body, url: Api.setLikesDislikesApi);

      // The endpoint answers a successful like with no `message` and no `code`,
      // so anything other than an explicit error is a success. Requiring one of
      // those keys reported every like as a failure.
      final dynamic error = result[ERROR];
      if (error == true || error.toString().toLowerCase() == "true") {
        throw ApiException(result[MESSAGE]?.toString() ??
            ErrorMessageKeys.defaultErrorMessage);
      }

      // Return the full response so the cubit can read MESSAGE even if data is null
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
