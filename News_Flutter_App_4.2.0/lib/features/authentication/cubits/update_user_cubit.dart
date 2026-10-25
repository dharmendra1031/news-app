import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/models/auth_model.dart';
import 'package:news/features/authentication/repositories/auth_repository.dart';

abstract class UpdateUserState {}

class UpdateUserInitial extends UpdateUserState {}

class UpdateUserFetchInProgress extends UpdateUserState {}

class UpdateUserFetchSuccess extends UpdateUserState {
  AuthModel? updatedUser;
  String? imgUpdatedPath;

  UpdateUserFetchSuccess({this.updatedUser, this.imgUpdatedPath});
}

class UpdateUserFetchFailure extends UpdateUserState {
  final String errorMessage;

  UpdateUserFetchFailure(this.errorMessage);
}

class UpdateUserCubit extends Cubit<UpdateUserState> {
  final AuthRepository _updateUserRepository;

  UpdateUserCubit(this._updateUserRepository) : super(UpdateUserInitial());

  void setUpdateUser(
      {String? name,
      String? mobile,
      String? email,
      String? filePath,
      required BuildContext context,
      String? authorBio,
      String? whatsappLink,
      String? facebookLink,
      String? telegramLink,
      String? linkedInLink}) async {
    try {
      emit(UpdateUserFetchInProgress());
      final Map<String, dynamic> result =
          await _updateUserRepository.updateUserData(
              mobile: mobile,
              name: name,
              email: email,
              filePath: filePath,
              authorBio: authorBio,
              whatsappLink: whatsappLink,
              facebookLink: facebookLink,
              telegramLink: telegramLink,
              linkedInLink: linkedInLink);
      //only incase of name,mobile & mail, not Profile Picture
      if (result["error"] == false) {
        context
            .read<AuthCubit>()
            .updateDetails(authModel: AuthModel.fromJson(result["data"]));
        emit(UpdateUserFetchSuccess(
            updatedUser: AuthModel.fromJson(result["data"])));
      } else {
        emit(UpdateUserFetchFailure(result["message"]));
      }
    } catch (e) {
      emit(UpdateUserFetchFailure(e.toString()));
    }
  }
}
