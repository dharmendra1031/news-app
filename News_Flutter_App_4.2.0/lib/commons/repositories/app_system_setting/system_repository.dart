import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SystemRepository {
  Future<dynamic> fetchSettings() async {
    try {
      final result = await Api.sendApiRequest(url: Api.getSettingApi, body: {});
      return result[DATA];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
