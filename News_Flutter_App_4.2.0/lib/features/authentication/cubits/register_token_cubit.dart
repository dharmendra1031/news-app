import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/authentication/repositories/auth_repository.dart';

@immutable
abstract class RegisterTokenState {}

class RegisterTokenInitial extends RegisterTokenState {}

class RegisterTokenProgress extends RegisterTokenState {
  RegisterTokenProgress();
}

class RegisterTokenSuccess extends RegisterTokenState {
  RegisterTokenSuccess();
}

class RegisterTokenFailure extends RegisterTokenState {
  final String errorMessage;

  RegisterTokenFailure(this.errorMessage);
}

class RegisterTokenCubit extends Cubit<RegisterTokenState> {
  final AuthRepository _authRepository;

  RegisterTokenCubit(this._authRepository) : super(RegisterTokenInitial());

  void registerToken({required String fcmId, required BuildContext context}) {
    emit(RegisterTokenProgress());
    _authRepository
        .registerToken(fcmId: fcmId, context: context)
        .then((result) {
      emit(RegisterTokenSuccess());
    }).catchError((e) {
      emit(RegisterTokenFailure(e.toString()));
    });
  }
}
