import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/get_survey_answer/get_survey_ans_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class GetSurveyAnsRepository {
  static final GetSurveyAnsRepository _getSurveyAnsRepository =
      GetSurveyAnsRepository._internal();

  late GetSurveyAnsRemoteDataSource _getSurveyAnsRemoteDataSource;

  factory GetSurveyAnsRepository() {
    _getSurveyAnsRepository._getSurveyAnsRemoteDataSource =
        GetSurveyAnsRemoteDataSource();
    return _getSurveyAnsRepository;
  }

  GetSurveyAnsRepository._internal();
  Future<Map<String, dynamic>> getSurveyAns({required String langCode}) async {
    final result =
        await _getSurveyAnsRemoteDataSource.getSurveyAns(langCode: langCode);
    return {
      "GetSurveyAns": (result[DATA][DATA] as List)
          .map((e) => NewsModel.fromSurvey(e))
          .toList()
    };
  }
}
