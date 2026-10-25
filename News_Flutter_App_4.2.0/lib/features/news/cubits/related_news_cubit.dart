import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/related_news/related_news_repository.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/strings.dart';

abstract class RelatedNewsState {}

class RelatedNewsInitial extends RelatedNewsState {}

class RelatedNewsFetchInProgress extends RelatedNewsState {}

class RelatedNewsFetchSuccess extends RelatedNewsState {
  final List<NewsModel> relatedNews;
  final int totalRelatedNewsCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  RelatedNewsFetchSuccess(
      {required this.relatedNews,
      required this.totalRelatedNewsCount,
      required this.hasMoreFetchError,
      required this.hasMore});
}

class RelatedNewsFetchFailure extends RelatedNewsState {
  final String errorMessage;

  RelatedNewsFetchFailure(this.errorMessage);
}

class RelatedNewsCubit extends Cubit<RelatedNewsState> {
  final RelatedNewsRepository _relatedNewsRepository;

  RelatedNewsCubit(this._relatedNewsRepository) : super(RelatedNewsInitial());

  void getRelatedNews(
      {required String langCode, String? catId, String? subCatId}) async {
    try {
      emit(RelatedNewsFetchInProgress());
      final result = await _relatedNewsRepository.getRelatedNews(
          perPage: limitOfAPIData.toString(),
          offset: "0",
          langCode: langCode,
          catId: catId,
          subCatId: subCatId);
      emit(RelatedNewsFetchSuccess(
          relatedNews: result['RelatedNews'],
          totalRelatedNewsCount: result[TOTAL],
          hasMoreFetchError: false,
          hasMore: (result['RelatedNews'] as List<NewsModel>).length <
              result[TOTAL]));
    } catch (e) {
      emit(RelatedNewsFetchFailure(e.toString()));
    }
  }

  bool hasMoreRelatedNews() {
    return (state is RelatedNewsFetchSuccess)
        ? (state as RelatedNewsFetchSuccess).hasMore
        : false;
  }

  // Scroll listeners call getMoreRelatedNews on every event near the bottom, so
  // a request already in flight must swallow the repeats.
  bool _isFetchingMore = false;

  void getMoreRelatedNews(
      {required String langCode,
      String? catId,
      String? subCatId,
      String? latitude,
      String? longitude}) async {
    final current = state;
    if (current is! RelatedNewsFetchSuccess || _isFetchingMore) return;
    _isFetchingMore = true;
    try {
      final result = await _relatedNewsRepository.getRelatedNews(
          perPage: limitOfAPIData.toString(),
          offset: current.relatedNews.length.toString(),
          langCode: langCode,
          subCatId: subCatId,
          catId: catId,
          latitude: latitude,
          longitude: longitude);
      // getRelatedNews replaced the list (another article was opened) while
      // this page was loading, so it no longer belongs to that list.
      if (state != current) return;
      List<NewsModel> updatedResults = current.relatedNews;
      updatedResults.addAll(result['RelatedNews'] as List<NewsModel>);
      emit(RelatedNewsFetchSuccess(
        relatedNews: updatedResults,
        totalRelatedNewsCount: result[TOTAL],
        hasMoreFetchError: false,
        hasMore: updatedResults.length < result[TOTAL],
      ));
    } catch (e) {
      if (state != current) return;
      emit(RelatedNewsFetchSuccess(
        relatedNews: current.relatedNews,
        hasMoreFetchError: true,
        totalRelatedNewsCount: current.totalRelatedNewsCount,
        hasMore: current.hasMore,
      ));
    } finally {
      _isFetchingMore = false;
    }
  }
}
