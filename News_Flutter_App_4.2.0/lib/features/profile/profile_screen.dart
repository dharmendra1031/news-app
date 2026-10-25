import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:news/core/app.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/cubits/delete_user_cubit.dart';
import 'package:news/features/author/cubits/author_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/language/cubits/language_json_cubit.dart';
import 'package:news/features/dynamic_pages/cubits/other_pages_cubit.dart';
import 'package:news/commons/enums.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/features/authentication/repositories/auth_local_data_source.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/features/dashboard/widgets/app_bottom_nav_bar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/cubits/font_size_cubit.dart';
import 'package:news/commons/widgets/font_size_bottom_sheet.dart';
import 'package:news/features/profile/widgets/custom_alert_dialog.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/commons/cubits/theme_cubit.dart';
import 'package:news/core/theme/app_theme.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const ProfileScreen());
  }
}

class ProfileScreenState extends State<ProfileScreen> {
  File? image;
  String? name, mobile, email, profile;
  TextEditingController? nameC, monoC, emailC = TextEditingController();
  AuthLocalDataSource authLocalDataSource = AuthLocalDataSource();
  bool isEditMono = false, isEditEmail = false, isAuthor = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InAppReview _inAppReview = InAppReview.instance;
  late AuthorStatus authorStatus;

  @override
  void initState() {
    getOtherPagesData();
    super.initState();
  }

  getOtherPagesData() {
    Future.delayed(Duration.zero, () {
      context.read<OtherPageCubit>().getOtherPage(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          defaultLangCode:
              context.read<AppConfigurationCubit>().getDefaultLanguageCode());
    });
  }

