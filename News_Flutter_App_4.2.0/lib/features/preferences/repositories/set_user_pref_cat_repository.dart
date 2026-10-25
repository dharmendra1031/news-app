import 'package:news/features/preferences/repositories/set_user_pref_cat_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class SetUserPrefCatRepository {
  static final SetUserPrefCatRepository _setUserPrefCatRepository =
      SetUserPrefCatRepository._internal();

  late SetUserPrefCatRemoteDataSource _setUserPrefCatRemoteDataSource;

  factory SetUserPrefCatRepository() {
    _setUserPrefCatRepository._setUserPrefCatRemoteDataSource =
        SetUserPrefCatRemoteDataSource();
    return _setUserPrefCatRepository;
  }

  SetUserPrefCatRepository._internal();

  Future<Map<String, dynamic>> setUserPrefCat({required String catId}) async {
    final result =
        await _setUserPrefCatRemoteDataSource.setUserPrefCat(catId: catId);

    return {"SetUserPrefCat": result[DATA]};
  }
}
