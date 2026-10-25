import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class BookmarkState {}

class BookmarkInitial extends BookmarkState {}

class BookmarkFetchInProgress extends BookmarkState {}

class BookmarkFetchSuccess extends BookmarkState {
  final List<NewsModel> bookmark;
  final int totalBookmarkCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  BookmarkFetchSuccess(
      {required this.bookmark,
      required this.totalBookmarkCount,
      required this.hasMoreFetchError,
      required this.hasMore});
}

class BookmarkFetchFailure extends BookmarkState {
  final String errorMessage;

  BookmarkFetchFailure(this.errorMessage);
}

class BookmarkCubit extends Cubit<BookmarkState> {
  final BookmarkRepository bookmarkRepository;
  int perPageLimit = 25;

  BookmarkCubit(this.bookmarkRepository) : super(BookmarkInitial());

  void getBookmark({required String langCode}) async {
    emit(BookmarkFetchInProgress());

    try {
      final result = await bookmarkRepository.getBookmark(
          limit: perPageLimit.toString(), offset: "0", langCode: langCode);

      if (result[ERROR]) {
        final message = result[MESSAGE];
        if (message == "No Data Found") {
          emit(BookmarkFetchSuccess(
              bookmark: [],
              totalBookmarkCount: 0,
              hasMoreFetchError: false,
              hasMore: false));
        } else {
          emit(BookmarkFetchFailure(message));
        }
        return;
      }

      final bookmarks = result['Bookmark'] as List<NewsModel>;
      final total = result[TOTAL] as int;

      emit(BookmarkFetchSuccess(
          bookmark: bookmarks,
          totalBookmarkCount: total,
          hasMoreFetchError: false,
          hasMore: bookmarks.length < total));
    } catch (e) {
      final error = e.toString();
      emit(error == "No Data Found"
          ? BookmarkFetchSuccess(
              bookmark: [],
              totalBookmarkCount: 0,
              hasMoreFetchError: false,
              hasMore: false)
          : BookmarkFetchFailure(error));
    }
  }

  bool hasMoreBookmark() {
    return (state is BookmarkFetchSuccess)
        ? (state as BookmarkFetchSuccess).hasMore
        : false;
  }

  void getMoreBookmark({required String langCode}) async {
    if (state is BookmarkFetchSuccess) {
      try {
        final result = await bookmarkRepository.getBookmark(
            limit: perPageLimit.toString(),
            offset: (state as BookmarkFetchSuccess).bookmark.length.toString(),
            langCode: langCode);
        List<NewsModel> updatedResults =
            (state as BookmarkFetchSuccess).bookmark;
        updatedResults.addAll(result['Bookmark'] as List<NewsModel>);
        emit(BookmarkFetchSuccess(
            bookmark: updatedResults,
            totalBookmarkCount: result[TOTAL],
            hasMoreFetchError: false,
            hasMore: updatedResults.length < result[TOTAL]));
      } catch (e) {
        emit(BookmarkFetchSuccess(
            bookmark: (state as BookmarkFetchSuccess).bookmark,
            hasMoreFetchError: (e.toString() == "No Data Found") ? false : true,
            totalBookmarkCount:
                (state as BookmarkFetchSuccess).totalBookmarkCount,
            hasMore: (state as BookmarkFetchSuccess).hasMore));
      }
    }
  }

  void addBookmarkNews(NewsModel model) {
    // //print("Add bookmark locally - state is $state");
    if (state is BookmarkFetchSuccess) {
      List<NewsModel> bookmarklist = [];
      bookmarklist.insert(0, model);
      bookmarklist.addAll((state as BookmarkFetchSuccess).bookmark);

      emit(BookmarkFetchSuccess(
          bookmark: List.from(bookmarklist),
          hasMoreFetchError: true,
          totalBookmarkCount:
              (state as BookmarkFetchSuccess).totalBookmarkCount,
          hasMore: (state as BookmarkFetchSuccess).hasMore));
    }
  }

  void removeBookmarkNews(NewsModel model) {
    if (state is BookmarkFetchSuccess) {
      final bookmark = (state as BookmarkFetchSuccess).bookmark;
      bookmark.removeWhere(((element) =>
          (element.id == model.id || element.newsId == model.id)));
      emit(BookmarkFetchSuccess(
          bookmark: List.from(bookmark),
          hasMoreFetchError: true,
          totalBookmarkCount:
              (state as BookmarkFetchSuccess).totalBookmarkCount,
          hasMore: (state as BookmarkFetchSuccess).hasMore));
    }
  }

  bool isNewsBookmark(String newsId) {
    // //print("Bookmark state is - $state");

    if (state is BookmarkFetchSuccess) {
      // //print("Bookmark success length - ${(state as BookmarkFetchSuccess).bookmark.length}");
      final bookmark = (state as BookmarkFetchSuccess).bookmark;
      return (bookmark.isNotEmpty)
          ? (bookmark.indexWhere((element) =>
                  (element.newsId == newsId || element.id == newsId)) !=
              -1)
          : false;
    }
    return false;
  }

  void resetState() {
    emit(BookmarkFetchInProgress());
  }
}
