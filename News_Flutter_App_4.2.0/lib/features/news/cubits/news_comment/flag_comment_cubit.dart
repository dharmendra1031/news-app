import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/repositories/news_comment/flag_comment/flag_comm_repository.dart';

abstract class SetFlagState {}

class SetFlagInitial extends SetFlagState {}

class SetFlagFetchInProgress extends SetFlagState {}

class SetFlagFetchSuccess extends SetFlagState {
  String message;

  SetFlagFetchSuccess({required this.message});
}

class SetFlagFetchFailure extends SetFlagState {
  final String errorMessage;

  SetFlagFetchFailure(this.errorMessage);
}

class SetFlagCubit extends Cubit<SetFlagState> {
  final SetFlagRepository _setFlagRepository;

  SetFlagCubit(this._setFlagRepository) : super(SetFlagInitial());

  void setFlag(
      {required String commId,
      required String newsId,
      required String message}) async {
    try {
      emit(SetFlagFetchInProgress());
      final result = await _setFlagRepository.setFlag(
          message: message, newsId: newsId, commId: commId);
      emit(SetFlagFetchSuccess(message: result['message']));
    } catch (e) {
      emit(SetFlagFetchFailure(e.toString()));
    }
  }
}
