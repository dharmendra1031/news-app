/// One notification type from `get_notification_preference`. The backend owns
/// the list (types, order, ids); the app owns the copy via [_copyByKey].
class NotificationPreferenceItem {
  final int typeId;
  final String key;
  final String label;
  final bool enabled;

  const NotificationPreferenceItem({
    required this.typeId,
    required this.key,
    required this.label,
    required this.enabled,
  });

  String get titleKey => _copyByKey[key]?.title ?? label;

  String? get descriptionKey => _copyByKey[key]?.description;

  NotificationPreferenceItem copyWith({bool? enabled}) {
    return NotificationPreferenceItem(
      typeId: typeId,
      key: key,
      label: label,
      enabled: enabled ?? this.enabled,
    );
  }

  factory NotificationPreferenceItem.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceItem(
      typeId: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      enabled: _asBool(json['enabled'], true),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': typeId,
        'key': key,
        'label': label,
        'enabled': enabled,
      };
}

class _PreferenceCopy {
  final String title;
  final String description;

  const _PreferenceCopy(this.title, this.description);
}

const Map<String, _PreferenceCopy> _copyByKey = <String, _PreferenceCopy>{
  'news': _PreferenceCopy('newsNotiTitle', 'newsNotiDesc'),
  'podcasts': _PreferenceCopy('podcastNotiTitle', 'podcastNotiDesc'),
  'alerts': _PreferenceCopy('marketAlertNotiTitle', 'marketAlertNotiDesc'),
  'comments': _PreferenceCopy('commentReplyNotiTitle', 'commentReplyNotiDesc'),
  'announcements':
      _PreferenceCopy('promotionalNotiTitle', 'promotionalNotiDesc'),
};

bool _asBool(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final String s = value.trim().toLowerCase();
    if (s == '1' || s == 'true' || s == 'yes' || s == 'on') return true;
    if (s == '0' || s == 'false' || s == 'no' || s == 'off') return false;
  }
  return fallback;
}

List<NotificationPreferenceItem> notificationPreferencesFromApi(dynamic data) {
  if (data is! List) return const <NotificationPreferenceItem>[];

  return data
      .whereType<Map>()
      .map((row) =>
          NotificationPreferenceItem.fromJson(Map<String, dynamic>.from(row)))
      .where((item) => item.key.isNotEmpty)
      .toList();
}

bool anyPreferenceEnabled(List<NotificationPreferenceItem> items) {
  return items.any((item) => item.enabled);
}

Map<String, String> notificationPreferencesToApiBody(
    List<NotificationPreferenceItem> items) {
  final Map<String, String> body = <String, String>{};
  for (int i = 0; i < items.length; i++) {
    body['preferences[$i][notification_type_id]'] = items[i].typeId.toString();
    body['preferences[$i][status]'] = items[i].enabled ? '1' : '0';
  }
  return body;
}
