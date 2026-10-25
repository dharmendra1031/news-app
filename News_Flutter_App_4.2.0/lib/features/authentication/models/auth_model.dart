import 'package:news/features/author/models/author_model.dart';
import 'package:news/core/constants/strings.dart';

class AuthModel {
  String? id;
  String? name;
  String? email;
  String? mobile;
  String? profile;
  String? type;
  String? status;
  String? isFirstLogin; // 0 - new user, 1 - existing user
  // String? role;
  String? jwtToken;
  int? isAuthor;
  Author? authorDetails;

  AuthModel(
      {this.id,
      this.name,
      this.email,
      this.mobile,
      this.profile,
      this.type,
      this.status,
      this.isFirstLogin,
      this.jwtToken,
      this.authorDetails,
      this.isAuthor = 0});

  AuthModel.fromJson(Map<String, dynamic> json) {
    id = json[ID].toString();
    name = json[NAME] ?? "";
    email = json[EMAIL] ?? "";
    mobile = json[MOBILE] ?? "";
    profile = json[PROFILE] ?? "";
    type = json[TYPE] ?? "";
    status = json[STATUS].toString();
    isFirstLogin = (json[IS_LOGIN] != null) ? json[IS_LOGIN].toString() : "";
    // role = json[ROLE].toString();
    jwtToken = json[TOKEN] ?? "";
    isAuthor = json[IS_AUTHOR];
    authorDetails = (isAuthor == 1 &&
            (json.containsKey(AUTHOR) &&
                json[AUTHOR] != null &&
                json[AUTHOR].isNotEmpty))
        ? Author.fromJson(json[AUTHOR])
        : null;
  }
}
