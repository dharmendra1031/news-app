import 'package:news/commons/repositories/get_user_by_id/get_user_by_id_data_source.dart';
import 'package:news/core/constants/strings.dart';

class GetUserByIdRepository {
  static final GetUserByIdRepository _getUserByIdRepository =
      GetUserByIdRepository._internal();

  late GetUserByIdRemoteDataSource _getUserByIdRemoteDataSource;

  factory GetUserByIdRepository() {
    _getUserByIdRepository._getUserByIdRemoteDataSource =
        GetUserByIdRemoteDataSource();
    return _getUserByIdRepository;
  }

  GetUserByIdRepository._internal();

  Future<Map<String, dynamic>> getUserById() async {
    final result = await _getUserByIdRemoteDataSource.getUserById();
    return result[DATA];
  }
}
