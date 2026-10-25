import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/repositories/breaking_news/break_news_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class BreakingNewsRepository {
  static final BreakingNewsRepository _breakingNewsRepository =
      BreakingNewsRepository._internal();

  late BreakingNewsRemoteDataSource _breakingNewsRemoteDataSource;

  factory BreakingNewsRepository() {
    _breakingNewsRepository._breakingNewsRemoteDataSource =
        BreakingNewsRemoteDataSource();
    return _breakingNewsRepository;
  }

  BreakingNewsRepository._internal();

  Future<dynamic> getBreakingNews({required String langCode}) async {
    final result =
        await _breakingNewsRemoteDataSource.getBreakingNews(langCode: langCode);

    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            "BreakingNews": (result[DATA][DATA] as List)
                .map((e) => BreakingNewsModel.fromJson(e))
                .toList()
          };
  }
}
