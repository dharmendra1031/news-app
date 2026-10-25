import 'dart:io';

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class CustomAlertDialog extends StatelessWidget {
  final BuildContext context;
  final String yesButtonText;
  final String yesButtonTextPostfix;
  final String noButtonText;
  final String imageName;
  final Widget titleWidget;
  final String messageText;
  final Function() onYESButtonPressed;
  final bool isForceAppUpdate;
  const CustomAlertDialog(
      {super.key,
      required this.context,
      required this.yesButtonText,
      required this.yesButtonTextPostfix,
      required this.noButtonText,
      required this.imageName,
      required this.titleWidget,
      required this.messageText,
      required this.onYESButtonPressed,
      required this.isForceAppUpdate});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = UiUtils.getColorScheme(context);
    final bool isDark = colorScheme.brightness == Brightness.dark;
    // Dark-mode colors per Figma (nodes 1592-4383 / 1592-4418): the dialog
    // surface is the Dark-bg token and the filled "Yes" button label is the
    // Dark-card token. Light mode keeps the existing surface color.
    final Color dialogBackground =
        isDark ? darkBackgroundColor : colorScheme.surface;
    final Color yesButtonTextColor =
        isDark ? darkSecondaryColor : colorScheme.surface;
    return AlertDialog(
      contentPadding: const EdgeInsets.all(20),
      backgroundColor: dialogBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPictureWidget(assetName: imageName),
          const SizedBox(height: 15),
          titleWidget,
          const SizedBox(height: 5),
          CustomTextLabel(
              text: messageText,
              textAlign: TextAlign.center,
              textStyle: Theme.of(this.context).textTheme.titleSmall?.copyWith(
                  color: UiUtils.getColorScheme(context).primaryContainer)),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceAround,
      actionsOverflowButtonSpacing: 15,
      actions: <Widget>[
        MaterialButton(
          minWidth: MediaQuery.of(context).size.width / 3.5,
          elevation: 0.0,
          highlightColor: Colors.transparent,
          color: Colors.transparent,
          splashColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                  color: UiUtils.getColorScheme(context).primaryContainer)),
          onPressed: () =>
              (isForceAppUpdate) ? exit(0) : Navigator.of(context).pop(false),
          child: CustomTextLabel(
              text: noButtonText,
              textStyle: Theme.of(this.context).textTheme.titleSmall?.copyWith(
                  color: UiUtils.getColorScheme(context).primaryContainer,
                  fontWeight: FontWeight.w500)),
        ),
        MaterialButton(
            elevation: 0.0,
            color: UiUtils.getColorScheme(context).primaryContainer,
            splashColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onPressed: onYESButtonPressed,
            child: RichText(
              text: TextSpan(
                  text: UiUtils.getTranslatedLabel(context, yesButtonText),
                  style: Theme.of(this.context).textTheme.titleSmall?.copyWith(
                      color: yesButtonTextColor, fontWeight: FontWeight.w500),
                  children: [
                    const TextSpan(text: " , "),
                    TextSpan(
                        text: UiUtils.getTranslatedLabel(
                            context, yesButtonTextPostfix),
                        style: Theme.of(this.context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: yesButtonTextColor,
                                fontWeight: FontWeight.w500))
                  ]),
            )),
      ],
    );
  }
}
