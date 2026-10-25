import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/preferences/repositories/user_by_cat_repository.dart';

abstract class UserByCatState {}

class UserByCatInitial extends UserByCatState {}

class UserByCatFetchInProgress extends UserByCatState {}

class UserByCatFetchSuccess extends UserByCatState {
  var userByCat;

  UserByCatFetchSuccess({required this.userByCat});
}

class UserByCatFetchFailure extends UserByCatState {
  final String errorMessage;

  UserByCatFetchFailure(this.errorMessage);
}

class UserByCatCubit extends Cubit<UserByCatState> {
  final UserByCatRepository _userByCatRepository;

  UserByCatCubit(this._userByCatRepository) : super(UserByCatInitial());

  void getUserById() async {
    emit(UserByCatFetchInProgress());
    try {
      final result = await _userByCatRepository.getUserById();
      emit(UserByCatFetchSuccess(
          userByCat: result['UserByCat']['user_category']));
    } catch (e) {
      emit(UserByCatFetchFailure(e.toString()));
    }
  }
}
