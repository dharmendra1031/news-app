import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/cubits/update_user_cubit.dart';
import 'package:news/features/author/cubits/author_cubit.dart';
import 'package:news/features/language/cubits/language_cubit.dart';
import 'package:news/features/authentication/repositories/auth_local_data_source.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';

import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/utils/validators.dart';

class UserProfileScreen extends StatefulWidget {
  final String from;
  const UserProfileScreen({super.key, required this.from});

  @override
  State createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return CupertinoPageRoute(
        builder: (_) => UserProfileScreen(from: arguments['from'] as String));
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthLocalDataSource authLocalDataSource = AuthLocalDataSource();
  dynamic size;
  FocusNode nameFocus = FocusNode();
  FocusNode mobNoFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode crntFocus = FocusNode();
  FocusNode authorBioFocus = FocusNode();
  FocusNode telegramLinkFocus = FocusNode();
  FocusNode facebookLinkFocus = FocusNode();
  FocusNode linkedInLinkFocus = FocusNode();
  FocusNode whatsappLinkFocus = FocusNode();

  TextEditingController? nameC = TextEditingController(),
      monoC = TextEditingController(),
      emailC = TextEditingController();
  TextEditingController? authorBioC = TextEditingController();
  TextEditingController? telegramLinkC = TextEditingController();
  TextEditingController? facebookLinkC = TextEditingController();
  TextEditingController? whatsappLinkC = TextEditingController();
  TextEditingController? linkedInLinkC = TextEditingController();
  String? profile, mobile;
  bool isEditMono = false,
      isEditEmail = false,
      isSaving = false,
      isThisUserAnAuthor = false;
  String? updateValue;
  File? image;

  @override
  void initState() {
    isThisUserAnAuthor = context.read<AuthCubit>().isAuthor();
    setControllers();
    if (widget.from == "login") getLanguageList();

    super.initState();
  }

  setControllers() {
    nameC = TextEditingController(text: authLocalDataSource.getName());
    emailC = TextEditingController(text: authLocalDataSource.getEmail());
    monoC = TextEditingController(text: authLocalDataSource.getMobile());
    profile = context.read<AuthCubit>().getProfile();
    // if (isThisUserAnAuthor) {
    authorBioC = TextEditingController(
        text: (authLocalDataSource.getAuthorBio().isEmpty)
            ? context.read<AuthCubit>().getAuthorBio()
            : authLocalDataSource.getAuthorBio());
    whatsappLinkC = TextEditingController(
        text: (authLocalDataSource.getAuthorWhatsappLink()!.isEmpty)
            ? context.read<AuthCubit>().getAuthorWhatsappLink()
            : authLocalDataSource.getAuthorWhatsappLink());
    telegramLinkC = TextEditingController(
        text: (authLocalDataSource.getAuthorTelegramLink()!.isEmpty)
            ? context.read<AuthCubit>().getAuthorTelegramLink()
            : authLocalDataSource.getAuthorTelegramLink());
    linkedInLinkC = TextEditingController(
        text: (authLocalDataSource.getAuthorLinkedInLink()!.isEmpty)
            ? context.read<AuthCubit>().getAuthorLinkedInLink()
            : authLocalDataSource.getAuthorLinkedInLink());
    facebookLinkC = TextEditingController(
        text: (authLocalDataSource.getAuthorFacebookLink()!.isEmpty)
            ? context.read<AuthCubit>().getAuthorFacebookLink()
            : authLocalDataSource.getAuthorFacebookLink());
    //  }
  }

