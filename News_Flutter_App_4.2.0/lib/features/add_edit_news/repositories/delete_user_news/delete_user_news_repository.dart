import 'delete_user_news_remote_data_source.dart';

class DeleteUserNewsRepository {
  static final DeleteUserNewsRepository _deleteUserNewsRepository =
      DeleteUserNewsRepository._internal();
  late DeleteUserNewsRemoteDataSource _deleteUserNewsRemoteDataSource;

  factory DeleteUserNewsRepository() {
    _deleteUserNewsRepository._deleteUserNewsRemoteDataSource =
        DeleteUserNewsRemoteDataSource();
    return _deleteUserNewsRepository;
  }

  DeleteUserNewsRepository._internal();

  Future setDeleteUserNews({
    required String newsId,
  }) async {
    final result =
        await _deleteUserNewsRemoteDataSource.deleteUserNews(newsId: newsId);
    return result;
  }
}
