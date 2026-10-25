import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/utils/ui_utils.dart';

class ErrorContainerWidget extends StatelessWidget {
  final String errorMsg;
  final Function onRetry;
  const ErrorContainerWidget(
      {super.key, required this.errorMsg, required this.onRetry});

  String _illustrationAssetName(BuildContext context) {
    if (errorMsg.contains(UiUtils.getTranslatedLabel(context, 'internetmsg'))) {
      return 'NoInternet';
    }
    if (errorMsg.contains(ErrorMessageKeys.noDataMessage)) {
      return 'NoDataFound';
    }
    return 'SomethingWentWrong';
  }

  Widget _illustration(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final w = mq.size.width;
    return Container(
      width: w * 0.7,
      margin: EdgeInsets.only(top: mq.padding.top + h * 0.05),
      height: h * 0.4,
      alignment: Alignment.center,
      child: SvgPictureWidget(assetName: _illustrationAssetName(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _illustration(context),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: CustomTextLabel(
                      text: errorMsg,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          fontSize: 16,
                          fontWeight: FontWeight.w300))),
              SizedBox(height: MediaQuery.of(context).size.height * (0.035)),
              CustomTextButton(
                  onTap: () {
                    onRetry.call();
                  },
                  buttonStyle: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          UiUtils.getColorScheme(context).primaryContainer),
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return UiUtils.getColorScheme(context)
                              .surface
                              .withOpacity(0.2);
                        }
                        return null;
                      }),
                      animationDuration: const Duration(milliseconds: 150),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)))),
                  textWidget: CustomTextLabel(
                    text: 'RetryLbl',
                    textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: UiUtils.getColorScheme(context).surface,
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                        letterSpacing: 0.6),
                  )),
              SizedBox(height: MediaQuery.of(context).size.height * (0.15)),
            ],
          ),
        ));
  }
}
