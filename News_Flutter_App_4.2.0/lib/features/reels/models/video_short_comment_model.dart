import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/constants/strings.dart';

class VideoShortCommentModel {
  final String? id;
  final String? videoShortsId;
  final String? userId;
  final String? comment;
  final bool? status;
  final UserAuthorModel? user;

  VideoShortCommentModel({
    this.id,
    this.videoShortsId,
    this.userId,
    this.comment,
    this.status,
    this.user,
  });

  factory VideoShortCommentModel.fromJson(Map<String, dynamic> json) {
    return VideoShortCommentModel(
      id: json[ID]?.toString(),
      videoShortsId: json[VIDEO_SHORTS_ID]?.toString(),
      userId: json[USER_ID]?.toString(),
      comment: json[COMMENT]?.toString(),
      status: _parseStatus(json[STATUS]),
      user: UserAuthorModel.fromJson(json[USER]),
    );
  }

  static bool? _parseStatus(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    final str = raw.toString().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return null;
  }
}
