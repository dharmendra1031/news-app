import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/homepage/repositories/featured_section/section_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class SectionRepository {
  static final SectionRepository _sectionRepository =
      SectionRepository._internal();

  late SectionRemoteDataSource _sectionRemoteDataSource;

  factory SectionRepository() {
    _sectionRepository._sectionRemoteDataSource = SectionRemoteDataSource();
    return _sectionRepository;
  }

  SectionRepository._internal();

  Future<Map<String, dynamic>> getSection(
      {required String langCode,
      String? latitude,
      String? longitude,
      String? limit,
      String? offset,
      String? sectionOffset}) async {
    final result = await _sectionRemoteDataSource.getSections(
        langCode: langCode,
        latitude: latitude,
        longitude: longitude,
        limit: limit,
        offset: offset,
        sectionOffset: sectionOffset);

    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            "Section": (result[DATA][DATA] as List)
                .map((e) => FeatureSectionModel.fromJson(e))
                .toList(),
            TOTAL: result[DATA][TOTAL]
          };
  }
}
