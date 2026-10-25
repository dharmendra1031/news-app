import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/preferences/repositories/set_user_pref_cat_repository.dart';

abstract class SetUserPrefCatState {}

class SetUserPrefCatInitial extends SetUserPrefCatState {}

class SetUserPrefCatFetchInProgress extends SetUserPrefCatState {}

class SetUserPrefCatFetchSuccess extends SetUserPrefCatState {
  var setUserPrefCat;

  SetUserPrefCatFetchSuccess({required this.setUserPrefCat});
}

class SetUserPrefCatFetchFailure extends SetUserPrefCatState {
  final String errorMessage;

  SetUserPrefCatFetchFailure(this.errorMessage);
}

class SetUserPrefCatCubit extends Cubit<SetUserPrefCatState> {
  final SetUserPrefCatRepository _setUserPrefCatRepository;

  SetUserPrefCatCubit(this._setUserPrefCatRepository)
      : super(SetUserPrefCatInitial());

  void setUserPrefCat({required String catId}) async {
    emit(SetUserPrefCatFetchInProgress());
    try {
      final result =
          await _setUserPrefCatRepository.setUserPrefCat(catId: catId);

      emit(
          SetUserPrefCatFetchSuccess(setUserPrefCat: result['SetUserPrefCat']));
    } catch (e) {
      emit(SetUserPrefCatFetchFailure(e.toString()));
    }
  }
}
