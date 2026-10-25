import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart'; 
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';

setForgotPass(BuildContext context) {
  return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Align(
          alignment: Alignment.topRight,
          child: CustomTextButton(
              onTap: () => Navigator.of(context).pushNamed(Routes.forgotPass),
              buttonStyle: ButtonStyle(overlayColor: WidgetStateProperty.all(Colors.transparent), foregroundColor: WidgetStateProperty.all(UiUtils.getColorScheme(context).outline.withOpacity(0.7))),
              // FIGMA(184-5864): body/small - Roboto Regular 12, secondary 50%
              textWidget: CustomTextLabel(
                  text: 'forgotPassLbl',
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UiUtils.getColorScheme(context)
                          .primaryContainer
                          .withOpacity(0.5))))));
}
