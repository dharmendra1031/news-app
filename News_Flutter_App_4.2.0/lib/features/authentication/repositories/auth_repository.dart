import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:news/commons/enums.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/features/author/models/author_model.dart';
import 'package:news/features/authentication/repositories/auth_local_data_source.dart';
import 'package:news/features/authentication/repositories/auth_remote_data_source.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/core/constants/strings.dart';

class AuthRepository {
  static final AuthRepository _authRepository = AuthRepository._internal();
  late AuthLocalDataSource _authLocalDataSource;
  late AuthRemoteDataSource _authRemoteDataSource;

  factory AuthRepository() {
    _authRepository._authLocalDataSource = AuthLocalDataSource();
    _authRepository._authRemoteDataSource = AuthRemoteDataSource();
    return _authRepository;
  }

  AuthRepository._internal();

  AuthLocalDataSource get authLocalDataSource => _authLocalDataSource;

  //to get auth detials stored in hive box
  getLocalAuthDetails() {
    return {
      "isLogIn": _authLocalDataSource.checkIsAuth(),
      ID: _authLocalDataSource.getId(),
      NAME: _authLocalDataSource.getName(),
      EMAIL: _authLocalDataSource.getEmail(),
      MOBILE: _authLocalDataSource.getMobile(),
      TYPE: _authLocalDataSource.getType(),
      PROFILE: _authLocalDataSource.getProfile(),
      STATUS: _authLocalDataSource.getStatus(),
      // ROLE: _authLocalDataSource.getRole(),
      TOKEN: _authLocalDataSource.getJWTtoken(),
      AUTHOR_BIO: _authLocalDataSource.getAuthorBio(),
      AUTHOR_STATUS: _authLocalDataSource.getAuthorStatus().name,
      AUTHOR_WHATSAPP_LINK: _authLocalDataSource.getAuthorWhatsappLink(),
      AUTHOR_FACEBOOK_LINK: _authLocalDataSource.getAuthorFacebookLink(),
      AUTHOR_TELEGRAM_LINK: _authLocalDataSource.getAuthorTelegramLink(),
      AUTHOR_LINKEDIN_LINK: _authLocalDataSource.getAuthorLinkedInLink()
    };
  }

  setLocalAuthDetails(
      {required bool authStatus,
      required String id,
      required String name,
      required String email,
      required String mobile,
      required String type,
      required String profile,
      required String status,
      // required String role,
      required String jwtToken,
      required int isAuthor,
      Author? authorDetails}) {
    _authLocalDataSource.changeAuthStatus(authStatus);
    _authLocalDataSource.setId(id);
    _authLocalDataSource.setName(name);
    _authLocalDataSource.setEmail(email);
    _authLocalDataSource.setMobile(mobile);
    _authLocalDataSource.setType(type);
    _authLocalDataSource.setProfile(profile);
    _authLocalDataSource.setStatus(status);
    // _authLocalDataSource.setRole(role);
    _authLocalDataSource.setJWTtoken(jwtToken);
    _authLocalDataSource.setAuthorStatus((authorDetails != null)
        ? authorDetails.status!
        : AuthorStatus.rejected);
    _authLocalDataSource
        .setAuthorBio((authorDetails != null) ? authorDetails.bio : "");
    _authLocalDataSource.setSocialMediaLinks(
        (authorDetails != null) ? authorDetails.whatsappLink : "",
        (authorDetails != null) ? authorDetails.facebookLink : "",
        (authorDetails != null) ? authorDetails.telegramLink : "",
        (authorDetails != null) ? authorDetails.linkedinLink : "");
  }

