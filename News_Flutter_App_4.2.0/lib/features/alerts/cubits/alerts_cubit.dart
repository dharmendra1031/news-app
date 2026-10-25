import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/alerts/models/alert_item_data.dart';
import 'package:news/features/alerts/repositories/alerts_repository.dart';

/// Market alerts (`get_market_alerts`) for the home page's "Alerts" section and
/// the full [AlertsScreen]. Registered app-wide so both share a single fetch.

abstract class AlertsState {}

class AlertsInitial extends AlertsState {}

class AlertsFetchInProgress extends AlertsState {}

class AlertsFetchSuccess extends AlertsState {
  final List<AlertItemData> alerts;

  AlertsFetchSuccess({required this.alerts});
}

class AlertsFetchFailure extends AlertsState {
  final String errorMessage;

  AlertsFetchFailure(this.errorMessage);
}

class AlertsCubit extends Cubit<AlertsState> {
  final AlertsRepository _alertsRepository;

  AlertsCubit(this._alertsRepository) : super(AlertsInitial());

  Future<void> getMarketAlerts() async {
    try {
      emit(AlertsFetchInProgress());
      final alerts = await _alertsRepository.getMarketAlerts();
      emit(AlertsFetchSuccess(alerts: alerts));
    } catch (e) {
      emit(AlertsFetchFailure(e.toString()));
    }
  }
}
