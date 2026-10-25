import 'delete_image_id_remote_data_source.dart';

class DeleteImageRepository {
  static final DeleteImageRepository _deleteImageRepository = DeleteImageRepository._internal();
  late DeleteImageRemoteDataSource _deleteImageRemoteDataSource;

  factory DeleteImageRepository() {
    _deleteImageRepository._deleteImageRemoteDataSource = DeleteImageRemoteDataSource();
    return _deleteImageRepository;
  }

  DeleteImageRepository._internal();

  Future setDeleteImage({
    required String imageId,
  }) async {
    final result = await _deleteImageRemoteDataSource.deleteImage(imageId: imageId);
    return result;
  }
}
