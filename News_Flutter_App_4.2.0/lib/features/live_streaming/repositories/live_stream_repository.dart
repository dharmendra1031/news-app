import 'package:news/features/live_streaming/models/live_streaming_model.dart';
import 'package:news/features/live_streaming/repositories/live_remote_data_source.dart';
import 'package:news/core/constants/strings.dart';

class LiveStreamRepository {
  static final LiveStreamRepository _liveStreamRepository =
      LiveStreamRepository._internal();

  late LiveStreamRemoteDataSource _liveStreamRemoteDataSource;

  factory LiveStreamRepository() {
    _liveStreamRepository._liveStreamRemoteDataSource =
        LiveStreamRemoteDataSource();
    return _liveStreamRepository;
  }

  LiveStreamRepository._internal();

  Future<dynamic> getLiveStream(
      {required String langCode,
      required String limit,
      required String offset}) async {
    final result = await _liveStreamRemoteDataSource.getLiveStreams(
        langCode: langCode, limit: limit, offset: offset);

    return (result[ERROR])
        ? {ERROR: result[ERROR], MESSAGE: result[MESSAGE]}
        : {
            ERROR: result[ERROR],
            TOTAL: result[DATA][TOTAL],
            "LiveStream": (result[DATA][DATA] as List)
                .map((e) => LiveStreamingModel.fromJson(e))
                .toList()
          };
  }
}
