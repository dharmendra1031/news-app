import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/constants/app_font_size.dart';
import 'package:news/utils/ui_utils.dart';

/// Guards against the sheet being opened twice by a double tap.
bool _isFontSheetOpen = false;

/// Slider sheet for picking a reader font size.
///
/// The sheet is deliberately dumb: it shows [fontSize] and reports every move
/// of the slider through [onFontSizeChanged]. It never stores anything itself,
/// so the caller decides what the change means:
///
/// Both Profile > Text Size and News Details save it to [FontSizeCubit], so
/// there is a single global, persisted size shared by every screen.
Future<void> changeFontSizeSheet(
  BuildContext context, {
  required int fontSize,
  required ValueChanged<int> onFontSizeChanged,
}) async {
  if (_isFontSheetOpen) return;

  _isFontSheetOpen = true;

  try {
    await showModalBottomSheet<dynamic>(
        context: context,
        elevation: 5.0,
        // FIGMA(1592-6734): sheet is white in light and the #0E1B36 "dark-card"
        // in dark; `secondary` maps to exactly those. Previously no colour was set
        // so it fell back to the theme default, which was too light in dark mode.
        backgroundColor: UiUtils.getColorScheme(context).secondary,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16))),
        builder: (BuildContext context) {
          int fontValue = fontSize;
          return StatefulBuilder(builder: (BuildContext context, setStater) {
            return Container(
                padding: const EdgeInsetsDirectional.only(
                    bottom: 20.0, top: 5.0, start: 20.0, end: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(Icons.text_fields_rounded),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: CustomTextLabel(
                                    text: 'txtSizeLbl',
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color:
                                                UiUtils.getColorScheme(context)
                                                    .primaryContainer),
                                  )),
                              CustomTextLabel(
                                  text: "( $fontValue )",
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer)),
                            ])),
                    SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                            // FIGMA(1592-6734): red slider bar. The inactive
                            // (background) portion was red[100] which washed out
                            // on the dark card, so use a translucent primary red
                            // that reads correctly on both themes.
                            activeTrackColor: Theme.of(context).primaryColor,
                            inactiveTrackColor:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            trackShape: const RoundedRectSliderTrackShape(),
                            trackHeight: 4.0,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8.0),
                            thumbColor: Colors.redAccent,
                            overlayColor: Colors.red.withAlpha(32),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 28.0),
                            tickMarkShape: const RoundSliderTickMarkShape(),
                            activeTickMarkColor: Theme.of(context).primaryColor,
                            inactiveTickMarkColor:
                                Theme.of(context).primaryColor.withOpacity(0.5),
                            valueIndicatorShape:
                                const PaddleSliderValueIndicatorShape(),
                            valueIndicatorColor: Colors.redAccent,
                            valueIndicatorTextStyle:
                                const TextStyle(color: Colors.white)),
                        child: Slider(
                            label: '$fontValue',
                            value: fontValue.toDouble(),
                            activeColor: Theme.of(context).primaryColor,
                            min: AppFontSize.min.toDouble(),
                            max: AppFontSize.max.toDouble(),
                            divisions: AppFontSize.sliderDivisions,
                            onChanged: (value) {
                              setStater(() => fontValue = value.round());
                              onFontSizeChanged(fontValue);
                            }))
                  ],
                ));
          });
        });
  } finally {
    _isFontSheetOpen = false;
  }
}
