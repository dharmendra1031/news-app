import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/bookmarks/repositories/bookmark_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class BookmarkRepository {
  static final BookmarkRepository _bookmarkRepository =
      BookmarkRepository._internal();
  late BookmarkRemoteDataSource _bookmarkRemoteDataSource;

  factory BookmarkRepository() {
    _bookmarkRepository._bookmarkRemoteDataSource = BookmarkRemoteDataSource();
    return _bookmarkRepository;
  }

  BookmarkRepository._internal();

  Future<Map<String, dynamic>> getBookmark(
      {required String offset,
      required String limit,
      required String langCode}) async {
    final result = await _bookmarkRemoteDataSource.getBookmark(
        perPage: limit, offset: offset, langCode: langCode);
    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            "total": result[DATA][TOTAL],
            "Bookmark": (result[DATA][DATA] as List)
                .map((e) => NewsModel.fromJson(e))
                .toList()
          };
  }

  Future setBookmark({required String newsId, required String status}) async {
    final result = await _bookmarkRemoteDataSource.addBookmark(
        status: status, newsId: newsId);
    return result;
  }
}
