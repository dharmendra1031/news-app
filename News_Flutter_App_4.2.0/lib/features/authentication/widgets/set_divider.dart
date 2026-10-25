import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';

class SetDividerOR extends StatelessWidget {
  const SetDividerOR({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = UiUtils.getColorScheme(context).outline.withOpacity(0.9);
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 30.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: Divider(
                    thickness: 1, indent: 5, endIndent: 5, color: color)),
            CustomTextLabel(
              text: 'orLbl',
              // FIGMA(184-5868): body/large - Roboto Regular 16, tracking 0.5
              textStyle: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: color, letterSpacing: 0.5),
            ),
            Expanded(
                child: Divider(
                    thickness: 1, indent: 5, endIndent: 5, color: color)),
          ],
        ));
  }
}
