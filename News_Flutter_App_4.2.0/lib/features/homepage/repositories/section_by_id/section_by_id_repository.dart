import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/homepage/repositories/section_by_id/section_by_id_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class SectionByIdRepository {
  static final SectionByIdRepository _sectionByIdRepository =
      SectionByIdRepository._internal();

  late SectionByIdRemoteDataSource _sectionByIdRemoteDataSource;

  factory SectionByIdRepository() {
    _sectionByIdRepository._sectionByIdRemoteDataSource =
        SectionByIdRemoteDataSource();
    return _sectionByIdRepository;
  }

  SectionByIdRepository._internal();
  Future<Map<String, dynamic>> getSectionById(
      {required String langCode,
      required String sectionId,
      required String limit,
      required String offset,
      String? latitude,
      String? longitude}) async {
    final result = await _sectionByIdRemoteDataSource.getSectionById(
        langCode: langCode,
        sectionId: sectionId,
        latitude: latitude,
        longitude: longitude,
        limit: limit,
        offset: offset);

    if ((result[ERROR])) {
      return {ERROR: result[ERROR], MESSAGE: result[MESSAGE]};
    } else {
      return {
        ERROR: result[ERROR],
        DATA: (result[DATA][DATA] as List)
            .map((e) => FeatureSectionModel.fromJson(e))
            .toList()
      };
    }
  }
}
