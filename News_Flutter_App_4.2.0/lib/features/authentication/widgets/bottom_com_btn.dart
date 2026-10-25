import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class BottomCommButton extends StatelessWidget {
  final Function onTap;
  final String img;
  final Color? btnColor;
  final String btnCaption;

  const BottomCommButton(
      {super.key,
      required this.onTap,
      required this.img,
      this.btnColor,
      required this.btnCaption});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    String textLbl =
        "${UiUtils.getTranslatedLabel(context, 'continueWith')} ${UiUtils.getTranslatedLabel(context, btnCaption)}";
    return InkWell(
        splashColor: Colors.transparent,
        child: Container(
            height: 45.0,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: UiUtils.getColorScheme(context).surface,
                borderRadius: BorderRadius.circular(8.0),
                border: isDark
                    ? Border.all(color: darkBorderDefaultColor)
                    : null),
            padding: const EdgeInsets.all(9.0),
            margin: EdgeInsets.symmetric(vertical: 10),
            //decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), color: secondaryColor),
            child: Wrap(
              // crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 15,
              children: [
                SvgPictureWidget(
                    assetName: img,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    assetColor: btnColor != null
                        ? ColorFilter.mode(btnColor!, BlendMode.srcIn)
                        : null),
                CustomTextLabel(
                    text: textLbl,
                    // FIGMA: label/large - Roboto Medium 14, tracking 0.1
                    textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1))
              ],
            )),
        onTap: () => onTap());
  }
}