  getLanguageList() {
    Future.delayed(Duration.zero, () {
      context.read<LanguageCubit>().getLanguage();
    });
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: CustomAppBar(
            height: 45,
            isBackBtn: (widget.from == "login") ? false : true,
            label: 'editProfile',
            isConvertText: true),
        body: buildProfileFields());
  }

  onBackPress(bool isTrue) {
    (widget.from == "login")
        ? Navigator.of(context).popUntil((route) => route.isFirst)
        : Navigator.pop(context);
  }

  buildProfileFields() {
    return PopScope(
      canPop: (widget.from != "login") ? true : false,
      onPopInvoked: (bool isTrue) => onBackPress,
      child: BlocConsumer<UpdateUserCubit, UpdateUserState>(
        listener: (context, state) {
          //show snackbar incase of success & failure both
          if (state is UpdateUserFetchSuccess && state.updatedUser != null) {
            showSnackBar(
                UiUtils.getTranslatedLabel(context, 'profileUpdateMsg'),
                context);
            //  var authStatus = state.updatedUser?.authorDetails?.status;
            //update local auth status here
            //  context.read<AuthCubit>().authRepository.setLocalAuthDetails(authorStatus: AuthorStatus.approved);
            isSaving = false;
            setState(() {});
            if (widget.from == "becomeAuthor") {
              //call author request API here
              context.read<AuthorCubit>().requestToBecomeAuthor();
              // setPendingStatusControllerValues();
            }
            if (widget.from == "login") {
              if (context.read<LanguageCubit>().langList().length > 1) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.languageList, (route) => false,
                    arguments: {"from": "firstLogin"});
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.managePref, (route) => false,
                    arguments: {"from": 2});
              }
            } else {
              Navigator.pop(context);
            }
          }
          if (state is UpdateUserFetchFailure) {
            isSaving = false;
            showSnackBar(
                (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                    ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                    : state.errorMessage,
                context);
            // showSnackBar(state.errorMessage, context);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 10.0),
              child: Form(
                  key: _formKey,
                  child: Column(children: [
                    profileWidget(),
                    setTextField(
                        validatorMethod: (value) =>
                            Validators.nameValidation(value!, context),
                        focusNode: nameFocus,
                        nextFocus:
                            (context.read<AuthCubit>().getType() != loginMbl)
                                ? mobNoFocus
                                : emailFocus,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        controller: nameC,
                        hintlbl:
                            UiUtils.getTranslatedLabel(context, 'nameLbl')),
                    const SizedBox(height: 16),
                    setMobileNumber(),
                    const SizedBox(height: 16),
                    setTextField(
                        validatorMethod: (value) => value!.trim().isEmpty
                            ? null
                            : Validators.emailValidation(value, context),
                        focusNode: emailFocus,
                        nextFocus: isThisUserAnAuthor ? authorBioFocus : null,
                        textInputAction: isThisUserAnAuthor
                            ? TextInputAction.next
                            : TextInputAction.done,
                        keyboardType: TextInputType.emailAddress,
                        controller: emailC,
                        isenable:
                            (context.read<AuthCubit>().getType() == loginMbl)
                                ? true
                                : false,
                        hintlbl:
                            UiUtils.getTranslatedLabel(context, 'emailLbl')),
                    if (widget.from == "becomeAuthor" ||
                        isThisUserAnAuthor) ...[
                      const SizedBox(height: 24),
                      showAuthorFields(),
                    ],
                    const SizedBox(height: 23),
                    submitBtn(context)
                  ])));
        },
      ),
    );
  }

  Widget showAuthorFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        setAuthorBio(),
        const SizedBox(height: 15),
        Container(
            alignment: AlignmentGeometry.centerLeft,
            padding: EdgeInsetsDirectional.only(start: 20),
            child: CustomTextLabel(
                text: 'socialMediaLinksLbl',
                textStyle: Theme.of(this.context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                        color: UiUtils.getColorScheme(context).primaryContainer,
                        fontWeight: FontWeight.w700))),
        const SizedBox(height: 15),
        setSocialMediaLink(
            linkController: telegramLinkC,
            currFocus: telegramLinkFocus,
            nextFocus: whatsappLinkFocus,
            typeForHintText: 'Telegram'),
        const SizedBox(height: 15),
        setSocialMediaLink(
            linkController: whatsappLinkC,
            currFocus: whatsappLinkFocus,
            nextFocus: facebookLinkFocus,
            typeForHintText: 'Whatsapp'),
        const SizedBox(height: 15),
        setSocialMediaLink(
            linkController: facebookLinkC,
            currFocus: facebookLinkFocus,
            nextFocus: linkedInLinkFocus,
            typeForHintText: 'Facebook'),
        const SizedBox(height: 15),
        setSocialMediaLink(
            linkController: linkedInLinkC,
            currFocus: linkedInLinkFocus,
            nextFocus: null,
            typeForHintText: 'LinkedIn'),
      ],
    );
  }

  Widget setAuthorBio() {
    return Container(
        width: double.maxFinite,
        child: setTextField(
            hintlbl: UiUtils.getTranslatedLabel(context, 'addYourBioHintLbl'),
            // shouldExpand: true,
            controller: authorBioC,
            focusNode: authorBioFocus,
            // isenable: isThisUserAnAuthor,
            nextFocus: telegramLinkFocus,
            textInputAction: TextInputAction.newline,
            maxLines: 2));
  }

  Widget setSocialMediaLink(
      {required TextEditingController? linkController,
      required FocusNode currFocus,
      required FocusNode? nextFocus,
      required String typeForHintText}) {
    return setTextField(
        hintlbl: getAddLinkHint(context, typeForHintText),
        controller: linkController,
        focusNode: currFocus,
        // isenable: isThisUserAnAuthor,
        nextFocus: nextFocus,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.url);
  }

  String getAddLinkHint(BuildContext context, String type) {
    final template = UiUtils.getTranslatedLabel(context, 'addLinkHereHintLbl');
    return template.replaceAll("{type}", type);
  }

  Widget setMobileNumber() {
    return setTextField(
        validatorMethod: (value) => value!.trim().isEmpty
            ? null
            : Validators.mobValidation(value, context),
        keyboardType: TextInputType.phone,
        hintlbl: UiUtils.getTranslatedLabel(context, 'mobileLbl'),
        textInputAction: TextInputAction.next,
        controller: monoC,
        focusNode: mobNoFocus,
        nextFocus: isThisUserAnAuthor ? authorBioFocus : emailFocus,
        isenable:
            (context.read<AuthCubit>().getType() != loginMbl) ? true : false);
  }

  //set image camera
  getFromCamera() async {
    try {
      XFile? pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          maxHeight: 1800,
          maxWidth: 1800);
      if (pickedFile != null) {
        Navigator.of(context).pop(); //pop dialog
        setState(() {
          image = File(pickedFile.path);
          profile = image!.absolute.path;
        });
        debugPrint("camera-success-absolute path: ${image?.absolute.path}");
      }
    } catch (e) {
      debugPrint("camera-error-${e.toString()}");
    }
  }

