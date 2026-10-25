import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/survey_question/survey_que_repository.dart';

abstract class SurveyQuestionState {}

class SurveyQuestionInitial extends SurveyQuestionState {}

class SurveyQuestionFetchInProgress extends SurveyQuestionState {}

class SurveyQuestionFetchSuccess extends SurveyQuestionState {
  final List<NewsModel> surveyQuestion;

  SurveyQuestionFetchSuccess({required this.surveyQuestion});
}

class SurveyQuestionFetchFailure extends SurveyQuestionState {
  final String errorMessage;

  SurveyQuestionFetchFailure(this.errorMessage);
}

class SurveyQuestionCubit extends Cubit<SurveyQuestionState> {
  final SurveyQuestionRepository _surveyQuestionRepository;

  SurveyQuestionCubit(this._surveyQuestionRepository)
      : super(SurveyQuestionInitial());

  Future<void> getSurveyQuestion({required String langCode}) async {
    try {
      emit(SurveyQuestionFetchInProgress());
      await _surveyQuestionRepository
          .getSurveyQuestion(langCode: langCode)
          .then((value) {
        emit(SurveyQuestionFetchSuccess(
            surveyQuestion: value['SurveyQuestion']));
      });
    } catch (e) {
      emit(SurveyQuestionFetchFailure(e.toString()));
    }
  }

  void removeQuestion(String index) {
    if (state is SurveyQuestionFetchSuccess) {
      List<NewsModel> queList =
          List.from((state as SurveyQuestionFetchSuccess).surveyQuestion)
            ..removeWhere((element) => element.id! == index);
      emit(SurveyQuestionFetchSuccess(surveyQuestion: queList));
    }
  }

  List surveyList() {
    return (state is SurveyQuestionFetchSuccess)
        ? (state as SurveyQuestionFetchSuccess).surveyQuestion
        : [];
  }
}
