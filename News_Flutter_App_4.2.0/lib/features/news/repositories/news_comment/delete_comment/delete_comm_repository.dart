import 'package:news/features/news/repositories/news_comment/delete_comment/delete_comm_data_source.dart';

class DeleteCommRepository {
  static final DeleteCommRepository _deleteCommRepository =
      DeleteCommRepository._internal();
  late DeleteCommRemoteDataSource _deleteCommRemoteDataSource;

  factory DeleteCommRepository() {
    _deleteCommRepository._deleteCommRemoteDataSource =
        DeleteCommRemoteDataSource();
    return _deleteCommRepository;
  }

  DeleteCommRepository._internal();

  Future setDeleteComm({required String commId}) async {
    final result = await _deleteCommRemoteDataSource.deleteComm(commId: commId);
    return result;
  }
}
