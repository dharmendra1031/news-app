import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/alerts/models/alert_item_data.dart';
import 'package:news/features/alerts/widgets/alert_card.dart';
import 'package:news/utils/ui_utils.dart';

/// Home-page "Alerts" section below the Weather Forecast: a header with
/// "View More" and a row of [AlertCard]s — the caller decides how many to pass.
class AlertsView extends StatelessWidget {
  final List<AlertItemData> alerts;
  final VoidCallback? onViewMore;

  const AlertsView({super.key, required this.alerts, this.onViewMore});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final colorScheme = UiUtils.getColorScheme(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: CustomTextLabel(
                  text: 'alerts',
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primaryContainer,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
              GestureDetector(
                onTap: onViewMore,
                child: const CustomTextLabel(
                  text: 'viewMore',
                  textStyle: TextStyle(
                    fontSize: 14.0,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < alerts.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 16.0),
                Expanded(child: AlertCard(item: alerts[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
