import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/get_survey_answer/get_survey_ans_repository.dart';

abstract class GetSurveyAnsState {}

class GetSurveyAnsInitial extends GetSurveyAnsState {}

class GetSurveyAnsFetchInProgress extends GetSurveyAnsState {}

class GetSurveyAnsFetchSuccess extends GetSurveyAnsState {
  final List<NewsModel> getSurveyAns;

  GetSurveyAnsFetchSuccess({required this.getSurveyAns});
}

class GetSurveyAnsFetchFailure extends GetSurveyAnsState {
  final String errorMessage;

  GetSurveyAnsFetchFailure(this.errorMessage);
}

class GetSurveyAnsCubit extends Cubit<GetSurveyAnsState> {
  final GetSurveyAnsRepository _getSurveyAnsRepository;

  GetSurveyAnsCubit(this._getSurveyAnsRepository)
      : super(GetSurveyAnsInitial());

  void getSurveyAns({required String langCode}) async {
    try {
      emit(GetSurveyAnsFetchInProgress());
      final result =
          await _getSurveyAnsRepository.getSurveyAns(langCode: langCode);
      emit(GetSurveyAnsFetchSuccess(getSurveyAns: result['GetSurveyAns']));
    } catch (e) {
      emit(GetSurveyAnsFetchFailure(e.toString()));
    }
  }
}