  Widget pagesBuild() {
    return BlocBuilder<OtherPageCubit, OtherPageState>(
        builder: (context, state) {
      if (state is OtherPageFetchSuccess) {
        return ScrollConfiguration(
          behavior: GlobalScrollBehavior(),
          child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.otherPage.length,
              itemBuilder: ((context, index) => setDrawerItem(
                  state.otherPage[index].title!,
                  Icons.info_rounded,
                  false,
                  true,
                  false,
                  8,
                  image: state.otherPage[index].image!,
                  desc: state.otherPage[index].pageContent))),
        );
      } else {
        //state is OtherPageFetchInProgress || state is OtherPageInitial || state is OtherPageFetchFailure
        return const SizedBox.shrink();
      }
    });
  }

  switchTheme(bool value) async {
    if (value) {
      context.read<ThemeCubit>().changeTheme(AppTheme.Dark);
    } else {
      context.read<ThemeCubit>().changeTheme(AppTheme.Light);
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // In dark mode surface and canvas are the same colour, so the cards need an
  // outline to stay distinguishable from the page.
  BoxBorder? get _cardBorder =>
      _isDark ? Border.all(color: darkBorderDefaultColor) : null;

  Color get _dividerColor =>
      _isDark ? darkBorderDefaultColor : Theme.of(context).canvasColor;

  bool getTheme() {
    return (context.read<ThemeCubit>().state.appTheme == AppTheme.Dark)
        ? true
        : false;
  }

  //set drawer item list
  Widget setDrawerItem(String title, IconData? icon, bool isTrailing,
      bool isNavigate, bool isSwitch, int id,
      {String? image, String? desc, bool isDeleteAcc = false}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
          height: isDeleteAcc ? 36 : 30,
          width: isDeleteAcc ? 36 : 30,
          padding: EdgeInsets.all(isDeleteAcc ? 7 : 3),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(isDeleteAcc ? 8 : 7),
              color: isDeleteAcc
                  ? primaryColor.withOpacity(0.1)
                  : (_isDark
                      ? darkIconSecondaryColor.withOpacity(0.12)
                      : borderColor.withOpacity(0.2))),
          child: (image != null && image != "")
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(isDeleteAcc ? 8 : 7),
                  child: CustomNetworkImage(
                    networkImageUrl: image,
                    width: isDeleteAcc ? 22 : 20,
                    height: isDeleteAcc ? 22 : 20,
                    fit: BoxFit.contain,
                    color: (image.contains("png"))
                        ? UiUtils.getColorScheme(context).primaryContainer
                        : null,
                    errorBuilder: Icon(icon, size: isDeleteAcc ? 22 : 20),
                  ),
                )
              : Icon(icon,
                  size: isDeleteAcc ? 22 : 20,
                  color: isDeleteAcc ? primaryColor : null)),
      iconColor: (isDeleteAcc)
          ? primaryColor
          : UiUtils.getColorScheme(context).primaryContainer,
      trailing: (isTrailing)
          ? SizedBox(
              height: 45,
              width: 55,
              child: FittedBox(
                  fit: BoxFit.fill,
                  child: Theme(
                      data: Theme.of(context).copyWith(useMaterial3: true),
                      child: Switch(
                          // Dark mode (id 0) is the only remaining toggle in
                          // this list; notifications moved to their own screen.
                          onChanged: switchTheme,
                          value: getTheme(),
                          thumbColor: WidgetStatePropertyAll(Colors.white),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).primaryColor;
                            }
                            return borderColor.withOpacity(0.3);
                          }),
                          trackOutlineColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.transparent;
                            }
                            return borderColor.withOpacity(0.5);
                          })))))
          : const SizedBox.shrink(),
      title: CustomTextLabel(
          text: title,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: (isDeleteAcc)
                  ? primaryColor
                  : UiUtils.getColorScheme(context).primaryContainer)),
      onTap: () {
        if (isNavigate) {
          switch (id) {
            case 1:
              Navigator.of(context)
                  .pushNamed(Routes.notificationPreferences);
              break;
            case 2:
              Navigator.of(context).pushNamed(Routes.languageList,
                  arguments: {"from": "profile"});
              break;
            case 3:
              Navigator.of(context).pushNamed(Routes.bookmark);
              break;
            case 6:
              Navigator.of(context).pushNamed(Routes.manageUserNews);
              break;
            case 15:
              // The author's own channels (MyPodcastsScreen), not the public
              // dashboard — that one stays behind home's "View More".
              Navigator.of(context).pushNamed(Routes.myPodcasts);
              break;
            case 7:
              Navigator.of(context)
                  .pushNamed(Routes.managePref, arguments: {"from": 1});
              break;
            case 8:
              Navigator.of(context).pushNamed(Routes.privacy,
                  arguments: {"from": "setting", "title": title, "desc": desc});
              break;
            case 11:
              Navigator.of(context).pushNamed(Routes.eNews);
              break;

            case 9:
              _openStoreListing();
              break;
            case 10:
              UiUtils.shareApp(context: context);
              break;
            case 12:
              deleteAccount();
              break;
            case 13:
              Navigator.of(context).pushNamed(Routes.editUserProfile,
                  arguments: {'from': 'profile'});
              break;
            case 14:
              // Profile is the only place that writes the global setting.
              changeFontSizeSheet(
                context,
                fontSize: context.read<FontSizeCubit>().fontSize,
                onFontSizeChanged: (value) =>
                    context.read<FontSizeCubit>().changeFontSize(value),
              );
              break;
            default:
              break;
          }
        }
      },
    );
  }

  logOutDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return CustomAlertDialog(
                isForceAppUpdate: false,
                context: context,
                yesButtonText: 'yesLbl',
                yesButtonTextPostfix: 'logoutLbl',
                noButtonText: 'noLbl',
                imageName: (context.read<ThemeCubit>().state.appTheme ==
                        AppTheme.Light)
                    ? 'logout'
                    : 'logout_dark',
                titleWidget: CustomTextLabel(
                    text: 'logoutLbl',
                    textStyle: Theme.of(this.context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer)),
                messageText: 'logoutTxt',
                onYESButtonPressed: () async {
                  UiUtils.userLogOut(contxt: context);
                });
          });
        });
  }

  //set Delete dialogue
  deleteAccount() async {
    if (isDemo && email == "newstester@gmail.com") {
      showSnackBar("This feature is not allowed for Demo User", context);
    } else {
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setStater) {
              return CustomAlertDialog(
                  context: context,
                  isForceAppUpdate: false,
                  yesButtonText:
                      (_auth.currentUser != null) ? 'yesLbl' : 'logoutLbl',
                  yesButtonTextPostfix:
                      (_auth.currentUser != null) ? 'deleteTxt' : '',
                  noButtonText:
                      (_auth.currentUser != null) ? 'noLbl' : 'cancelBtn',
                  imageName: (context.read<ThemeCubit>().state.appTheme ==
                          AppTheme.Light)
                      ? 'deleteAccount'
                      : 'deleteAccount_dark',
                  titleWidget: (_auth.currentUser != null)
                      ? CustomTextLabel(
                          text: 'deleteAcc',
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer))
                      : CustomTextLabel(
                          text: 'deleteAlertTitle',
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer)),
                  messageText: (_auth.currentUser != null)
                      ? 'deleteConfirm'
                      : 'deleteRelogin',
                  onYESButtonPressed: () async {
                    (_auth.currentUser != null)
                        ? proceedToDeleteProfile()
                        : askToLoginAgain();
                  });
            });
          });
    }
  }

  askToLoginAgain() {
    showSnackBar(UiUtils.getTranslatedLabel(context, 'loginReqMsg'), context);
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.login, (route) => false);
  }

  proceedToDeleteProfile() async {
    //delete user from firebase
    try {
      await _auth.currentUser!.delete().then((value) {
        //delete user prefs from App-local
        context.read<DeleteUserCubit>().deleteUser().then((value) {
          showSnackBar(value["message"], context);
          for (int i = 0; i < AuthProviders.values.length; i++) {
            if (AuthProviders.values[i].name ==
                context.read<AuthCubit>().getType()) {
              context
                  .read<AuthCubit>()
                  .signOut(AuthProviders.values[i])
                  .then((value) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(Routes.login, (route) => false);
              });
            }
          }
        });
      });
    } on FirebaseAuthException catch (error) {
      if (error.code == "requires-recent-login") {
        for (int i = 0; i < AuthProviders.values.length; i++) {
          if (AuthProviders.values[i].name ==
              context.read<AuthCubit>().getType()) {
            context
                .read<AuthCubit>()
                .signOut(AuthProviders.values[i])
                .then((value) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(Routes.login, (route) => false);
            });
          }
        }
      } else {
        throw showSnackBar('${error.message}', context);
      }
    } catch (e) {
      //debugPrint("unable to delete user - ${e.toString()}");
    }
  }

  Future<void> _openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
          appStoreId: context.read<AppConfigurationCubit>().getAppstoreId(),
          microsoftStoreId: 'microsoftStoreId');
    } catch (e) {
      //Redirect to app link
      UiUtils.gotoStores(context);
    }
  }

  Widget setHeader() {
    return BlocBuilder<AuthCubit, AuthState>(builder: (context, authState) {
      if (authState is Authenticated &&
          context.read<AuthCubit>().getUserId() != "0") {
        email = authState.authModel.email;
        isAuthor = (authState.authModel.isAuthor == 1);
        authorStatus = (authState.authModel.authorDetails != null)
            ? (authState.authModel.authorDetails?.status! ??
                AuthorStatus.rejected)
            : AuthorStatus.rejected;

        return Padding(
          padding: const EdgeInsetsDirectional.only(
              start: 15.0, end: 15.0, top: 15.0),
          child: Container(
            padding: const EdgeInsetsDirectional.only(
                start: 16.0, end: 16.0, top: 12.0, bottom: 12.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: _cardBorder,
                color: Theme.of(context).colorScheme.surface),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  (authState.authModel.profile != null &&
                          authState.authModel.profile
                              .toString()
                              .trim()
                              .isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CustomNetworkImage(
                            networkImageUrl: authState.authModel.profile!,
                            // FIGMA(1630-9710): profile photo is 78x86 with a
                            // 4px radius and BoxFit.cover so it fills without
                            // stretching (was 80x80, BoxFit.fill which distorted
                            // the image).
                            fit: BoxFit.cover,
                            width: 78,
                            height: 86,
                            filterQuality: FilterQuality.high,
                            errorBuilder: const Icon(Icons.person),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          // Empty-state box kept at the same 78x86 size as the
                          // photo so the layout matches the design either way.
                          child: Container(
                            width: 78,
                            height: 86,
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer
                                .withOpacity(0.1),
                            child: Icon(Icons.person,
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer),
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (authState.authModel.name != null &&
                              authState.authModel.name != "")
                            CustomTextLabel(
                                text: authState.authModel.name!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: UiUtils.getColorScheme(context)
                                            .primaryContainer)),
                          const SizedBox(height: 3),
                          if (authState.authModel.mobile != null &&
                              authState.authModel.mobile!.trim().isNotEmpty)
                            CustomTextLabel(
                                text: authState.authModel.mobile!,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: UiUtils.getColorScheme(context)
                                            .primaryContainer
                                            .withOpacity(0.7))),
                          const SizedBox(height: 3),
                          if (authState.authModel.email != null &&
                              authState.authModel.email != "")
                            CustomTextLabel(
                                text: authState.authModel.email!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: UiUtils.getColorScheme(context)
                                            .primaryContainer
                                            .withOpacity(0.7))),
                          BlocConsumer<AuthorCubit, AuthorState>(
                            listener: (context, state) {
                              if (state is AuthorRequestSent)
                                showSnackBar(state.responseMessage, context);
                            },
                            builder: (context, state) {
                              return buildAuthorButton(context, state);
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ]),
          ),
        );
      } else {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              //For Guest User
              Container(
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: UiUtils.getColorScheme(context)
                              .primaryContainer)),
                  alignment: Alignment.center,
                  child: Icon(Icons.person,
                      size: 25.0,
                      color: UiUtils.getColorScheme(context).primaryContainer)),
              Expanded(child: setGuestText())
            ]);
      }
    });
  }

  Widget buildAuthorButton(BuildContext context, AuthorState state) {
    //check if user is author already
    final chipBg = _isDark ? Colors.transparent : backgroundColor;
    final approvedColor = _isDark ? darkIconColor : authorApprovedColor;
    final reviewColor =
        _isDark ? const Color(0xff4DD0D6) : authorReviewColor;
    final requestColor = _isDark ? secondaryColor : authorRequestColor;

    if (isAuthor ||
        authorStatus == AuthorStatus.approved ||
        state is AuthorApproved) {
      return IntrinsicWidth(
        child: Container(
          margin: const EdgeInsets.only(top: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: approvedColor),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_outlined, size: 18, color: approvedColor),
              const SizedBox(width: 6),
              CustomTextLabel(
                  text: 'authorLbl',
                  textStyle: TextStyle(
                      color: approvedColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (authorStatus == AuthorStatus.pending || state is AuthorRequestSent) {
      return InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(Routes.editUserProfile,
                arguments: {'from': 'becomeAuthor'});
          },
          child: IntrinsicWidth(
            child: Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: reviewColor)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 18, color: reviewColor),
                  const SizedBox(width: 6),
                  CustomTextLabel(
                      text: 'authorReviewPendingLbl',
                      textStyle: TextStyle(
                          color: reviewColor,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ));
    }

    if (authorStatus == AuthorStatus.rejected || state is AuthorInitial) {
      return InkWell(
        onTap: () {
          //redirect to update profile screen
          Navigator.of(context).pushNamed(Routes.editUserProfile,
              arguments: {'from': 'becomeAuthor'});
        },
        child: Container(
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: requestColor)),
            child: CustomTextLabel(
                text: 'becomeAuthorLbl',
                textStyle: TextStyle(
                    color: requestColor, fontWeight: FontWeight.w500))),
      );
    }

    return const SizedBox.shrink();
  }

  Widget setGuestText() {
    return BlocBuilder<LanguageJsonCubit, LanguageJsonState>(
      builder: (context, langState) {
        return RichText(
          text: TextSpan(
            text: UiUtils.getTranslatedLabel(context, 'plzLbl'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: UiUtils.getColorScheme(context).primaryContainer,
                overflow: TextOverflow.ellipsis),
            children: <TextSpan>[
              TextSpan(
                  text: " ${UiUtils.getTranslatedLabel(context, 'loginBtn')} ",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        setState(() {
                          Navigator.of(context)
                              .pushReplacementNamed(Routes.login);
                        });
                      });
                    }),
              TextSpan(
                  text:
                      "${UiUtils.getTranslatedLabel(context, 'firstAccLbl')} ",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer)),
              TextSpan(
                  text: UiUtils.getTranslatedLabel(context, 'allFunLbl'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                      overflow: TextOverflow.ellipsis))
            ],
          ),
        );
      },
    );
  }

  Widget setBody() {
    return Padding(
      padding:
          const EdgeInsetsDirectional.only(start: 15.0, end: 15.0, top: 15.0),
      child: Container(
          padding: const EdgeInsetsDirectional.only(start: 20.0, end: 20.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              border: _cardBorder,
              color: Theme.of(context).colorScheme.surface),
          child: ScrollConfiguration(
            behavior: GlobalScrollBehavior(),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsetsDirectional.only(top: 10.0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  //const BouncingScrollPhysics(),
                  children: <Widget>[
                    if (context.read<AuthCubit>().getUserId() != "0")
                      setDrawerItem('editProfile', Icons.edit_outlined, false,
                          true, false, 13),
                    setDrawerItem('darkModeLbl', Icons.swap_horizontal_circle,
                        true, false, true, 0),
                    setDrawerItem('changeLang', Icons.g_translate_rounded,
                        false, true, false, 2),
                    setDrawerItem('txtSizeLbl', Icons.format_size_rounded,
                        false, true, false, 14),
                    Divider(thickness: 4, color: _dividerColor),
                    // FIGMA(1630-9968): the approved-author rows lead the second
                    // group — News, then Podcast, then Bookmarks. "Create News"
                    // is no longer a row here; it is the bottom button on the
                    // News (ManageUserNews) screen.
                    if (context.read<AuthCubit>().getUserId() != "0" &&
                        isAuthor)
                      setDrawerItem('manageNewsLbl', Icons.newspaper_rounded,
                          false, true, false, 6),
                    // Podcast is gated on `podcast_mode` as well as on the
                    // author flag, so switching the module off in the Admin
                    // panel keeps it hidden here too.
                    if (context.read<AuthCubit>().getUserId() != "0" &&
                        isAuthor &&
                        context
                                .read<AppConfigurationCubit>()
                                .getPodcastMode() ==
                            "1")
                      setDrawerItem('managePodcastLbl', Icons.podcasts_rounded,
                          false, true, false, 15),
                    if (context.read<AuthCubit>().getUserId() != "0")
                      setDrawerItem('bookmarkLbl', Icons.bookmarks_rounded,
                          false, true, false, 3),
                    // FIGMA(1630-9968): Notification Preferences sits in the
                    // second group — after Bookmarks, before Category
                    // Preferences — as a navigable row to its own screen.
                    setDrawerItem('notificationPreferences',
                        Icons.notifications_rounded, false, true, false, 1),
                    if (context.read<AuthCubit>().getUserId() != "0")
                      setDrawerItem('managePreferences',
                          Icons.thumbs_up_down_rounded, false, true, false, 7),
                    if (context.read<AuthCubit>().getUserId() != "0")
                      Divider(thickness: 4, color: _dividerColor),
                    setDrawerItem('eNewsLbl', Icons.chrome_reader_mode_rounded,
                        false, true, false, 11),
                    pagesBuild(),
                    setDrawerItem(
                        'rateUs', Icons.stars_sharp, false, true, false, 9),
                    setDrawerItem('shareApp', Icons.share_rounded, false, true,
                        false, 10),
                    if (context.read<AuthCubit>().getUserId() != "0")
                      setDrawerItem('deleteAcc', Icons.delete_forever_rounded,
                          false, true, false, 12,
                          isDeleteAcc: true),
                  ],
                );
              },
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          height: 45,
          isBackBtn: false,
          label: 'myProfile',
          isConvertText: true,
          actionWidget: [
            if (context.read<AuthCubit>().getUserId() != "0") logoutButton()
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(
                    top: 15.0,
                    bottom: AppBottomNavBar.contentClearance(context)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[setHeader(), setBody()])),
          ],
        ));
  }

  Widget logoutButton() {
    return GestureDetector(
      onTap: () => logOutDialog(),
      child: Container(
          margin: EdgeInsetsDirectional.only(end: 15, top: 12, bottom: 12),
          height: 30,
          width: 30,
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(7),
              color: Colors.transparent,
              border:
                  Border.all(width: 2, color: borderColor.withOpacity(0.3))),
          child: Icon(Icons.power_settings_new_rounded,
              color: UiUtils.getColorScheme(context).primaryContainer,
              size: 20)),
    );
  }
}
