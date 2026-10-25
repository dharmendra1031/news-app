import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';

Widget titleView({required String title, required BuildContext context}) {
  // FIGMA(3768-8884): News/title/large — Roboto ExtraBold 22 / 28. Roboto ships
  // up to w700 in this app, so w700 is the closest available weight.
  return Padding(
      padding: const EdgeInsetsDirectional.only(top: 10.0),
      child: CustomTextLabel(
          text: title,
          textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: UiUtils.getColorScheme(context).primaryContainer,
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w800)));
}
