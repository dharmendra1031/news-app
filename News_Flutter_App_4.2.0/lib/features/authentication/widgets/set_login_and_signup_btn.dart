import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/theme/theme_colors.dart'; 

class SetLoginAndSignUpBtn extends StatelessWidget {
  final Function onTap;
  final String text;
  final double topPad;

  const SetLoginAndSignUpBtn(
      {super.key,
      required this.onTap,
      required this.text,
      required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: InkWell(
          splashColor: Colors.transparent,
          child: Container(
            height: 45.0,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8.0)),
            child: CustomTextLabel(
              text: text,
              // FIGMA: label/large - Roboto Medium 14, tracking 0.1
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1),
            ),
          ),
          onTap: () => onTap()),
    );
  }
}
