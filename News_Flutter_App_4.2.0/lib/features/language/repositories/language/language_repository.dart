import 'package:news/features/language/models/app_language_model.dart';
import 'package:news/features/language/repositories/language/language_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class LanguageRepository {
  static final LanguageRepository _languageRepository =
      LanguageRepository._internal();

  late LanguageRemoteDataSource _languageRemoteDataSource;

  factory LanguageRepository() {
    _languageRepository._languageRemoteDataSource = LanguageRemoteDataSource();
    return _languageRepository;
  }

  LanguageRepository._internal();

  Future<Map<String, dynamic>> getLanguage() async {
    final result = await _languageRemoteDataSource.getLanguages();

    return {
      "Language": (result[DATA][DATA] as List)
          .map((e) => LanguageModel.fromJson(e))
          .toList()
    };
  }
}
