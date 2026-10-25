import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/dynamic_pages/cubits/privacy_terms_cubit.dart';
import 'package:news/utils/ui_utils.dart';

setTermPolicyTxt(BuildContext context, PrivacyTermsFetchSuccess state) {
  return Container(
      alignment: AlignmentDirectional.bottomCenter,
      padding: const EdgeInsets.only(top: 20.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          TextSpan(
            text:
                "${UiUtils.getTranslatedLabel(context, 'agreeTermPolicyLbl')}\n",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: UiUtils.getColorScheme(context)
                    .primaryContainer
                    .withOpacity(0.7),
                overflow: TextOverflow.ellipsis),
          ),
          TextSpan(
            text: UiUtils.getTranslatedLabel(context, 'termLbl'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
                overflow: TextOverflow.ellipsis),
            recognizer: TapGestureRecognizer()
              ..onTap = (() {
                Navigator.of(context).pushNamed(Routes.privacy, arguments: {
                  "from": "login",
                  "title": state.termsPolicy.title,
                  "desc": state.termsPolicy.pageContent
                });
              }),
          ),
          TextSpan(
            text: "\t${UiUtils.getTranslatedLabel(context, 'andLbl')}\t",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: UiUtils.getColorScheme(context)
                    .primaryContainer
                    .withOpacity(0.7),
                overflow: TextOverflow.ellipsis),
          ),
          TextSpan(
            text: UiUtils.getTranslatedLabel(context, 'priPolicy'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
                overflow: TextOverflow.ellipsis),
            recognizer: TapGestureRecognizer()
              ..onTap = (() {
                Navigator.of(context).pushNamed(Routes.privacy, arguments: {
                  "from": "login",
                  "title": state.privacyPolicy.title,
                  "desc": state.privacyPolicy.pageContent
                });
              }),
          ),
        ]),
      ));
}
