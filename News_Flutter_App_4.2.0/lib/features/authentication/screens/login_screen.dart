import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/cubits/register_token_cubit.dart';
import 'package:news/features/authentication/widgets/bottom_com_btn.dart';
import 'package:news/features/authentication/widgets/field_focus_change.dart';
import 'package:news/features/authentication/widgets/set_confim_pass.dart';
import 'package:news/features/authentication/widgets/set_divider.dart';
import 'package:news/features/authentication/widgets/set_email.dart';
import 'package:news/features/authentication/widgets/set_forgot_pass.dart';
import 'package:news/features/authentication/widgets/set_login_and_signup_btn.dart';
import 'package:news/features/authentication/widgets/set_name.dart';
import 'package:news/features/authentication/widgets/set_password.dart';
import 'package:news/features/authentication/widgets/set_term_policy.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/dynamic_pages/cubits/privacy_terms_cubit.dart';
import 'package:news/commons/cubits/setting_cubit.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/authentication/cubits/social_signup_cubit.dart';
import 'package:news/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  final bool? isFromApp;
  const LoginScreen({super.key, this.isFromApp});

  @override
  LoginScreenState createState() => LoginScreenState();

  static Route route(RouteSettings routeSettings) {
    if (routeSettings.arguments == null) {
      return CupertinoPageRoute(builder: (_) => const LoginScreen());
    } else {
      final arguments = routeSettings.arguments as Map<String, dynamic>;
      return CupertinoPageRoute(
          builder: (_) =>
              LoginScreen(isFromApp: arguments['isFromApp'] ?? false));
    }
  }
}

class LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TabController? _tabController;
  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();
  FocusNode nameFocus = FocusNode();
  FocusNode emailSFocus = FocusNode();
  FocusNode passSFocus = FocusNode();
  FocusNode confPassFocus = FocusNode();
  TextEditingController? emailC, passC, sEmailC, sPassC, sNameC, sConfPassC;
  String? name, email, pass, mobile, profile, confPass;
  bool isPolicyAvailable = true;
  bool isObscure = true; //setPassword widget

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    assignAllTextController();
    if (isDemo) {
      //set demo credentials for testing
      emailC!.text = "newstester@gmail.com";
      passC!.text = "123456";
    }

    super.initState();
  }

  assignAllTextController() {
    emailC = TextEditingController();
    passC = TextEditingController();
    sEmailC = TextEditingController();
    sPassC = TextEditingController();
    sNameC = TextEditingController();
    sConfPassC = TextEditingController();
  }

  clearSignUpTextFields() {
    setState(() {
      sNameC!.clear();
      sEmailC!.clear();
      sPassC!.clear();
      sConfPassC!.clear();
    });
  }

  disposeAllTextController() {
    emailC!.dispose();
    passC!.dispose();
    sEmailC!.dispose();
    sPassC!.dispose();
    sNameC!.dispose();
    sConfPassC!.dispose();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    disposeAllTextController();

    super.dispose();
  }

  showContent() {
    return BlocConsumer<SocialSignUpCubit, SocialSignUpState>(
        bloc: context.read<SocialSignUpCubit>(),
        listener: (context, state) async {
          if (!mounted) return;

          if (state is SocialSignUpFailure) {
            if (mounted) {
              showSnackBar(state.errorMessage, context);
            }
          }
          if (state is SocialSignUpSuccess) {
            if (!mounted) return;

            context.read<AuthCubit>().checkAuthStatus();
            if (state.authModel.status == "0") {
              if (mounted) {
                showSnackBar(UiUtils.getTranslatedLabel(context, 'deactiveMsg'),
                    context);
              }
            } else {
              FirebaseMessaging.instance.getToken().then((token) async {
                if (!mounted) return;

                if (token != null) {
                  context
                      .read<RegisterTokenCubit>()
                      .registerToken(fcmId: token, context: context);
                  if (token !=
                      context.read<SettingsCubit>().getSettings().token) {
                    context.read<SettingsCubit>().changeFcmToken(token);
                  }
                  if (state.authModel.isFirstLogin != null &&
                      state.authModel.isFirstLogin!.isNotEmpty &&
                      state.authModel.isFirstLogin == "0" &&
                      state.authModel.type != loginApple) {
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.editUserProfile, (route) => false,
                          arguments: {"from": "login"});
                    }
                  } else if (widget.isFromApp == true) {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, Routes.home, (route) => false);
                    }
                  }
                }
              });
            }
          }
        },
        builder: (context, state) {
          return Form(
              key: _formkey,
              child: Stack(
                children: [
                  Container(
                    // Horizontal padding is applied per-element (and per tab
                    // page) instead of here, so the TabBarView spans full width
                    // and each page keeps its own gutter while swiping.
                    padding: const EdgeInsetsDirectional.only(
                        top: 30.0, bottom: 5.0),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: skipBtn(),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: showTabs(),
                          ),
                          showTabBarView()
                        ]),
                  ),
                  if (state is SocialSignUpProgress)
                    UiUtils.showCircularProgress(
                        true, Theme.of(context).primaryColor),
                ],
              ));
        });
  }

  getGuestToken() {
    FirebaseMessaging.instance.getToken().then((token) async {
      if (!mounted) return;

      if (token != null) {
        context
            .read<RegisterTokenCubit>()
            .registerToken(fcmId: token, context: context);
        if (token != context.read<SettingsCubit>().getSettings().token) {
          context.read<SettingsCubit>().changeFcmToken(token);
        }
      }
    });
  }

  skipBtn() {
    return Align(
        alignment: AlignmentDirectional.topEnd,
        child: CustomTextButton(
          onTap: () {
            getGuestToken();
            Navigator.of(context)
                .pushReplacementNamed(Routes.home, arguments: false);
          },
          text: UiUtils.getTranslatedLabel(context, 'skip'),
          color:
              UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7),
        ));
  }

  showTabs() {
    final colorScheme = UiUtils.getColorScheme(context);
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10.0),
      // FIGMA(184-5855): Button Group - white pill, border secondary 10%, radius 1000
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(1000),
        border:
            Border.all(color: colorScheme.primaryContainer.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(4.0),
      child: TabBar(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        controller: _tabController,
        // FIGMA(184-5857): title/medium - Roboto Medium 16, tracking 0.15
        labelStyle: labelStyle,
        unselectedLabelStyle: labelStyle,
        labelPadding: EdgeInsets.zero,
        labelColor: colorScheme.surface,
        unselectedLabelColor: colorScheme.primaryContainer,
        indicatorSize: TabBarIndicatorSize.tab,
        // FIGMA(184-5856): active segment - filled dark pill
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(1000),
          color: colorScheme.primaryContainer,
        ),
        tabs: [
          Tab(
              height: 44,
              text: UiUtils.getTranslatedLabel(context, 'signInTab')),
          Tab(
              height: 44,
              text: UiUtils.getTranslatedLabel(context, 'signupBtn')),
        ],
      ),
    );
  }

  bool validateAndSave() {
    final form = _formkey.currentState;
    form!.save();

    if (!isPolicyAvailable) {
      showSnackBar(UiUtils.getTranslatedLabel(context, 'addTCFirst'), context);
      return false;
    }

    return form.validate();
  }

  Widget setPassword(
      {required FocusNode currFocus,
      FocusNode? nextFocus,
      required TextEditingController passC,
      required String pass,
      required double topPad,
      required bool isLogin}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: TextFormField(
        focusNode: currFocus,
        textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
        controller: passC,
        obscureText: isObscure,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: UiUtils.getColorScheme(context).primaryContainer,
            ),
        validator: (val) => Validators.passValidation(val!, context),
        onFieldSubmitted: (v) {
          if (!isLogin) {
            fieldFocusChange(context, currFocus, nextFocus!);
          }
        },
        onChanged: (String value) {
          pass = value;
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: UiUtils.getTranslatedLabel(context, 'passLbl'),
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: UiUtils.getColorScheme(context)
                    .primaryContainer
                    .withOpacity(0.5),
              ),
          suffixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 12.0),
              child: IconButton(
                icon: isObscure
                    ? Icon(Icons.visibility_off_rounded,
                        size: 20,
                        color: UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.6))
                    : Icon(Icons.visibility_rounded,
                        size: 20,
                        color: UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.6)),
                splashColor: Colors.transparent,
                onPressed: () {
                  setState(() => isObscure = !isObscure);
                },
              )),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color:
                    UiUtils.getColorScheme(context).outline.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(4.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: isDark
                ? const BorderSide(color: darkBorderDefaultColor)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  showTabBarView() {
    return Expanded(
      child: Container(
          alignment: Alignment.center,
          height: MediaQuery.of(context).size.height * 1.0,
          child: TabBarView(
            controller: _tabController,
            dragStartBehavior: DragStartBehavior.start,
            children: [
              //Login
              SingleChildScrollView(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(children: [
                  loginTxt(),
                  SetEmail(
                      currFocus: emailFocus,
                      nextFocus: passFocus,
                      emailC: emailC!,
                      email: email ?? '',
                      topPad: 30),
                  SetPassword(
                      currFocus: passFocus,
                      passC: passC!,
                      pass: pass ?? '',
                      topPad: 20,
                      isLogin: true),
                  setForgotPass(context),
                  SetLoginAndSignUpBtn(
                      onTap: () async {
                        FocusScope.of(context).unfocus(); //dismiss keyboard
                        if (validateAndSave()) {
                          if (await InternetConnectivity.isNetworkAvailable()) {
                            context.read<SocialSignUpCubit>().socialSignUpUser(
                                email: emailC!.text.trim(),
                                password: passC!.text,
                                authProvider: AuthProviders.email,
                                context: context);
                          } else {
                            showSnackBar(
                                UiUtils.getTranslatedLabel(
                                    context, 'internetmsg'),
                                context);
                          }
                        }
                      },
                      text: 'loginTxt',
                      topPad: 10),
                  SetDividerOR(),
                  bottomBtn(),
                  BlocConsumer<PrivacyTermsCubit, PrivacyTermsState>(
                      listener: (context, state) {
                    if (state is PrivacyTermsFetchSuccess) {
                      setState(() {
                        isPolicyAvailable = true;
                      });
                    }
                    if (state is PrivacyTermsFetchFailure) {
                      setState(() {
                        isPolicyAvailable = false;
                      });
                    }
                  }, builder: (context, state) {
                    return (state is PrivacyTermsFetchSuccess)
                        ? setTermPolicyTxt(context, state)
                        : const SizedBox.shrink();
                  })
                ]),
              )),
              //SignUp
              SingleChildScrollView(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    signUpTxt(),
                    SetName(
                        currFocus: nameFocus,
                        nextFocus: emailSFocus,
                        nameC: sNameC!,
                        name: sNameC!.text),
                    SetEmail(
                        currFocus: emailSFocus,
                        nextFocus: passSFocus,
                        emailC: sEmailC!,
                        email: sEmailC!.text,
                        topPad: 20),
                    setPassword(
                        currFocus: passSFocus,
                        nextFocus: confPassFocus,
                        passC: sPassC!,
                        pass: sPassC!.text,
                        topPad: 20,
                        isLogin: false),
                    SetConfirmPass(
                        currFocus: confPassFocus,
                        confPassC: sConfPassC!,
                        confPass: sConfPassC!.text,
                        pass: sPassC!.text),
                    SetLoginAndSignUpBtn(
                        onTap: () async {
                          FocusScope.of(context).unfocus(); //dismiss keyboard
                          final form = _formkey.currentState;
                          if (form!.validate()) {
                            form.save();
                            if (await InternetConnectivity
                                .isNetworkAvailable()) {
                              registerWithEmailPassword(
                                  sEmailC!.text.trim(), sPassC!.text.trim());
                            } else {
                              showSnackBar(
                                  UiUtils.getTranslatedLabel(
                                      context, 'internetmsg'),
                                  context);
                            }
                          }
                        },
                        text: 'signupBtn',
                        topPad: 25)
                  ],
                ),
              ))
            ],
          )),
    );
  }

  registerWithEmailPassword(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;

      User? user = credential.user;
      user!
          .updateDisplayName(sNameC!.text.trim())
          .then((value) => debugPrint("updated name is - ${user.displayName}"));
      user.reload();

      user.sendEmailVerification().then((value) {
        if (mounted) {
          return showSnackBar(
              '${UiUtils.getTranslatedLabel(context, 'verifSentMail')} $email',
              context);
        }
      });
      if (mounted) {
        clearSignUpTextFields();
        _tabController!.animateTo(0);
        FocusScope.of(context).requestFocus(emailFocus);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'weakPassword') {
        return showSnackBar(
            UiUtils.getTranslatedLabel(context, 'weakPassword'), context);
      }
      if (e.code == 'email-already-in-use') {
        return showSnackBar(
            UiUtils.getTranslatedLabel(context, 'emailAlreadyInUse'), context);
      }
    } catch (e) {
      //debugPrint(e.toString());
    }
  }

  loginTxt() {
    return authHeader(
        title: 'loginDescr', subtitle: 'loginSubDescr', topPad: 24.0);
  }

  signUpTxt() {
    return authHeader(
        title: 'signupDescr', subtitle: 'signupSubDescr', topPad: 24.0);
  }

  // FIGMA(2883-9414 / 2883-9413): title + supporting subtitle, left aligned
  authHeader(
      {required String title,
      required String subtitle,
      required double topPad}) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: topPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIGMA(184-5863): title/large - Roboto SemiBold 22, tracking 0.
            // Full heading on ONE line (as in Figma). The remote language data
            // for some titles (e.g. loginDescr = "Let's Sign \nYou In") contains
            // a stray line break; collapseWhitespace flattens it so the whole
            // heading renders on a single line. There is ample width, so no
            // text is cut. (Proper fix: remove the line break in the CMS.)
            CustomTextLabel(
              text: title,
              textAlign: TextAlign.left,
              maxLines: 1,
              softWrap: false,
              collapseWhitespace: true,
              textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.primaryContainer,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0),
            ),
            const SizedBox(height: 8),
            // FIGMA(2883-9408): body/large - Roboto Regular 16, tracking 0.5
            CustomTextLabel(
              text: subtitle,
              textAlign: TextAlign.left,
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  bottomBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        mainAxisAlignment: (fblogInEnabled)
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.spaceAround,
        children: [
          BottomCommButton(
              btnCaption: 'google',
              onTap: () {
                if (!isPolicyAvailable) {
                  showSnackBar(
                      UiUtils.getTranslatedLabel(context, 'addTCFirst'),
                      context);
                } else {
                  context.read<SocialSignUpCubit>().socialSignUpUser(
                      authProvider: AuthProviders.google, context: context);
                }
              },
              img: 'google_button'),
          if (fblogInEnabled)
            BottomCommButton(
                onTap: () {
                  if (!isPolicyAvailable) {
                    showSnackBar(
                        UiUtils.getTranslatedLabel(context, 'addTCFirst'),
                        context);
                  } else {
                    context.read<SocialSignUpCubit>().socialSignUpUser(
                        authProvider: AuthProviders.facebook, context: context);
                  }
                },
                img: 'facebook_button',
                btnCaption: 'fb'),
          if (Platform.isIOS)
            BottomCommButton(
                onTap: () {
                  if (!isPolicyAvailable) {
                    showSnackBar(
                        UiUtils.getTranslatedLabel(context, 'addTCFirst'),
                        context);
                  } else {
                    context.read<SocialSignUpCubit>().socialSignUpUser(
                        authProvider: AuthProviders.apple, context: context);
                  }
                },
                img: 'apple_logo',
                btnCaption: 'apple',
                btnColor: UiUtils.getColorScheme(context).primaryContainer),
          if (context.read<AppConfigurationCubit>().getMobileLoginMode() !=
                  "" &&
              context.read<AppConfigurationCubit>().getMobileLoginMode() != "0")
            BottomCommButton(
                onTap: () {
                  if (!isPolicyAvailable) {
                    showSnackBar(
                        UiUtils.getTranslatedLabel(context, 'addTCFirst'),
                        context);
                  } else {
                    Navigator.of(context).pushNamed(Routes.requestOtp);
                  }
                },
                img: 'phone_button',
                btnCaption: 'mobileLbl',
                btnColor: UiUtils.getColorScheme(context).primaryContainer)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showContent(),
    );
  }
}
