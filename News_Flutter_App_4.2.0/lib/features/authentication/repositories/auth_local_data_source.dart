import 'package:hive/hive.dart';
import 'package:news/commons/enums.dart';
import 'package:news/core/constants/hive_box_keys.dart';

//AuthLocalDataSource will communicate with local database (hive)
class AuthLocalDataSource {
  bool? checkIsAuth() {
    return Hive.box(authBoxKey).get(isLogInKey, defaultValue: false) ?? false;
  }

  String? getId() {
    return Hive.box(authBoxKey).get(userIdKey, defaultValue: "0");
  }

  Future<void> setId(String? id) async {
    Hive.box(authBoxKey).put(userIdKey, id);
  }

  String? getName() {
    return Hive.box(authBoxKey).get(userNameKey, defaultValue: "");
  }

  Future<void> setName(String? name) async {
    Hive.box(authBoxKey).put(userNameKey, name);
  }

  String? getEmail() {
    return Hive.box(authBoxKey).get(userEmailKey, defaultValue: "");
  }

  Future<void> setEmail(String? email) async {
    Hive.box(authBoxKey).put(userEmailKey, email);
  }

  String? getMobile() {
    return Hive.box(authBoxKey).get(userMobKey, defaultValue: "");
  }

  Future<void> setMobile(String? mobile) async {
    Hive.box(authBoxKey).put(userMobKey, mobile);
  }

  String? getType() {
    return Hive.box(authBoxKey).get(userTypeKey, defaultValue: "");
  }

  Future<void> setType(String? type) async {
    Hive.box(authBoxKey).put(userTypeKey, type);
  }

  String? getProfile() {
    return Hive.box(authBoxKey).get(userProfileKey, defaultValue: "");
  }

  Future<void> setProfile(String? image) async {
    Hive.box(authBoxKey).put(userProfileKey, image);
  }

  String? getStatus() {
    return Hive.box(authBoxKey).get(userStatusKey, defaultValue: "");
  }

  Future<void> setStatus(String? status) async {
    Hive.box(authBoxKey).put(userStatusKey, status);
  }

  String getJWTtoken() {
    return Hive.box(authBoxKey).get(jwtTokenKey, defaultValue: "");
  }

  Future<void> setJWTtoken(String? jwtToken) async {
    Hive.box(authBoxKey).put(jwtTokenKey, jwtToken);
  }

  Future<void> changeAuthStatus(bool? authStatus) async {
    Hive.box(authBoxKey).put(isLogInKey, authStatus);
  }

  String? getAuthorWhatsappLink() {
    return Hive.box(authBoxKey).get(
        (authorWhatsappLinkKey != "0") ? authorWhatsappLinkKey : "",
        defaultValue: "");
  }

  String? getAuthorFacebookLink() {
    return Hive.box(authBoxKey).get(
        (authorfacebookLinkKey != "0") ? authorfacebookLinkKey : "",
        defaultValue: "");
  }

  String? getAuthorTelegramLink() {
    return Hive.box(authBoxKey).get(
        (authorTelegramLinkKey != "0") ? authorTelegramLinkKey : "",
        defaultValue: "");
  }

  String? getAuthorLinkedInLink() {
    return Hive.box(authBoxKey).get(
        (authorLinkedInLinkKey != "0") ? authorLinkedInLinkKey : "",
        defaultValue: "");
  }

  Future<void> setSocialMediaLinks(
      String? whatsappLink, facebookLink, telegramLink, linkedInLink) async {
    Hive.box(authBoxKey).put(authorWhatsappLinkKey, whatsappLink);
    Hive.box(authBoxKey).put(authorfacebookLinkKey, facebookLink);
    Hive.box(authBoxKey).put(authorTelegramLinkKey, telegramLink);
    Hive.box(authBoxKey).put(authorLinkedInLinkKey, linkedInLink);
  }

  String getAuthorBio() {
    return Hive.box(authBoxKey).get(authorBioKey, defaultValue: "");
  }

  Future<void> setAuthorBio(String? authorBio) async {
    Hive.box(authBoxKey).put(authorBioKey, authorBio);
  }

  AuthorStatus getAuthorStatus() {
    final value = Hive.box(authBoxKey)
        .get(authorStatusKey, defaultValue: AuthorStatus.rejected.name);

    return AuthorStatus.values.byName(value);
  }

  Future<void> setAuthorStatus(AuthorStatus authorStatus) async {
    Hive.box(authBoxKey).put(authorStatusKey, authorStatus.name);
  }
}
