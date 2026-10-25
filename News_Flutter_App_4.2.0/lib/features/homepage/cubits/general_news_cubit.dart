import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class GeneralNewsState {}

class GeneralNewsInitial extends GeneralNewsState {}

class GeneralNewsFetchInProgress extends GeneralNewsState {}

class GeneralNewsFetchSuccess extends GeneralNewsState {
  final List<NewsModel> generalNews;
  final int totalCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  GeneralNewsFetchSuccess(
      {required this.totalCount,
      required this.hasMoreFetchError,
      required this.hasMore,
      required this.generalNews});
}

class GeneralNewsFetchFailure extends GeneralNewsState {
  final String errorMessage;

  GeneralNewsFetchFailure(this.errorMessage);
}

class GeneralNewsCubit extends Cubit<GeneralNewsState> {
  GeneralNewsCubit() : super(GeneralNewsInitial());

  Future<dynamic> getGeneralNews(
      {required String langCode,
      String? latitude,
      String? longitude,
      int? offset,
      String? newsSlug}) async {
    emit(GeneralNewsInitial());
    try {
      final body = {LANGUAGE_CODE: langCode, LIMIT: 20};

      if (latitude != null && latitude != "null") body[LATITUDE] = latitude;
      if (longitude != null && longitude != "null") body[LONGITUDE] = longitude;
      if (offset != null) body[OFFSET] = offset;
      if (newsSlug != null && newsSlug != "null" && newsSlug.trim().isNotEmpty)
        body[SLUG] = newsSlug;
      // used in case of native link , details screen redirection

      final result = await Api.sendApiRequest(body: body, url: Api.getNewsApi);
      if (!result[ERROR]) {
        emit(GeneralNewsFetchSuccess(
            generalNews: (result[DATA][DATA] as List)
                .map((e) => NewsModel.fromJson(e))
                .toList(),
            totalCount: result[DATA][TOTAL],
            hasMoreFetchError: false,
            hasMore: result[DATA][DATA].length < result[DATA][TOTAL]));
      } else {
        emit(GeneralNewsFetchFailure(result[MESSAGE]));
      }
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  bool hasMoreGeneralNews() {
    return (state is GeneralNewsFetchSuccess)
        ? (state as GeneralNewsFetchSuccess).hasMore
        : false;
  }

  void getMoreGeneralNews(
      {required String langCode, String? latitude, String? longitude}) async {
    if (state is GeneralNewsFetchSuccess) {
      try {
        final result = await getGeneralNews(
            langCode: langCode,
            latitude: latitude,
            longitude: longitude,
            offset: (state as GeneralNewsFetchSuccess).generalNews.length);
        if (!result[ERROR]) {
          List<NewsModel> updatedResults =
              (state as GeneralNewsFetchSuccess).generalNews;
          updatedResults.addAll((result[DATA][DATA] as List)
              .map((e) => NewsModel.fromJson(e))
              .toList());
          emit(GeneralNewsFetchSuccess(
              generalNews: updatedResults,
              totalCount: result[DATA][TOTAL],
              hasMoreFetchError: false,
              hasMore: updatedResults.length < result[TOTAL]));
        } else {
          emit(GeneralNewsFetchFailure(result[MESSAGE]));
        }
      } catch (e) {
        emit(GeneralNewsFetchSuccess(
            generalNews: (state as GeneralNewsFetchSuccess).generalNews,
            hasMoreFetchError: true,
            totalCount: (state as GeneralNewsFetchSuccess).totalCount,
            hasMore: (state as GeneralNewsFetchSuccess).hasMore));
      }
    }
  }
}
