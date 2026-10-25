import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/repositories/set_survey_answer/set_survey_ans_repository.dart';

abstract class SetSurveyAnsState {}

class SetSurveyAnsInitial extends SetSurveyAnsState {}

class SetSurveyAnsFetchInProgress extends SetSurveyAnsState {}

class SetSurveyAnsFetchSuccess extends SetSurveyAnsState {
  // var setSurveyAns;
  final String message;

  SetSurveyAnsFetchSuccess({required this.message});
}

class SetSurveyAnsFetchFailure extends SetSurveyAnsState {
  final String errorMessage;

  SetSurveyAnsFetchFailure(this.errorMessage);
}

class SetSurveyAnsCubit extends Cubit<SetSurveyAnsState> {
  final SetSurveyAnsRepository _setSurveyAnsRepository;

  SetSurveyAnsCubit(this._setSurveyAnsRepository)
      : super(SetSurveyAnsInitial());

  void setSurveyAns(
      {required String queId,
      required String optId,
      required String languageCode}) async {
    try {
      emit(SetSurveyAnsFetchInProgress());
      final result = await _setSurveyAnsRepository.setSurveyAns(
          queId: queId, optId: optId, languageCode: languageCode);

      emit(SetSurveyAnsFetchSuccess(message: result['message']));
    } catch (e) {
      emit(SetSurveyAnsFetchFailure(e.toString()));
    }
  }
}
