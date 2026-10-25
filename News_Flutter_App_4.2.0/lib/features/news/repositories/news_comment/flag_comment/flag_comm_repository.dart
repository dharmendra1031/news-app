import 'package:news/features/news/repositories/news_comment/flag_comment/flag_comm_remote_data_source.dart';

class SetFlagRepository {
  static final SetFlagRepository _setFlagRepository =
      SetFlagRepository._internal();

  late SetFlagRemoteDataSource _setFlagRemoteDataSource;

  factory SetFlagRepository() {
    _setFlagRepository._setFlagRemoteDataSource = SetFlagRemoteDataSource();
    return _setFlagRepository;
  }

  SetFlagRepository._internal();

  Future<Map<String, dynamic>> setFlag(
      {required String commId,
      required String newsId,
      required String message}) async {
    final result = await _setFlagRemoteDataSource.setFlag(
        commId: commId, newsId: newsId, message: message);
    return result;
  }
}
