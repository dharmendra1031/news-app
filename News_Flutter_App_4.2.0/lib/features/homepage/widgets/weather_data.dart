import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/features/homepage/models/weather_data.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';

/// Home-page weather card: current temperature on the start side, location
/// and today's high/low on the end side, inside a bordered rounded box.
class WeatherDataView extends StatefulWidget {
  final WeatherDetails weatherData;

  const WeatherDataView({super.key, required this.weatherData});

  @override
  WeatherDataState createState() => WeatherDataState();
}

class WeatherDataState extends State<WeatherDataView> {
  late Future<void> _future;

  /// Figma "sun1" box — the condition icon keeps its aspect ratio inside it.
  static const double _iconSize = 24.0;

  @override
  void initState() {
    super.initState();
    _future = UiUtils.checkIfValidLocale(
        langCode: Hive.box(settingsBoxKey).get(currentLanguageCodeKey));
  }

  TextStyle? _primaryStyle(BuildContext context,
          {double fontSize = 14.0,
          double height = 20 / 14,
          FontWeight fontWeight = FontWeight.w400}) =>
      TextStyle(
          fontSize: fontSize,
          height: height,
          fontWeight: fontWeight,
          color: UiUtils.getColorScheme(context).primaryContainer);

  TextStyle _secondaryStyle(BuildContext context) => TextStyle(
      fontSize: 12.0,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).brightness == Brightness.dark
          ? textTertiaryColor
          : textSecondaryColor);

  Widget? _conditionIcon() {
    final String? icon = widget.weatherData.icon;
    if (icon == null || icon.isEmpty) return null;
    return SizedBox(
      width: _iconSize,
      height: _iconSize,
      child: CustomNetworkImage(
        networkImageUrl: icon.startsWith('http') ? icon : 'https:$icon',
        width: _iconSize,
        height: _iconSize,
        fit: BoxFit.contain,
        errorBuilder: const SizedBox.shrink(),
      ),
    );
  }

  Widget _temperatureContainer(BuildContext context) {
    final Widget? icon = _conditionIcon();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (icon != null) ...<Widget>[icon, const SizedBox(width: 3.0)],
        Flexible(
          child: CustomTextLabel(
              text: '${widget.weatherData.tempC ?? ''}°C',
              textStyle: _primaryStyle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false),
        ),
      ],
    );
  }

  Widget _locationInfo(BuildContext context) {
    final WeatherDetails weatherData = widget.weatherData;
    final String location = <String?>[
      weatherData.name,
      weatherData.region,
      weatherData.country
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        CustomTextLabel(
            text: location,
            textStyle: _primaryStyle(context,
                fontSize: 12.0, height: 16 / 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false),
        const SizedBox(height: 4.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: CustomTextLabel(
                  text: 'H:${weatherData.maxTempC ?? ''}°C',
                  textStyle: _secondaryStyle(context),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            ),
            const SizedBox(width: 9.0),
            Flexible(
              child: CustomTextLabel(
                  text: 'L:${weatherData.minTempC ?? ''}°C',
                  textStyle: _secondaryStyle(context),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            ),
          ],
        ),
      ],
    );
  }

  Widget weatherDataView() {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: UiUtils.getColorScheme(context).surface,
                border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? darkBorderDefaultColor
                        : borderDefaultColor,
                    width: 1.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(child: _temperatureContainer(context)),
                const SizedBox(width: 16.0),
                Flexible(child: _locationInfo(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return weatherDataView();
  }
}
