import 'package:flutter/material.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/authentication/widgets/field_focus_change.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/utils/validators.dart';

class SetName extends StatelessWidget {
  final FocusNode currFocus;
  final FocusNode nextFocus;
  final TextEditingController nameC;
  late String name;

  SetName(
      {super.key,
      required this.currFocus,
      required this.nextFocus,
      required this.nameC,
      required this.name});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: TextFormField(
        focusNode: currFocus,
        textInputAction: TextInputAction.next,
        controller: nameC,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: UiUtils.getColorScheme(context).primaryContainer,
            ),
        validator: (val) => Validators.nameValidation(val!, context),
        onFieldSubmitted: (v) {
          fieldFocusChange(context, currFocus, nextFocus);
        },
        decoration: InputDecoration(
          hintText: UiUtils.getTranslatedLabel(context, 'nameLbl'),
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: UiUtils.getColorScheme(context)
                    .primaryContainer
                    .withOpacity(0.5),
              ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    UiUtils.getColorScheme(context).outline.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(4.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: isDark
                ? const BorderSide(color: darkBorderDefaultColor)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }
}
