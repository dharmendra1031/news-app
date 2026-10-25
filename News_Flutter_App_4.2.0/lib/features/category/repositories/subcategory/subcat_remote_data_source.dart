import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SubCategoryRemoteDataSource {
  Future<dynamic> getSubCategory(
      {required String catId, required String langCode}) async {
    try {
      final body = {CATEGORY_ID: catId, LANGUAGE_CODE: langCode};
      final result =
          await Api.sendApiRequest(body: body, url: Api.getSubCategoryApi);

      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
