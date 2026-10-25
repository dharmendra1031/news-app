import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/authentication/models/auth_model.dart';
import 'package:news/features/authentication/repositories/auth_repository.dart';

const String loginEmail = "email";
const String loginGmail = "google";
const String loginFb = "facebook";
const String loginMbl = "mobile";
const String loginApple = "apple";

enum AuthProviders { google, facebook, apple, mobile, email }

@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  //to store authDetails
  final AuthModel authModel;

  Authenticated({required this.authModel});
}

class Unauthenticated extends AuthState {}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    checkAuthStatus();
  }

  AuthRepository get authRepository => _authRepository;

  void checkAuthStatus() {
    //authDetails is map. keys are isLogin,userId,authProvider
    final authDetails = _authRepository.getLocalAuthDetails();

    (authDetails['isLogIn'])
        ? emit(Authenticated(authModel: AuthModel.fromJson(authDetails)))
        : emit(Unauthenticated());
  }

  String getUserId() {
    return (state is Authenticated)
        ? (state as Authenticated).authModel.id!
        : "0";
  }

  String getProfile() {
    return (state is Authenticated)
        ? ((state as Authenticated).authModel.profile!.trim().isNotEmpty)
            ? (state as Authenticated).authModel.profile!
            : ""
        : "";
  }

  String getMobile() {
    return (state is Authenticated)
        ? (state as Authenticated).authModel.mobile!
        : "";
  }

  String getType() {
    return (state is Authenticated)
        ? (state as Authenticated).authModel.type ?? ""
        : "";
  }

  String getAuthorBio() {
    return (state is Authenticated &&
            (state as Authenticated).authModel.authorDetails != null)
        ? ((state as Authenticated).authModel.authorDetails?.bio ?? "")
        : "";
  }

  String getAuthorWhatsappLink() {
    return (state is Authenticated &&
            (state as Authenticated).authModel.authorDetails != null)
        ? (state as Authenticated).authModel.authorDetails?.whatsappLink ?? ""
        : "";
  }

  String getAuthorTelegramLink() {
    return (state is Authenticated &&
            (state as Authenticated).authModel.authorDetails != null)
        ? (state as Authenticated).authModel.authorDetails?.telegramLink ?? ""
        : "";
  }

  String getAuthorFacebookLink() {
    return (state is Authenticated &&
            (state as Authenticated).authModel.authorDetails != null)
        ? (state as Authenticated).authModel.authorDetails?.facebookLink ?? ""
        : "";
  }

  String getAuthorLinkedInLink() {
    return (state is Authenticated &&
            (state as Authenticated).authModel.authorDetails != null)
        ? (state as Authenticated).authModel.authorDetails?.linkedinLink ?? ""
        : "";
  }

  /// True when the logged-in author is flagged for auto-approval, i.e. their
  /// posted news is published immediately without per-article admin review.
  bool isAuthorAutoApprove() {
    return (state is Authenticated &&
            (state as Authenticated).authModel.authorDetails != null)
        ? ((state as Authenticated).authModel.authorDetails?.autoApprove ??
            false)
        : false;
  }

  void updateDetails({required AuthModel authModel}) {
    emit(Authenticated(authModel: authModel));
  }

  Future signOut(AuthProviders authProvider) async {
    if (state is Authenticated) {
      _authRepository.signOut(authProvider);
      emit(Unauthenticated());
    }
  }

  bool isAuthor() {
    return (state is Authenticated)
        ? ((state as Authenticated).authModel.isAuthor == 1)
        : false;
  }
}
