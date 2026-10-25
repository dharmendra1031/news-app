import 'package:news/core/constants/strings.dart';
import 'package:news/core/api/api.dart';

class BookmarkRemoteDataSource {
  Future<dynamic> getBookmark(
      {required String langCode,
      required String offset,
      required String perPage}) async {
    try {
      final body = {LANGUAGE_CODE: langCode, OFFSET: offset, LIMIT: perPage};
      final result =
          await Api.sendApiRequest(body: body, url: Api.getBookmarkApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future addBookmark({required String newsId, required String status}) async {
    try {
      final body = {NEWS_ID: newsId, STATUS: status};
      final result =
          await Api.sendApiRequest(body: body, url: Api.setBookmarkApi);

      final isSuccess = result[ERROR] == false ||
          (result[MESSAGE]?.toString().toLowerCase().contains("success") ??
              false) ||
          result[CODE] == 200;

      if (isSuccess) {
        // Return full response so Cubit can read MESSAGE even if data is null
        return result;
      } else {
        throw ApiException(
            result[MESSAGE]?.toString() ?? "Something went wrong");
      }
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
