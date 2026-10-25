import 'package:flutter/material.dart';
import 'package:news/utils/ui_utils.dart';

class CustomBackButton extends StatelessWidget {
  final Function? onTap;
  final double? horizontalPadding;

  const CustomBackButton({super.key, this.onTap, this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 0),
        child: InkWell(
            onTap: () => onTap ?? Navigator.of(context).pop(),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Icon(Icons.arrow_back, color: UiUtils.getColorScheme(context).primaryContainer)));
  }
}
