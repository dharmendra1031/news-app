import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/videos/repositories/video_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class VideoRepository {
  static final VideoRepository _videoRepository = VideoRepository._internal();

  late VideoRemoteDataSource _videoRemoteDataSource;

  factory VideoRepository() {
    _videoRepository._videoRemoteDataSource = VideoRemoteDataSource();
    return _videoRepository;
  }

  VideoRepository._internal();

  Future<Map<String, dynamic>> getVideo(
      {required String offset,
      required String limit,
      required String langCode,
      String? latitude,
      String? longitude,
      String? slug}) async {
    final result = await _videoRemoteDataSource.getVideos(
        limit: limit,
        offset: offset,
        langCode: langCode,
        latitude: latitude,
        longitude: longitude,
        slug: slug);
    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            "total": result[DATA][TOTAL],
            "Video": (result[DATA][DATA] as List)
                .map((e) => NewsModel.fromVideos(e))
                .toList()
          };
  }
}
