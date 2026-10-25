import 'package:news/core/api/api.dart';

/// Calls `get_market_alerts` -> { data: { total, data: [ alert ] } }.
/// Needs no auth token and no parameters; returns only the active alerts.
class AlertsRemoteDataSource {
  Future<dynamic> getMarketAlerts() async {
    try {
      return await Api.sendApiRequest(
          body: <String, dynamic>{}, url: Api.getMarketAlertsApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
