import 'package:news/core/api/api.dart';

class UserByCatRemoteDataSource {
  Future<dynamic> getUserById() async {
    try {
      final result = await Api.sendApiRequest(body: {}, url: Api.getUserByIdApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
