import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/alerts/models/alert_item_data.dart';
import 'package:news/features/alerts/repositories/alerts_remote_data_source.dart';

/// Single entry point for market alerts. `Api.sendApiRequest` does not throw on
/// `error: true`, so the flag is checked here; "no alerts" returns an empty list.
class AlertsRepository {
  static final AlertsRepository _alertsRepository =
      AlertsRepository._internal();

  late AlertsRemoteDataSource _alertsRemoteDataSource;

  factory AlertsRepository() {
    _alertsRepository._alertsRemoteDataSource = AlertsRemoteDataSource();
    return _alertsRepository;
  }

  AlertsRepository._internal();

  Future<List<AlertItemData>> getMarketAlerts() async {
    final result = await _alertsRemoteDataSource.getMarketAlerts();

    if (result[ERROR] == true || result[ERROR]?.toString() == 'true') {
      throw ApiMessageAndCodeException(
          errorMessage: result[MESSAGE]?.toString() ??
              ErrorMessageKeys.defaultErrorMessage);
    }

    final dynamic payload = result[DATA];
    if (payload is! Map) return const <AlertItemData>[];

    final dynamic alerts = payload[DATA];
    if (alerts is! List) return const <AlertItemData>[];

    return alerts
        .whereType<Map>()
        .map((alert) =>
            AlertItemData.fromJson(Map<String, dynamic>.from(alert)))
        .toList();
  }
}
