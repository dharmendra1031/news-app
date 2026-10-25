import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SetUserPrefCatRemoteDataSource {
  Future<dynamic> setUserPrefCat({required String catId}) async {
    try {
      final body = {CATEGORY_ID: catId};
      final result =
          await Api.sendApiRequest(body: body, url: Api.setUserCatApi);

      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
