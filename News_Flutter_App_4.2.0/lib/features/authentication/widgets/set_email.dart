import 'package:flutter/material.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/utils/validators.dart';

import 'field_focus_change.dart';

class SetEmail extends StatelessWidget {
  final FocusNode? currFocus;
  final FocusNode? nextFocus;
  final TextEditingController emailC;
  late String email;
  final double topPad;

  SetEmail(
      {super.key,
      this.currFocus,
      this.nextFocus,
      required this.emailC,
      required this.email,
      required this.topPad});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: TextFormField(
        focusNode: currFocus,
        textInputAction: TextInputAction.next,
        controller: emailC,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: UiUtils.getColorScheme(context).primaryContainer),
        validator: (val) => Validators.emailValidation(val!, context),
        onFieldSubmitted: (v) {
          if (currFocus != null || nextFocus != null)
            fieldFocusChange(context, currFocus!, nextFocus!);
        },
        decoration: InputDecoration(
          hintText: UiUtils.getTranslatedLabel(context, 'enterEmailLbl'),
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: UiUtils.getColorScheme(context)
                  .primaryContainer
                  .withOpacity(0.5)),
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
