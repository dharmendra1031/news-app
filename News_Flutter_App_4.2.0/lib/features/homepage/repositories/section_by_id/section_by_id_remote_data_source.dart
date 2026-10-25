import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SectionByIdRemoteDataSource {
  Future<dynamic> getSectionById(
      {required String langCode,
      required String limit,
      required String offset,
      required String sectionId,
      String? latitude,
      String? longitude}) async {
    try {
      final body = {
        LANGUAGE_CODE: langCode,
        SECTION_ID: sectionId,
        PLATFORM: "app"
      };
      if (latitude != null && latitude != "null") body[LATITUDE] = latitude;
      if (longitude != null && longitude != "null") body[LONGITUDE] = longitude;

      if (sectionId.isNotEmpty) {
        body[SECTION_ID] = sectionId;
      }
      body[LIMIT] = limit;
      body[OFFSET] = offset;
      final result =
          await Api.sendApiRequest(body: body, url: Api.getFeatureSectionApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