// set image gallery
  _getFromGallery() async {
    XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1800, maxHeight: 1800);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
        profile = image!.absolute.path;
        Navigator.of(context).pop(); //pop dialog
      });
      debugPrint("gallery-success-absolute path: ${image?.absolute.path}");
    }
  }

  profileWidget() {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Center(child: profileImgWidget()));
  }

  Widget profilePictureWidget() {
    const double imageSize = 85;
    final fallbackIcon = Container(
        width: imageSize,
        height: imageSize,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: UiUtils.getColorScheme(context).primaryContainer)),
        child: Icon(Icons.person,
            color: UiUtils.getColorScheme(context).primaryContainer));

    if (image != null) {
      return Image.file(image!,
          fit: BoxFit.cover, width: imageSize, height: imageSize);
    }

    if (profile == null || profile!.trim().isEmpty) {
      return fallbackIcon;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CustomNetworkImage(
          networkImageUrl: profile!,
          fit: BoxFit.cover,
          width: imageSize,
          height: imageSize,
          errorBuilder: fallbackIcon),
    );
  }

  profileImgWidget() {
    return GestureDetector(
        onTap: () => UiUtils().showUploadImageBottomsheet(
            context: context,
            onCamera: getFromCamera,
            onGallery: _getFromGallery),
        child: SizedBox(
          width: 85,
          height: 85,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              profilePictureWidget(),
              Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color:
                              UiUtils.getColorScheme(context).primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color:
                                  UiUtils.getColorScheme(context).secondary)),
                      child: Icon(Icons.camera_alt_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20)))
            ],
          ),
        ));
  }

  submitBtn(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                (Platform.isIOS ? 100 : 0)),
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0))),
            child: Container(
              height: 45.0,
              width: MediaQuery.of(context).size.width * 0.8,
              alignment: Alignment.center,
              child: (isSaving)
                  ? UiUtils.showCircularProgress(
                      true, UiUtils.getColorScheme(context).primaryContainer)
                  : CustomTextLabel(
                      text: 'saveLbl',
                      textStyle: Theme.of(this.context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              color: secondaryColor,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.6)),
            ),
            onPressed: () async {
              validateData();
            }));
  }

  validateData() async {
    if (_formKey.currentState!.validate()) {
      profileupdateprocess();
    } else {
      //debugPrint("validation failed");
    }
  }

  profileupdateprocess() async {
    isSaving = true;
    //in case of Clearing Existing mobile number -> set mobile to blank, so it can be passed to replace existing value of mobile number as NULL mobile number won't be passed to APi
    mobile = monoC!.text.trim();

    if (mobile == null &&
        context.read<AuthCubit>().getType() != loginMbl &&
        context.read<AuthCubit>().getMobile().isNotEmpty) {
      mobile = " ";
    }
    try {
      debugPrint("profileupdateprocess ${image?.absolute.path}");
      final includeAuthorLinks =
          widget.from == "becomeAuthor" || isThisUserAnAuthor;
      String? authorLink(TextEditingController? controller) =>
          includeAuthorLinks ? controller?.text : null;
      context.read<UpdateUserCubit>().setUpdateUser(
          context: context,
          name: nameC!.text,
          email: emailC!.text,
          mobile: mobile,
          filePath: (image != null) ? image!.absolute.path : "",
          authorBio: authorBioC?.text,
          whatsappLink: authorLink(whatsappLinkC),
          facebookLink: authorLink(facebookLinkC),
          telegramLink: authorLink(telegramLinkC),
          linkedInLink: authorLink(linkedInLinkC));
    } catch (e) {
      showSnackBar(e.toString(), context);
    }
  }

  setTextField({
    String? Function(String?)? validatorMethod,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    TextEditingController? controller,
    String? hintlbl,
    bool isenable = true,
    int? maxLines,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextFormField(
            // expands: shouldExpand,
            enabled: isenable,
            decoration: InputDecoration(
              hintText: hintlbl,
              hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      UiUtils.getColorScheme(context).outline.withOpacity(0.2)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: UiUtils.getColorScheme(context)
                          .outline
                          .withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(5.0)),
              enabledBorder: OutlineInputBorder(
                  borderSide: isDark
                      ? const BorderSide(color: darkBorderDefaultColor)
                      : BorderSide.none,
                  borderRadius: BorderRadius.circular(5.0)),
              disabledBorder: OutlineInputBorder(
                  borderSide: isDark
                      ? const BorderSide(color: darkBorderDefaultColor)
                      : BorderSide.none,
                  borderRadius: BorderRadius.circular(5.0)),
            ),
            validator: validatorMethod,
            inputFormatters: [
              (focusNode == mobNoFocus)
                  ? FilteringTextInputFormatter.digitsOnly
                  : FilteringTextInputFormatter.singleLineFormatter
            ],
            focusNode: focusNode,
            textInputAction: textInputAction,
            onEditingComplete: () {
              crntFocus = FocusNode();
              (nextFocus != null)
                  ? fieldFocusChange(context, focusNode!, nextFocus)
                  : focusNode?.unfocus();
            },
            onChanged: (String value) {
              setState(() => crntFocus = focusNode!);
            },
            onTapOutside: (val) => FocusScope.of(context).unfocus(),
            maxLines: (maxLines ?? 1),
            textAlignVertical: TextAlignVertical.center,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: (isenable)
                    ? UiUtils.getColorScheme(context).primaryContainer
                    : borderColor),
            keyboardType: keyboardType,
            controller: controller));
  }

  fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }
}
