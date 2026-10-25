import 'package:news/features/enews/models/enews_model.dart';
import 'package:news/features/enews/repositories/enews_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class ENewsRepository {
  static final ENewsRepository _eNewsRepository = ENewsRepository._internal();

  late ENewsRemoteDataSource _eNewsRemoteDataSource;

  factory ENewsRepository() {
    _eNewsRepository._eNewsRemoteDataSource = ENewsRemoteDataSource();
    return _eNewsRepository;
  }

  ENewsRepository._internal();

  Future<Map<String, dynamic>> getENews({
    required String languageCode,
    required String perPage,
    required String page,
  }) async {
    final result = await _eNewsRemoteDataSource.getENews(
      languageCode: languageCode,
      perPage: perPage,
      page: page,
    );

    // Response structure: { error, message, data: { current_page, data: [...], total, last_page, next_page_url, ... } }
    final Map<String, dynamic> paginatedData =
        result[DATA] as Map<String, dynamic>;
    final List<ENewsModel> eNewsList = (paginatedData['data'] as List)
        .map((e) => ENewsModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final int total = paginatedData['total'] is int
        ? paginatedData['total']
        : int.tryParse(paginatedData['total'].toString()) ?? 0;

    final int lastPage = paginatedData['last_page'] is int
        ? paginatedData['last_page']
        : int.tryParse(paginatedData['last_page'].toString()) ?? 1;

    final int currentPage = paginatedData['current_page'] is int
        ? paginatedData['current_page']
        : int.tryParse(paginatedData['current_page'].toString()) ?? 1;

    return {
      ERROR: result[ERROR],
      "eNews": eNewsList,
      TOTAL: total,
      "lastPage": lastPage,
      "currentPage": currentPage,
      "hasMore": paginatedData['next_page_url'] != null,
    };
  }
}
