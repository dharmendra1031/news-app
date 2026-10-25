import 'package:news/features/news/models/tag_model.dart';
import 'package:news/features/add_edit_news/repositories/add_tag_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class AddTagRepository {
  static final AddTagRepository _addTagRepository =
      AddTagRepository._internal();

  late AddTagRemoteDataSource _addTagRemoteDataSource;

  factory AddTagRepository() {
    _addTagRepository._addTagRemoteDataSource = AddTagRemoteDataSource();
    return _addTagRepository;
  }

  AddTagRepository._internal();

  Future<TagModel> addTag(
      {required String langCode, required String tagName}) async {
    final result = await _addTagRemoteDataSource.addTag(
        langCode: langCode, tagName: tagName);

    // Expecting newly created tag data in DATA
    if (result[DATA] is List && (result[DATA] as List).isNotEmpty) {
      return TagModel.fromJson(result[DATA][0]);
    }

    // Fallback: try to parse result itself as a single tag object
    return TagModel.fromJson(result[DATA] ?? result);
  }
}
