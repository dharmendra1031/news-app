import 'dart:core';
import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_back_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final double? horizontalPad;
  final bool isBackBtn, isConvertText;
  final String label;
  final List<Widget>? actionWidget;

  const CustomAppBar(
      {Key? key,
      required this.height,
      required this.isBackBtn,
      required this.label,
      required this.isConvertText,
      this.horizontalPad,
      this.actionWidget})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
        preferredSize: Size(double.infinity, height),
        child: UiUtils.applyBoxShadow(
          context: context,
          child: AppBar(
            leading: (isBackBtn)
                ? CustomBackButton(horizontalPadding: horizontalPad ?? 15)
                : null,
            actions: actionWidget,
            titleSpacing: 0.0,
            automaticallyImplyLeading: false,
            centerTitle: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Padding(
              padding: EdgeInsetsDirectional.only(start: isBackBtn ? 0 : 20),
              child: !isConvertText
                  ? Text(label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color:
                              UiUtils.getColorScheme(context).primaryContainer,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5))
                  : CustomTextLabel(
                      text: label,
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              color: UiUtils.getColorScheme(context)
                                  .primaryContainer,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                    ),
            ),
          ),
        ));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
