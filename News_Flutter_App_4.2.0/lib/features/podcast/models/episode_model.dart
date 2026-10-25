// One podcast episode from `get_episode` / `my_episodes`. Also converts itself to
// tile data and to PlayableAudio, so no screen builds those by hand.

import 'package:news/core/constants/strings.dart';
import 'package:news/features/podcast/models/playable_audio.dart';
import 'package:news/features/podcast/screens/widgets/episode_list_tile.dart';

class EpisodeListeningHistory {
  final int listenedSeconds;
  final bool completed;

  const EpisodeListeningHistory({
    this.listenedSeconds = 0,
    this.completed = false,
  });

  factory EpisodeListeningHistory.fromJson(Map<String, dynamic> json) {
    return EpisodeListeningHistory(
      listenedSeconds: EpisodeModel._parseInt(json[LISTENED_SECONDS]),
      completed: EpisodeModel._parseBool(json[COMPLETED]),
    );
  }
}

class EpisodeModel {
  final String? id;
  final String? podcastId;
  final int episodeNo;

  final String? slug;
  final String? title;
  final String? description;
  final String? image;
  final String? sourceType;
  final String? audioUrl;
  final int durationSeconds;
  final String? publishedAt;

  final bool isActive;

  final bool isDraft;

  bool isBookmarked;

  final EpisodeListeningHistory? listeningHistory;

  EpisodeModel({
    this.id,
    this.podcastId,
    this.episodeNo = 0,
    this.slug,
    this.title,
    this.description,
    this.image,
    this.sourceType,
    this.audioUrl,
    this.durationSeconds = 0,
    this.publishedAt,
    this.isActive = true,
    this.isDraft = false,
    this.isBookmarked = false,
    this.listeningHistory,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json[ID]?.toString(),
      podcastId: json[PODCAST_ID]?.toString(),
      episodeNo: _parseInt(json[EPISODE_NO]),
      slug: json[SLUG]?.toString(),
      title: json[TITLE]?.toString(),
      description: json[DESCRIPTION]?.toString(),
      image: json[IMAGE]?.toString(),
      sourceType: json[SOURCE_TYPE]?.toString(),
      audioUrl: json[AUDIO_URL]?.toString(),
      durationSeconds: _parseInt(json[DURATION_SECONDS]),
      publishedAt: json[PUBLISHED_AT]?.toString(),
      isActive: json[STATUS] == null ? true : _parseBool(json[STATUS]),
      isDraft: _parseBool(json[DRAFT]),
      isBookmarked: _parseBool(json[IS_BOOKMARKED]),
      listeningHistory: (json[LISTENING_HISTORY] is Map)
          ? EpisodeListeningHistory.fromJson(
              Map<String, dynamic>.from(json[LISTENING_HISTORY]))
          : null,
    );
  }

  EpisodeListTileData toTileData({
    String? fallbackImage,
    String? episodeLabel,
    String? artist,
    double? progress,
    bool? isBookmarked,
  }) {
    return EpisodeListTileData(
      imageUrl: (image?.isNotEmpty ?? false) ? image! : (fallbackImage ?? ''),
      episodeLabel: episodeLabel,
      title: title ?? '',
      duration: durationLabel,
      date: dateLabel,
      progress: progress,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      audio: toPlayableAudio(fallbackImage: fallbackImage, artist: artist),
      description: description,
      isDeactivated: !isActive,
    );
  }

  PlayableAudio toPlayableAudio({String? fallbackImage, String? artist}) {
    return PlayableAudio(
      id: id ?? '',
      url: audioUrl ?? '',
      title: title ?? '',
      artist: artist,
      artUri: (image?.isNotEmpty ?? false) ? image : fallbackImage,
      podcastId: podcastId,
      sourceType: sourceType,
      episodeNo: episodeNo,
      durationSeconds: durationSeconds,
      publishedAt: publishedAt,
    );
  }

  /// How much of this episode has been listened to, or null when the row came
  /// back without any listening history — every list that shows a resume bar
  /// reads it from here, so History and Bookmark agree on the same episode.
  /// A finished episode reads as a full bar even when the last saved position
  /// stopped a few seconds short of the end.
  double? get listeningProgress {
    final history = listeningHistory;
    if (history == null) return null;
    if (history.completed) return 1;
    if (durationSeconds <= 0) return null;
    return (history.listenedSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  String get durationLabel => PlayableAudio.formatDuration(durationSeconds);

  String get dateLabel => PlayableAudio.formatDate(publishedAt);

  static int _parseInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    final str = raw?.toString().toLowerCase();
    return str == 'true' || str == '1';
  }
}
