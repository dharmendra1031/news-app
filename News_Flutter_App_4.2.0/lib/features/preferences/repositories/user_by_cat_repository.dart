import 'package:news/features/preferences/repositories/user_by_cat_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class UserByCatRepository {
  static final UserByCatRepository _userByCatRepository =
      UserByCatRepository._internal();

  late UserByCatRemoteDataSource _userByCatRemoteDataSource;

  factory UserByCatRepository() {
    _userByCatRepository._userByCatRemoteDataSource =
        UserByCatRemoteDataSource();
    return _userByCatRepository;
  }

  UserByCatRepository._internal();

  Future<Map<String, dynamic>> getUserById() async {
    final result = await _userByCatRemoteDataSource.getUserById();

    return {"UserByCat": result[DATA]};
  }
}
