import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:news/utils/ui_utils.dart';

class SvgPictureWidget extends StatelessWidget {
  String assetName;
  ColorFilter? assetColor;
  double? height, width;
  BoxFit? fit;

  SvgPictureWidget(
      {Key? key,
      required this.assetName,
      this.assetColor,
      this.height,
      this.width,
      this.fit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
        placeholderBuilder: (_) => SizedBox(
            width: width,
            height: height,
            child: Center(child: CircularProgressIndicator())),
        UiUtils.getSvgImagePath(assetName),
        colorFilter: assetColor,
        height: height,
        width: width,
        fit: fit ?? BoxFit.fill);
  }
}
