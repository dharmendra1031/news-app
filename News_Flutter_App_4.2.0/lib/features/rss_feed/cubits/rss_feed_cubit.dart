import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class RSSFeedState {}

class RSSFeedInitial extends RSSFeedState {}

class RSSFeedFetchInProgress extends RSSFeedState {}

class RSSFeedFetchSuccess extends RSSFeedState {
  final List<RSSFeedModel> RSSFeed;
  final int totalRSSFeedCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  RSSFeedFetchSuccess(
      {required this.RSSFeed,
      required this.totalRSSFeedCount,
      required this.hasMoreFetchError,
      required this.hasMore});
}

class RSSFeedFetchFailure extends RSSFeedState {
  final String errorMessage;

  RSSFeedFetchFailure(this.errorMessage);
}

class RSSFeedCubit extends Cubit<RSSFeedState> {
  RSSFeedCubit() : super(RSSFeedInitial());
  int limit = 10;

  void getRSSFeed(
      {required String langCode,
      String? categoryId,
      String? subCategoryId}) async {
    try {
      emit(RSSFeedFetchInProgress());

      final result = await Api.sendApiRequest(body: {
        LANGUAGE_CODE: langCode,
        if (categoryId != null) CATEGORY_ID: categoryId,
        if (subCategoryId != null) SUBCAT_ID: subCategoryId,
        LIMIT: limit,
        OFFSET: 0
      }, url: Api.rssFeedApi);

      int totalFeeds = (!result[ERROR])
          ? (result[DATA][DATA] as List)
              .map((e) => RSSFeedModel.fromJson(e))
              .toList()
              .length
          : 0;
      (!result[ERROR] && result[DATA][DATA] != null)
          ? emit(RSSFeedFetchSuccess(
              RSSFeed: (result[DATA][DATA] as List)
                  .map((e) => RSSFeedModel.fromJson(e))
                  .toList(),
              totalRSSFeedCount: result[DATA][TOTAL],
              hasMoreFetchError: false,
              hasMore: (totalFeeds < result[DATA][TOTAL])))
          : emit(RSSFeedFetchFailure(result[MESSAGE]));
    } catch (e) {
      emit(RSSFeedFetchFailure(e.toString()));
    }
  }

  bool hasMoreRSSFeed() {
    return (state is RSSFeedFetchSuccess)
        ? (state as RSSFeedFetchSuccess).hasMore
        : false;
  }

  void getMoreRSSFeed({required String langCode}) async {
    if (state is RSSFeedFetchSuccess) {
      try {
        final result = await Api.sendApiRequest(body: {
          LANGUAGE_CODE: langCode,
          LIMIT: limit,
          OFFSET: (state as RSSFeedFetchSuccess).RSSFeed.length
        }, url: Api.rssFeedApi);
        if (!result[ERROR] && result[DATA][DATA] != null) {
          List<RSSFeedModel> updatedResults =
              (state as RSSFeedFetchSuccess).RSSFeed;
          updatedResults.addAll((result[DATA][DATA] as List)
              .map((e) => RSSFeedModel.fromJson(e))
              .toList());
          emit(RSSFeedFetchSuccess(
              RSSFeed: updatedResults,
              totalRSSFeedCount: result[DATA][TOTAL],
              hasMoreFetchError: false,
              hasMore: updatedResults.length < result[DATA][TOTAL]));
        } else {
          emit(RSSFeedFetchFailure(result[MESSAGE]));
        }
      } catch (e) {
        emit(RSSFeedFetchSuccess(
            RSSFeed: (state as RSSFeedFetchSuccess).RSSFeed,
            hasMoreFetchError: true,
            totalRSSFeedCount: (state as RSSFeedFetchSuccess).totalRSSFeedCount,
            hasMore: (state as RSSFeedFetchSuccess).hasMore));
      }
    }
  }
}
