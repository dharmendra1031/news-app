import 'package:news/core/api/api.dart';

/// Authenticated get/set notification-preference endpoints. Both are POST-only
/// and answer with the full current list: `{ data: [ {id, key, label, enabled} ] }`.
class NotificationPreferenceRemoteDataSource {
  Future<dynamic> getNotificationPreference() async {
    try {
      final result = await Api.sendApiRequest(
          body: <String, dynamic>{}, url: Api.getNotificationPreferenceApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> setNotificationPreference(
      {required Map<String, String> body}) async {
    try {
      final result = await Api.sendApiRequest(
          body: body, url: Api.setNotificationPreferenceApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
