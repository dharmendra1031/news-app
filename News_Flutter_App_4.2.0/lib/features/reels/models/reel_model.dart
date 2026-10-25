import 'package:news/core/constants/strings.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';

class ReelModel {
  final String? id;
  final String? languageId;
  final String? categoryId;
  final String? title;
  final String? slug;
  final String? videoUrl;
  final VideoType videoType;
  final String? description;
  final String? publishedDate;
  final bool? status;
  int viewsCount;
  int sharesCount;
  int commentsCount;
  int totalLikeCount;
  bool isLiked;
  bool isDisliked;

  ReelModel({
    this.id,
    this.languageId,
    this.categoryId,
    this.title,
    this.slug,
    this.videoUrl,
    this.videoType = VideoType.video_upload,
    this.description,
    this.publishedDate,
    this.status,
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.commentsCount = 0,
    this.totalLikeCount = 0,
    this.isLiked = false,
    this.isDisliked = false,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json[ID]?.toString(),
      languageId: json[LANGUAGE_ID]?.toString(),
      categoryId: json[CATEGORY_ID]?.toString(),
      title: json[TITLE]?.toString(),
      slug: json[SLUG]?.toString(),
      videoUrl: json[VIDEO_URL]?.toString(),
      videoType: _parseVideoType(json[VIDEO_TYPE]),
      description: json[DESCRIPTION]?.toString(),
      publishedDate: json[PUBLISHED_DATE]?.toString(),
      status: _parseBool(json[STATUS]),
      viewsCount: _parseInt(json[VIEWS_COUNT]),
      sharesCount: _parseInt(json[SHARES_COUNT]),
      commentsCount: _parseInt(json[COMMENT_COUNT]),
      totalLikeCount: _parseInt(json[TOTAL_LIKE_COUNT]),
      isLiked: _parseBool(json[IS_LIKED]) ?? false,
      isDisliked: _parseBool(json[IS_DISLIKED]) ?? false,
    );
  }

  /// True when the reel is a YouTube link rather than a file the panel hosts,
  /// so callers know the URL can't be handed to a plain video controller.
  bool get isYoutube =>
      videoType == VideoType.video_youtube || videoType == VideoType.url_youtube;

  /// Video shorts label their source differently from the rest of the panel:
  /// get_video_shorts sends `youtubelink` where the news/video sections send
  /// `video_youtube` (and podcasts send `youtube_link`), so the raw value is
  /// matched loosely rather than against the [VideoType] names alone.
  ///
  /// Panels older than the video_type field send uploads only, and an unknown
  /// type would leave [VideoPlayContainer] with no player to build, so anything
  /// still unrecognised falls back to the upload path.
  static VideoType _parseVideoType(dynamic raw) {
    final type = videoTypeFromString(raw?.toString());
    if (type != VideoType.unknown) return type;

    final normalised =
        raw?.toString().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '') ?? '';
    if (normalised.contains('youtube')) return VideoType.video_youtube;
    if (normalised.contains('other')) return VideoType.video_other;
    return VideoType.video_upload;
  }

  static int _parseInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  static bool? _parseBool(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    final str = raw.toString().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return null;
  }
}
