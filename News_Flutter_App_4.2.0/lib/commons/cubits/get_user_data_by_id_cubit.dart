import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/repositories/get_user_by_id/get_user_by_id_repository.dart';

abstract class GetUserByIdState {}

class GetUserByIdInitial extends GetUserByIdState {}

class GetUserByIdFetchInProgress extends GetUserByIdState {}

class GetUserByIdFetchSuccess extends GetUserByIdState {
  var result;

  GetUserByIdFetchSuccess({required this.result});
}

class GetUserByIdFetchFailure extends GetUserByIdState {
  final String errorMessage;

  GetUserByIdFetchFailure(this.errorMessage);
}

class GetUserByIdCubit extends Cubit<GetUserByIdState> {
  final GetUserByIdRepository _getUserByIdRepository;

  GetUserByIdCubit(this._getUserByIdRepository) : super(GetUserByIdInitial());

  void getUserById() {
    emit(GetUserByIdFetchInProgress());
    _getUserByIdRepository.getUserById().then((value) {
      emit(GetUserByIdFetchSuccess(result: value));
    }).catchError((e) {
      emit(GetUserByIdFetchFailure(e.toString()));
    });
  }
}
