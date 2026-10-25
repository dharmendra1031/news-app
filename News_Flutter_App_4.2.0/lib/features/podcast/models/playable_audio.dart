// The only audio type the player, downloader and Hive storage understand — it
// knows nothing about the podcast API, which keeps that layer reusable.

import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:news/core/constants/hive_box_keys.dart';

class PlayableAudio {
  final String id;

  final String url;

  final String title;

  final String? artist;

  final String? album;

  final String? artUri;

  final String? localFilePath;

  final String? podcastId;

  final String? sourceType;

  final int episodeNo;

  final int durationSeconds;

  final String? publishedAt;

  const PlayableAudio({
    required this.id,
    required this.url,
    required this.title,
    this.artist,
    this.album,
    this.artUri,
    this.localFilePath,
    this.podcastId,
    this.sourceType,
    this.episodeNo = 0,
    this.durationSeconds = 0,
    this.publishedAt,
  });

  String? get episodeLabel => episodeNo > 0 ? 'Episode - $episodeNo' : null;

  String get durationLabel => formatDuration(durationSeconds);

  String get dateLabel => formatDate(publishedAt);

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final minutes = (seconds / 60).round();
    return '${minutes < 1 ? 1 : minutes} min';
  }

  static String formatDate(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) return '';
    final parsed = DateTime.tryParse(isoTimestamp);
    if (parsed == null) return isoTimestamp.split('T').first.split(' ').first;
    try {
      final langCode = Hive.box(settingsBoxKey).get(currentLanguageCodeKey);
      return DateFormat('dd MMMM yyyy', langCode).format(parsed);
    } catch (_) {
      return DateFormat('dd MMMM yyyy').format(parsed);
    }
  }

  bool get hasLocalFile => localFilePath != null && localFilePath!.isNotEmpty;

  String get playbackSource => hasLocalFile ? localFilePath! : url;

  bool get isYoutubeSource {
    final type = sourceType?.trim().toLowerCase();
    if (type != null && type.isNotEmpty) return type == 'youtube_link';
    final u = url.toLowerCase();
    return u.contains('youtube.com/') || u.contains('youtu.be/');
  }

  bool get isDownloadable => url.isNotEmpty && !isYoutubeSource;

  PlayableAudio copyWith({
    String? url,
    String? localFilePath,
  }) {
    return PlayableAudio(
      id: id,
      url: url ?? this.url,
      title: title,
      artist: artist,
      album: album,
      artUri: artUri,
      localFilePath: localFilePath ?? this.localFilePath,
      podcastId: podcastId,
      sourceType: sourceType,
      episodeNo: episodeNo,
      durationSeconds: durationSeconds,
      publishedAt: publishedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'artist': artist,
      'album': album,
      'artUri': artUri,
      'localFilePath': localFilePath,
      'podcastId': podcastId,
      'sourceType': sourceType,
      'episodeNo': episodeNo,
      'durationSeconds': durationSeconds,
      'publishedAt': publishedAt,
    };
  }

  factory PlayableAudio.fromMap(Map<dynamic, dynamic> map) {
    return PlayableAudio(
      id: map['id']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString(),
      album: map['album']?.toString(),
      artUri: map['artUri']?.toString(),
      localFilePath: map['localFilePath']?.toString(),
      podcastId: map['podcastId']?.toString(),
      sourceType: map['sourceType']?.toString(),
      episodeNo: (map['episodeNo'] as num?)?.toInt() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      publishedAt: map['publishedAt']?.toString(),
    );
  }
}
