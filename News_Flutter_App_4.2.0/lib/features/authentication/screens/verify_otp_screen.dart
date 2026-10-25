import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/cubits/social_signup_cubit.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';

class VerifyOtp extends StatefulWidget {
  String? verifyId, countryCode, mono;

  VerifyOtp({super.key, this.verifyId, this.countryCode, this.mono});

  @override
  VerifyOtpState createState() => VerifyOtpState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => VerifyOtp(
              verifyId: arguments['verifyId'],
              countryCode: arguments['countryCode'],
              mono: arguments['mono'],
            ));
  }
}

class VerifyOtpState extends State<VerifyOtp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? otp;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int secondsRemaining = 60;
  bool enableResend = false;
  Timer? timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? verifId;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining != 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        setState(() {
          enableResend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _resendCode() {
    otp = "";
    _onVerifyCode();
    setState(() {
      secondsRemaining = 60;
      enableResend = false;
    });
  }

  void _onVerifyCode() async {
    verificationCompleted(AuthCredential phoneAuthCredential) {
      _auth
          .signInWithCredential(phoneAuthCredential)
          .then((UserCredential value) {
        if (value.user != null) {
          showSnackBar(UiUtils.getTranslatedLabel(context, 'otpMsg'), context);
        } else {
          showSnackBar(
              UiUtils.getTranslatedLabel(context, 'otpError'), context);
        }
      }).catchError((error) {
        showSnackBar(error.toString(), context);
      });
    }

    verificationFailed(FirebaseAuthException authException) {
      if (authException.code == 'invalidVerificationCode') {
        showSnackBar(
            UiUtils.getTranslatedLabel(context, 'invalidVerificationCode'),
            context);
      } else {
        showSnackBar(authException.message.toString(), context);
      }
    }

    codeSent(String? verificationId, [int? forceResendingToken]) async {
      verifId = verificationId;
      if (mounted) {
        setState(() {
          verifId = verificationId;
        });
      }
    }

    codeAutoRetrievalTimeout(String verificationId) {
      verifId = verificationId;
      setState(() {
        verifId = verificationId;
      });
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'otpTimeoutLbl'), context);
    }

    await _auth.verifyPhoneNumber(
        phoneNumber: "+${widget.countryCode}${widget.mono}",
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: BlocConsumer<SocialSignUpCubit, SocialSignUpState>(
            bloc: context.read<SocialSignUpCubit>(),
            listener: (context, state) async {
              if (state is SocialSignUpFailure) {
                showSnackBar(state.errorMessage, context);
              }
            },
            builder: (context, state) {
              return Stack(
                children: <Widget>[
                  SafeArea(bottom: false, child: showContent()),
                  if (state is SocialSignUpProgress)
                    Center(
                        child: UiUtils.showCircularProgress(
                            true, Theme.of(context).primaryColor))
                ],
              );
            }));
  }

  //show form content
  showContent() {
    return Container(
      padding: const EdgeInsetsDirectional.all(20.0),
      child: SingleChildScrollView(
          child: Form(
              key: _formkey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 50),
                    otpVerifySet(),
                    otpSentSet(),
                    mblSet(),
                    otpFillSet(),
                    buildTimer(),
                    submitBtn(),
                    if (secondsRemaining == 0) showResendOTPButton()
                  ]))),
    );
  }

  otpVerifySet() {
    return CustomTextLabel(
        text: 'otpVerifyLbl',
        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: UiUtils.getColorScheme(context).primaryContainer,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
        textAlign: TextAlign.left);
  }

  otpSentSet() {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0),
      child: CustomTextLabel(
          text: 'otpSentLbl',
          maxLines: 3,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: UiUtils.getColorScheme(context).primaryContainer,
              fontWeight: FontWeight.w500)),
    );
  }

  mblSet() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: CustomTextLabel(
          text: "${widget.countryCode} ${widget.mono}",
          textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: UiUtils.getColorScheme(context)
                  .primaryContainer
                  .withOpacity(0.8))),
    );
  }

  otpFillSet() {
    return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(top: 30.0),
        child: PinFieldAutoFill(
            decoration: BoxLooseDecoration(
                strokeColorBuilder: PinListenColorBuilder(
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface),
                bgColorBuilder: PinListenColorBuilder(
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface),
                gapSpace: 7.0),
            currentCode: otp,
            codeLength: 6,
            keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: true),
            onCodeChanged: (String? code) {
              otp = code;
            },
            onCodeSubmitted: (String code) {
              otp = code;
            }));
  }

  showResendOTPButton() {
    return Container(
        padding: const EdgeInsets.only(top: 20.0),
        alignment: Alignment.center,
        child: Text.rich(
          TextSpan(
            text: "${UiUtils.getTranslatedLabel(context, 'didntGetCode')} ",
            style: TextStyle(
                color: UiUtils.getColorScheme(context)
                    .primaryContainer
                    .withOpacity(0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
            children: [
              TextSpan(
                text: UiUtils.getTranslatedLabel(context, 'resendLbl'),
                style: TextStyle(
                    color: UiUtils.getColorScheme(context).secondaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = enableResend ? _resendCode : null,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ));
  }

  buildTimer() {
    return Container(
      alignment: AlignmentDirectional.bottomStart,
      padding: const EdgeInsets.only(top: 30.0),
      child: secondsRemaining != 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                CustomTextLabel(
                    text: 'resendCodeLbl',
                    textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.8))),
                CustomTextLabel(
                    text: ' 00:${secondsRemaining.toString().padLeft(2, '0')}',
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Theme.of(context).primaryColor)),
              ],
            )
          : SizedBox.shrink(),
    );
  }

  submitBtn() {
    return Container(
        padding: const EdgeInsets.only(top: 45.0),
        child: InkWell(
            child: Container(
              height: 45.0,
              width: MediaQuery.of(context).size.width * 0.9,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(7.0)),
              child: CustomTextLabel(
                  text: 'submitBtn',
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: secondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.6)),
            ),
            onTap: () async {
              if (otp!.trim().isEmpty)
                return showSnackBar(
                    UiUtils.getTranslatedLabel(context, 'enterOtpTxt'),
                    context);
              FocusScope.of(context).unfocus(); //dismiss keyboard

              if (validateAndSave()) {
                if (await InternetConnectivity.isNetworkAvailable()) {
                  context.read<SocialSignUpCubit>().socialSignUpUser(
                      authProvider: AuthProviders.mobile,
                      verifiedId: widget.verifyId,
                      otp: otp,
                      context: context);
                } else {
                  showSnackBar(
                      UiUtils.getTranslatedLabel(context, 'internetmsg'),
                      context);
                }
              }
            }));
  }

  //check validation of form data
  bool validateAndSave() {
    final form = _formkey.currentState;
    form!.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }
}
