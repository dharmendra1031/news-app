import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/alerts/models/alert_item_data.dart';
import 'package:news/utils/ui_utils.dart';

/// A single alert card, shared by the home [AlertsView] row and [AlertsScreen].
/// IPO rows have no trend, so they render without the arrow or trend color.

const Color kAlertUpColor = Color(0xff20B364);
const Color kAlertDownColor = Color(0xffD63031);
// Figma "Border/Black" token inverts per theme mode, like Border/Default.
const Color kAlertAccentColorLight = Color(0xff101010);
const Color kAlertAccentColorDark = Colors.white;
const double kAlertCardRadius = 8.0;
const double kAlertAccentStrokeWidth = 3.0;

class AlertCard extends StatelessWidget {
  final AlertItemData item;

  const AlertCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasTrend = item.hasTrend;
    // A 0.00% row keeps its percent text but drops the arrow and trend color.
    final bool showTrend = hasTrend && !item.isFlat;
    final Color trendColor = !showTrend
        ? colorScheme.primaryContainer
        : (item.isUp ? kAlertUpColor : kAlertDownColor);
    final String valueText = hasTrend ? item.changeText : item.ipoPriceText;
    final String subValueText = hasTrend ? item.priceText : item.alertType;
    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(kAlertCardRadius),
            border: Border.all(
              color: isDark ? darkBorderDefaultColor : borderDefaultColor,
              width: 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(width: kAlertAccentStrokeWidth),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: CustomTextLabel(
                            text: item.name,
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: colorScheme.primaryContainer,
                                    fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (showTrend) ...<Widget>[
                              SvgPictureWidget(
                                  assetName: item.isUp
                                      ? "alert_trend_up"
                                      : "alert_trend_down",
                                  height: 24.0,
                                  width: 24.0),
                              const SizedBox(width: 8.0),
                            ],
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                CustomTextLabel(
                                  text: valueText,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: trendColor,
                                          fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                CustomTextLabel(
                                  text: subValueText,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color:
                                              colorScheme.primaryContainer),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Left accent drawn as a separate curved stroke (transparent fill)
        // instead of Border.all, so it hugs the card's rounded corners.
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isDark
                        ? kAlertAccentColorDark
                        : kAlertAccentColorLight,
                    width: kAlertAccentStrokeWidth,
                  ),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(kAlertCardRadius),
                  bottomLeft: Radius.circular(kAlertCardRadius),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
