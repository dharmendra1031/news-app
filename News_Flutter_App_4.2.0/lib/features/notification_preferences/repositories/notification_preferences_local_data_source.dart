import 'package:hive_flutter/adapters.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/features/notification_preferences/models/notification_preference_item.dart';

/// Hive mirror of the notification preferences, because [PushNotificationService]
/// gates pushes synchronously and offline. Unmapped push types always show.
class NotificationPreferencesLocalDataSource {
  Box get _box => Hive.box(settingsBoxKey);

  List<NotificationPreferenceItem> load() {
    return notificationPreferencesFromApi(_box.get(notificationPreferencesKey));
  }

  Future<void> save(List<NotificationPreferenceItem> items) async {
    await _box.put(notificationPreferencesKey,
        items.map((item) => item.toJson()).toList());
  }

  static const Map<String, String> typeToPreferenceKey = <String, String>{
    'comment': 'comments',
    'comment_like': 'comments',
    'default': 'news',
    'category': 'news',
    'newlyadded': 'news',
    'podcast': 'podcasts',
    'podcast_episode': 'podcasts',
    'market_alert': 'alerts',
    'alert': 'alerts',
  };

  bool shouldShowType(String? type) {
    final String? key = typeToPreferenceKey[type];
    if (key == null) return true;
    return isEnabled(key);
  }

  bool isEnabled(String key, {bool fallback = true}) {
    final dynamic raw = _box.get(notificationPreferencesKey);
    if (raw is List) {
      for (final dynamic row in raw) {
        if (row is Map && row['key']?.toString() == key) {
          final dynamic value = row['enabled'];
          if (value is bool) return value;
        }
      }
    }
    return fallback;
  }
}
