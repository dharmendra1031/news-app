import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class SetNewsViewsDataRemoteDataSource {
  Future<dynamic> setNewsViews(
      {required String newsId, required bool isBreakingNews}) async {
    try {
      final body = {
        if (isBreakingNews) BR_NEWS_ID: newsId,
        if (!isBreakingNews) NEWS_ID: newsId
      };
      final result = await Api.sendApiRequest(
          body: body,
          url: (isBreakingNews)
              ? Api.setBreakingNewsViewApi
              : Api.setNewsViewApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
