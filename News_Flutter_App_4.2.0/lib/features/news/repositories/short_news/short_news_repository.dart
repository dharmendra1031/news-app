import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/short_news/short_news_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class ShortNewsRepository {
  static final ShortNewsRepository _instance = ShortNewsRepository._internal();

  late ShortNewsRemoteDataSource _remote;

  factory ShortNewsRepository() {
    _instance._remote = ShortNewsRemoteDataSource();
    return _instance;
  }

  ShortNewsRepository._internal();

  List<NewsModel> _newsListFromData(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => NewsModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final inner = map[DATA];
      if (inner is List) {
        return inner
            .whereType<Map>()
            .map((e) => NewsModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  }

  Future<dynamic> getShortNews({required String langCode}) async {
    final result = await _remote.getShortNews(langCode: langCode);

    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            "shortNews": _newsListFromData(result[DATA][NEWS]),
            MESSAGE: result[MESSAGE],
          };
  }
}