  //First we signin user with given provider then add user details
  Future<Map<String, dynamic>> signInUser(
      {required BuildContext context,
      required AuthProviders authProvider,
      String? email,
      String? password,
      String? otp,
      String? verifiedId}) async {
    try {
      final result = await _authRemoteDataSource.socialSignInUser(
          context: context,
          authProvider: authProvider,
          email: email,
          password: password,
          verifiedId: verifiedId,
          otp: otp);
      final user = result['user'] as User;
      var providerData = user.providerData[0];
      if ((authProvider == AuthProviders.email && !user.emailVerified) &&
          (isDemo && user.email != "newstester@gmail.com")) {
        throw ApiException(
            UiUtils.getTranslatedLabel(context, 'verifyEmailMsg'));
      }

      // id_token is the primary authentication for user_signup; the backend
      // verifies it, so it is fetched right after sign-in (valid ~1 hour).
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(ErrorMessageKeys.defaultErrorMessage);
      }

      Map<String, dynamic> userDataTest = await _authRemoteDataSource.loginAuth(
          idToken: idToken,
          mobile: providerData.phoneNumber ?? "",
          email: providerData.email ?? "",
          firebaseId: user.uid,
          name: providerData.displayName ?? "",
          profile: providerData.photoURL ?? "",
          type: authProvider.name);
      if (!userDataTest[ERROR]) {
        if (userDataTest[DATA][STATUS].toString() != "0") {
          setLocalAuthDetails(
              type: userDataTest[DATA][TYPE] ?? "",
              profile: userDataTest[DATA][PROFILE] ?? "",
              name: userDataTest[DATA][NAME] ?? "",
              email: userDataTest[DATA][EMAIL] ?? "",
              authStatus: true,
              id: (userDataTest[DATA][ID].toString() != "")
                  ? userDataTest[DATA][ID].toString()
                  : "0",
              mobile: userDataTest[DATA][MOBILE] ?? "",
              // role: userDataTest[DATA][ROLE].toString(),
              status: userDataTest[DATA][STATUS].toString(),
              jwtToken: userDataTest[DATA][TOKEN] ?? "",
              isAuthor: userDataTest[DATA][IS_AUTHOR] ?? 0,
              // authorStatus
              authorDetails: (userDataTest[DATA][IS_AUTHOR] == 1 &&
                      userDataTest[DATA][AUTHOR] != null)
                  ? Author.fromJson(userDataTest[DATA][AUTHOR])
                  : null);
        }
        return userDataTest;
      } else {
        signOut(authProvider);
        throw ApiMessageAndCodeException(errorMessage: userDataTest[MESSAGE]);
      }
    } catch (e) {
      signOut(authProvider);
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> updateUserData(
      {String? name,
      String? mobile,
      String? email,
      String? filePath,
      String? authorBio,
      // AuthorStatus? authorStatus,
      String? whatsappLink,
      String? facebookLink,
      String? telegramLink,
      String? linkedInLink}) async {
    final result = await _authRemoteDataSource.updateUserData(
        email: email,
        name: name,
        mobile: mobile,
        filePath: filePath,
        authorBio: authorBio,
        whatsappLink: whatsappLink,
        facebookLink: facebookLink,
        telegramLink: telegramLink,
        linkedInLink: linkedInLink);
    if (name != null) _authLocalDataSource.setName(name);
    if (mobile != null) _authLocalDataSource.setMobile(mobile);
    if (email != null) _authLocalDataSource.setEmail(email);
    if (filePath != null && filePath.isNotEmpty)
      _authLocalDataSource.setProfile(result[PROFILE]);
    if (authorBio != null) _authLocalDataSource.setAuthorBio(authorBio);
    if (whatsappLink != null ||
        facebookLink != null ||
        telegramLink != null ||
        linkedInLink != null)
      _authLocalDataSource.setSocialMediaLinks(
          whatsappLink, facebookLink, telegramLink, linkedInLink);

    return result;
  }

  Future<Map<String, dynamic>> registerToken(
      {required String fcmId, required BuildContext context}) async {
    final result = await _authRemoteDataSource.registerToken(
        fcmId: fcmId, context: context);
    return result;
  }

  //to delete my account
  Future<dynamic> deleteUser() async {
    final result = await _authRemoteDataSource.deleteUserAcc();
    return result;
  }

  Future<void> signOut(AuthProviders authProvider) async {
    _authRemoteDataSource.signOut(authProvider);
    await _authLocalDataSource.changeAuthStatus(false);
    await _authLocalDataSource.setId("0");
    await _authLocalDataSource.setName("");
    await _authLocalDataSource.setEmail("");
    await _authLocalDataSource.setMobile("");
    await _authLocalDataSource.setType("");
    await _authLocalDataSource.setProfile("");
    // await _authLocalDataSource.setRole("");
    await _authLocalDataSource.setStatus("");
    await _authLocalDataSource.setJWTtoken("");
    await _authLocalDataSource.setAuthorBio("");
    await _authLocalDataSource.setAuthorStatus(AuthorStatus.rejected);
    await _authLocalDataSource.setSocialMediaLinks("", "", "", "");
    await Hive.box(authBoxKey).clear();
  }
}
