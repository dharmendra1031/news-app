import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class GetUserDraftedNewsState {}

class GetUserDraftedNewsInitial extends GetUserDraftedNewsState {}

class GetUserDraftedNewsFetchInProgress extends GetUserDraftedNewsState {}

class GetUserDraftedNewsFetchSuccess extends GetUserDraftedNewsState {
  final List<NewsModel> GetUserDraftedNews;
  final int totalGetUserDraftedNewsCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  GetUserDraftedNewsFetchSuccess(
      {required this.GetUserDraftedNews,
      required this.totalGetUserDraftedNewsCount,
      required this.hasMoreFetchError,
      required this.hasMore});
}

class GetUserDraftedNewsFetchFailure extends GetUserDraftedNewsState {
  final String errorMessage;

  GetUserDraftedNewsFetchFailure(this.errorMessage);
}

class GetUserDraftedNewsCubit extends Cubit<GetUserDraftedNewsState> {
  GetUserDraftedNewsCubit() : super(GetUserDraftedNewsInitial());

  void getUserDraftedNews({int? userId}) async {
    try {
      emit(GetUserDraftedNewsFetchInProgress());
      final apiUrl = Api.getDraftNewsApi;

      final body = {
        AUTHOR_ID: userId,
        PAGE: "1",
        PER_PAGE: limitOfAPIData.toString(),
      };

      final result = await Api.sendApiRequest(body: body, url: apiUrl);
      (!result[ERROR] ||
              result[DATA][NEWS][DATA].isNotEmpty ||
              result[DATA][NEWS][TOTAL] > 0)
          ? emit(GetUserDraftedNewsFetchSuccess(
              GetUserDraftedNews: (result[DATA][NEWS][DATA] as List)
                  .map((e) => NewsModel.fromJson(e))
                  .toList(),
              totalGetUserDraftedNewsCount: result[DATA][NEWS][TOTAL],
              hasMoreFetchError: false,
              hasMore: (result[DATA][NEWS][DATA] as List).length <
                  result[DATA][NEWS][TOTAL]))
          : emit(GetUserDraftedNewsFetchFailure(result[MESSAGE]));
    } catch (e) {
      emit(GetUserDraftedNewsFetchFailure(e.toString()));
    }
  }

  bool hasMoreGetUserDraftedNews() {
    return (state is GetUserDraftedNewsFetchSuccess)
        ? (state as GetUserDraftedNewsFetchSuccess).hasMore
        : false;
  }

  void getMoreUserDraftedNews({int? userId}) async {
    if (state is GetUserDraftedNewsFetchSuccess) {
      try {
        final currentState = state as GetUserDraftedNewsFetchSuccess;
        final nextPage =
            (currentState.GetUserDraftedNews.length ~/ limitOfAPIData) + 1;

        final result = await Api.sendApiRequest(
          body: {
            AUTHOR_ID: userId,
            PAGE: nextPage.toString(),
            PER_PAGE: limitOfAPIData.toString(),
          },
          url: Api.getDraftNewsApi,
        );

        final fetchedNews = (result[DATA][NEWS][DATA] as List)
            .map((e) => NewsModel.fromJson(e))
            .toList();
        final updatedResults = [
          ...currentState.GetUserDraftedNews,
          ...fetchedNews
        ];
        final totalCount = result[DATA][NEWS][TOTAL];

        emit(GetUserDraftedNewsFetchSuccess(
            GetUserDraftedNews: updatedResults,
            totalGetUserDraftedNewsCount: totalCount,
            hasMoreFetchError: false,
            hasMore: updatedResults.length < totalCount));
      } catch (e) {
        emit(GetUserDraftedNewsFetchSuccess(
            GetUserDraftedNews:
                (state as GetUserDraftedNewsFetchSuccess).GetUserDraftedNews,
            hasMoreFetchError: true,
            totalGetUserDraftedNewsCount:
                (state as GetUserDraftedNewsFetchSuccess)
                    .totalGetUserDraftedNewsCount,
            hasMore: (state as GetUserDraftedNewsFetchSuccess).hasMore));
      }
    }
  }

  void deleteNews(int index) {
    if (state is GetUserDraftedNewsFetchSuccess) {
      List<NewsModel> newsList = List.from(
          (state as GetUserDraftedNewsFetchSuccess).GetUserDraftedNews)
        ..removeAt(index);

      emit(GetUserDraftedNewsFetchSuccess(
          GetUserDraftedNews: newsList,
          hasMore: (state as GetUserDraftedNewsFetchSuccess).hasMore,
          hasMoreFetchError: false,
          totalGetUserDraftedNewsCount:
              (state as GetUserDraftedNewsFetchSuccess)
                      .totalGetUserDraftedNewsCount -
                  1));
    }
  }

  void deleteImageId(int index) {
    if (state is GetUserDraftedNewsFetchSuccess) {
      List<NewsModel> newsList =
          (state as GetUserDraftedNewsFetchSuccess).GetUserDraftedNews;

      newsList[index].imageDataList!.removeAt(index);

      emit(GetUserDraftedNewsFetchSuccess(
          GetUserDraftedNews: newsList,
          hasMore: (state as GetUserDraftedNewsFetchSuccess).hasMore,
          hasMoreFetchError: false,
          totalGetUserDraftedNewsCount:
              (state as GetUserDraftedNewsFetchSuccess)
                  .totalGetUserDraftedNewsCount));
    }
  }
}
