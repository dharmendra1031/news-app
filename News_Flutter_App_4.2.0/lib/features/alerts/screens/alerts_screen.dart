import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/alerts/cubits/alerts_cubit.dart';
import 'package:news/features/alerts/widgets/alert_card.dart';

/// Full "Alerts" list screen (`Routes.alertsList`), opened from [AlertsView]'s
/// "View More". Reuses the app-wide [AlertsCubit]; fetches only when opened cold.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return MaterialPageRoute(builder: (_) => const AlertsScreen());
  }

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      if (context.read<AlertsCubit>().state is AlertsInitial) _fetchAlerts();
    });
  }

  void _fetchAlerts() => context.read<AlertsCubit>().getMarketAlerts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
          height: 54, isBackBtn: true, isConvertText: true, label: 'alerts'),
      body: BlocBuilder<AlertsCubit, AlertsState>(
        builder: (context, state) {
          if (state is AlertsFetchInProgress || state is AlertsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AlertsFetchFailure) {
            return Center(
                child: ErrorContainerWidget(
                    errorMsg: state.errorMessage, onRetry: _fetchAlerts));
          }

          if (state is AlertsFetchSuccess) {
            if (state.alerts.isEmpty) {
              return Center(
                  child: ErrorContainerWidget(
                      errorMsg: ErrorMessageKeys.noDataMessage,
                      onRetry: _fetchAlerts));
            }

            return RefreshIndicator(
              onRefresh: () async => _fetchAlerts(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: state.alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                itemBuilder: (_, index) => AlertCard(item: state.alerts[index]),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
