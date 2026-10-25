import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/survey_question/survey_que_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class SurveyQuestionRepository {
  static final SurveyQuestionRepository _surveyQuestionRepository =
      SurveyQuestionRepository._internal();

  late SurveyQuestionRemoteDataSource _surveyQuestionRemoteDataSource;

  factory SurveyQuestionRepository() {
    _surveyQuestionRepository._surveyQuestionRemoteDataSource =
        SurveyQuestionRemoteDataSource();
    return _surveyQuestionRepository;
  }

  SurveyQuestionRepository._internal();

  Future<Map<String, dynamic>> getSurveyQuestion(
      {required String langCode}) async {
    final result = await _surveyQuestionRemoteDataSource.getSurveyQuestions(
        langCode: langCode);

    return {
      "SurveyQuestion": (result[DATA][DATA] as List)
          .map((e) => NewsModel.fromSurvey(e))
          .toList()
    };
  }
}
