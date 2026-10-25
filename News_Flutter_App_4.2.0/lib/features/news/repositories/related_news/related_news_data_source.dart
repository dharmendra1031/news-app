import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class RelatedNewsRemoteDataSource {
  Future<dynamic> getRelatedNews(
      {required String langCode,
      String? catId,
      String? subCatId,
      String? latitude,
      String? longitude,
      required String offset,
      required String perPage}) async {
    try {
      final body = {
        LANGUAGE_CODE: langCode,
        OFFSET: offset,
        LIMIT: perPage,
        MERGE_TAG: 1
      }; //merge_tag used to get related news according to tagId along with cat or Subcat Id
      (subCatId != "0" && subCatId != '')
          ? body[SUBCAT_ID] = subCatId!
          : body[CATEGORY_ID] = catId!;
      if (latitude != null && latitude != "null") body[LATITUDE] = latitude;
      if (longitude != null && longitude != "null") body[LONGITUDE] = longitude;

      final result = await Api.sendApiRequest(body: body, url: Api.getNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
