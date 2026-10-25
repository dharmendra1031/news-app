// Source-type field of the Create / Edit episode form: a read-only selection
// row that opens a bottom sheet listing every EpisodeSourceType.

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/features/add_edit_news/widgets/bottom_sheet_option.dart';
import 'package:news/features/add_edit_news/widgets/selection_widget.dart';
import 'package:news/features/podcast/screens/episode_form_controller.dart';
import 'package:news/utils/ui_utils.dart';

class EpisodeSourceTypeSelector extends StatelessWidget {
  /// Currently selected source, or null while nothing has been picked yet.
  final EpisodeSourceType? value;

  final ValueChanged<EpisodeSourceType> onChanged;

  const EpisodeSourceTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionField(
        topMargin: 0,
        value: (value == null)
            ? ''
            : UiUtils.getTranslatedLabel(context, value!.labelKey),
        placeholder: UiUtils.getTranslatedLabel(context, 'selSourceTypeLbl'),
        onTap: () => _showSourceSheet(context));
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      elevation: 3.0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      builder: (sheetContext) => Container(
        padding: const EdgeInsetsDirectional.only(
            bottom: 15.0, top: 15.0, start: 20.0, end: 20.0),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            color: UiUtils.getColorScheme(sheetContext).surface),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextLabel(
                text: 'selSourceTypeLbl',
                textStyle: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: UiUtils.getColorScheme(sheetContext)
                            .primaryContainer)),
            Padding(
              padding:
                  const EdgeInsetsDirectional.only(top: 10.0, bottom: 15.0),
              child: Column(
                children: EpisodeSourceType.values
                    .map((source) => BottomSheetOption(
                        title: source.labelKey,
                        selected: value == source,
                        onTap: () {
                          onChanged(source);
                          Navigator.pop(sheetContext);
                        }))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
