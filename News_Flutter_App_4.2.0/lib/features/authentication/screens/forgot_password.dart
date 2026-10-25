import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_back_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/features/authentication/widgets/set_email.dart';
import 'package:news/features/authentication/widgets/set_login_and_signup_btn.dart';
import 'package:news/utils/ui_utils.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  FrgtPswdState createState() => FrgtPswdState();
}

class FrgtPswdState extends State<ForgotPassword> {
  TextEditingController emailC = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int durationInMiliSeconds = 2500;

  @override
  void dispose() {
    emailC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: screenContent());
  }

  Widget backBtn() {
    return const Padding(
        padding: EdgeInsets.only(top: 20.0), child: CustomBackButton());
  }

  Widget forgotPassLbl() {
    return CustomTextLabel(
      text: 'forgotPassLbl',
      maxLines: 3,
      textAlign: TextAlign.left,
      // FIGMA(184-5946): title/large - Roboto Medium 22/28, weight 500, tracking 0
      textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 22,
          height: 28 / 22,
          letterSpacing: 0,
          color: UiUtils.getColorScheme(context).primaryContainer),
    );
  }

  Widget forgotPassHead() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 16.0),
        child: CustomTextLabel(
          text: 'frgtPassHead',
          maxLines: 3,
          textAlign: TextAlign.left,
          // FIGMA(184-5948): body/large - Roboto Regular 16/24, tracking 0.5
          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 24 / 16,
              letterSpacing: 0.5,
              color: UiUtils.getColorScheme(context).primaryContainer),
        ));
  }

  Widget forgotPassSubHead() {
    return Padding(
        padding: const EdgeInsetsDirectional.only(top: 16.0),
        child: CustomTextLabel(
          text: 'forgotPassSub',
          maxLines: 3,
          textAlign: TextAlign.left,
          // FIGMA(184-5949): body/medium - Roboto Regular 14/20, tracking 0.25
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 14.0,
              height: 20 / 14,
              letterSpacing: 0.25,
              color: UiUtils.getColorScheme(context).primaryContainer),
        ));
  }

  Widget emailTextCtrl() {
    return SetEmail(emailC: emailC, email: emailC.text, topPad: 26);
  }

  Widget submitBtn() {
    return SetLoginAndSignUpBtn(
        onTap: () async {
          FocusScope.of(context).unfocus(); //dismiss keyboard

          if (await InternetConnectivity.isNetworkAvailable()) {
            final form = _formkey.currentState;
            if (form != null && form.validate()) {
              form.save();
              try {
                await _auth.sendPasswordResetEmail(email: emailC.text.trim());
                showSnackBar(
                    UiUtils.getTranslatedLabel(context, 'passReset'), context,
                    durationInMiliSeconds: durationInMiliSeconds);
                Navigator.pop(context);
              } on FirebaseAuthException catch (e) {
                //debugPrint(e.code);
                //debugPrint(e.message);
                if (e.code == "user-not-found") {
                  showSnackBar(
                      UiUtils.getTranslatedLabel(context, 'userNotFound'),
                      context,
                      durationInMiliSeconds: durationInMiliSeconds);
                } else {
                  showSnackBar(e.message!, context,
                      durationInMiliSeconds: durationInMiliSeconds);
                }
              }
            }
          } else {
            showSnackBar(
                UiUtils.getTranslatedLabel(context, 'internetmsg'), context,
                durationInMiliSeconds: durationInMiliSeconds);
          }
        },
        text: 'submitBtn',
        topPad: 30);
  }

  Widget screenContent() {
    return Container(
        // FIGMA(2883-9436): content inset 16 (left 16, width 358)
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16.0, vertical: 20.0),
        child: SingleChildScrollView(
            child: Form(
          key: _formkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              backBtn(),
              const SizedBox(height: 40),
              forgotPassLbl(),
              forgotPassHead(),
              forgotPassSubHead(),
              emailTextCtrl(),
              submitBtn()
            ],
          ),
        )));
  }
}
