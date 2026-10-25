import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/notification_preferences/models/notification_preference_item.dart';
import 'package:news/features/notification_preferences/repositories/notification_preferences_local_data_source.dart';
import 'package:news/features/notification_preferences/repositories/notification_preference_remote_data_source.dart';

/// Notification preferences: the API is the source of truth, and every fetch or
/// save is mirrored into Hive so the push gate keeps working offline.
class NotificationPreferenceRepository {
  static final NotificationPreferenceRepository _repository =
      NotificationPreferenceRepository._internal();

  late NotificationPreferenceRemoteDataSource _remoteDataSource;
  late NotificationPreferencesLocalDataSource _localDataSource;

  factory NotificationPreferenceRepository() {
    _repository._remoteDataSource = NotificationPreferenceRemoteDataSource();
    _repository._localDataSource = NotificationPreferencesLocalDataSource();
    return _repository;
  }

  NotificationPreferenceRepository._internal();

  Future<List<NotificationPreferenceItem>> getNotificationPreference() async {
    final result = await _remoteDataSource.getNotificationPreference();
    _throwOnApiError(result);

    final List<NotificationPreferenceItem> items =
        notificationPreferencesFromApi(result[DATA]);
    await _localDataSource.save(items);
    return items;
  }

  Future<List<NotificationPreferenceItem>> setNotificationPreference(
      List<NotificationPreferenceItem> items) async {
    final result = await _remoteDataSource.setNotificationPreference(
        body: notificationPreferencesToApiBody(items));
    _throwOnApiError(result);

    final List<NotificationPreferenceItem> saved =
        notificationPreferencesFromApi(result[DATA]);
    final List<NotificationPreferenceItem> updated =
        saved.isEmpty ? items : saved;
    await _localDataSource.save(updated);
    return updated;
  }

  List<NotificationPreferenceItem> getCachedPreferences() {
    return _localDataSource.load();
  }

  /// `Api.sendApiRequest` does not throw on `error: true`, so the flag is
  /// checked here — otherwise a failure would render as an empty list.
  void _throwOnApiError(Map<String, dynamic> result) {
    if (result[ERROR] == true || result[ERROR]?.toString() == 'true') {
      throw ApiMessageAndCodeException(
          errorMessage: result[MESSAGE]?.toString() ??
              ErrorMessageKeys.defaultErrorMessage);
    }
  }
}
