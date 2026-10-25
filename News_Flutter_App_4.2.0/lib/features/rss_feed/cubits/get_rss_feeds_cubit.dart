import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class GetRssFeedsState {}

class GetRssFeedsInitial extends GetRssFeedsState {}

class GetRssFeedsFetchInProgress extends GetRssFeedsState {}

class GetRssFeedsFetchSuccess extends GetRssFeedsState {
  final List<RSSFeedModel> rssFeeds;
  final int totalRssFeedsCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  GetRssFeedsFetchSuccess({
    required this.rssFeeds,
    required this.totalRssFeedsCount,
    required this.hasMoreFetchError,
    required this.hasMore,
  });
}

class GetRssFeedsFetchFailure extends GetRssFeedsState {
  final String errorMessage;

  GetRssFeedsFetchFailure(this.errorMessage);
}

class GetRssFeedsCubit extends Cubit<GetRssFeedsState> {
  GetRssFeedsCubit() : super(GetRssFeedsInitial());

  int perPage = 20;
  int currentPage = 1;

  void getRssFeeds({
    required String languageCode,
    List<String>? sourceIds,
    List<String>? categoryIds,
    List<String>? subcategoryIds,
  }) async {
    try {
      emit(GetRssFeedsFetchInProgress());
      currentPage = 1;

      final body = {
        PER_PAGE: perPage.toString(),
        LANGUAGE_CODE: languageCode,
        if (sourceIds != null && sourceIds.isNotEmpty)
          SOURCE_IDS: sourceIds.join(","),
        if (categoryIds != null && categoryIds.isNotEmpty)
          CAT_IDS: categoryIds.join(","),
        if (subcategoryIds != null && subcategoryIds.isNotEmpty)
          SUBCAT_IDS: subcategoryIds.join(","),
        PAGE: currentPage.toString(),
      };

      final result =
          await Api.sendApiRequest(body: body, url: Api.getFeedItemsApi);

      if (!result[ERROR]) {
        final List<RSSFeedModel> feedsList = (result[DATA][DATA] as List)
            .map((e) => RSSFeedModel.fromJson(e))
            .toList();

        final int totalCount = result[DATA][TOTAL] ?? feedsList.length;
        final bool hasMore =
            feedsList.length >= perPage && feedsList.length < totalCount;

        emit(GetRssFeedsFetchSuccess(
          rssFeeds: feedsList,
          totalRssFeedsCount: totalCount,
          hasMoreFetchError: false,
          hasMore: hasMore,
        ));
      } else {
        emit(GetRssFeedsFetchFailure(result[MESSAGE]));
      }
    } catch (e) {
      emit(GetRssFeedsFetchFailure(e.toString()));
    }
  }

  bool hasMoreRssFeeds() {
    return (state is GetRssFeedsFetchSuccess)
        ? (state as GetRssFeedsFetchSuccess).hasMore
        : false;
  }

  void getMoreRssFeeds(
      {required String languageCode,
      List<String>? sourceIds,
      List<String>? categoryIds,
      List<String>? subcategoryIds}) async {
    if (state is GetRssFeedsFetchSuccess) {
      try {
        currentPage++;

        final body = {
          PER_PAGE: perPage.toString(),
          LANGUAGE_CODE: languageCode,
          if (sourceIds != null && sourceIds.isNotEmpty)
            SOURCE_IDS: sourceIds.join(","),
          if (categoryIds != null && categoryIds.isNotEmpty)
            CAT_IDS: categoryIds.join(","),
          if (subcategoryIds != null && subcategoryIds.isNotEmpty)
            SUBCAT_IDS: subcategoryIds.join(","),
          PAGE: currentPage.toString(),
        };

        final result =
            await Api.sendApiRequest(body: body, url: Api.getFeedItemsApi);

        if (!result[ERROR]) {
          final List<RSSFeedModel> newFeeds = (result[DATA][DATA] as List)
              .map((e) => RSSFeedModel.fromJson(e))
              .toList();

          final currentState = state as GetRssFeedsFetchSuccess;
          final List<RSSFeedModel> updatedFeeds =
              List.from(currentState.rssFeeds);
          updatedFeeds.addAll(newFeeds);

          final int totalCount = result[DATA][TOTAL] ?? updatedFeeds.length;
          final bool hasMore =
              newFeeds.length >= perPage && updatedFeeds.length < totalCount;

          emit(GetRssFeedsFetchSuccess(
            rssFeeds: updatedFeeds,
            totalRssFeedsCount: totalCount,
            hasMoreFetchError: false,
            hasMore: hasMore,
          ));
        } else {
          // On error, emit current state with error flag
          final currentState = state as GetRssFeedsFetchSuccess;
          currentPage--; // Revert page increment on error
          emit(GetRssFeedsFetchSuccess(
            rssFeeds: currentState.rssFeeds,
            totalRssFeedsCount: currentState.totalRssFeedsCount,
            hasMoreFetchError: true,
            hasMore: currentState.hasMore,
          ));
        }
      } catch (e) {
        // On exception, emit current state with error flag
        final currentState = state as GetRssFeedsFetchSuccess;
        currentPage--; // Revert page increment on error
        emit(GetRssFeedsFetchSuccess(
          rssFeeds: currentState.rssFeeds,
          totalRssFeedsCount: currentState.totalRssFeedsCount,
          hasMoreFetchError: true,
          hasMore: currentState.hasMore,
        ));
      }
    }
  }
}
