// The single entry point for everything podcast. Every write goes through
// _writeMessage because a rejected save arrives here looking like a success.

import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/authentication/repositories/auth_local_data_source.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/playable_audio.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/features/podcast/repositories/podcast_download_data_source.dart';
import 'package:news/features/podcast/repositories/podcast_remote_data_source.dart';

class PodcastChannelEpisodes {
  final PodcastModel? podcast;
  final List<EpisodeModel> episodes;

  const PodcastChannelEpisodes({this.podcast, this.episodes = const []});
}

class BookmarkedEpisode {
  final EpisodeModel episode;
  final PodcastModel? podcast;

  const BookmarkedEpisode({required this.episode, this.podcast});
}

class ListenedEpisode {
  final EpisodeModel episode;
  final PodcastModel? podcast;

  const ListenedEpisode({required this.episode, this.podcast});

  int get positionMs => (episode.listeningHistory?.listenedSeconds ?? 0) * 1000;

  int get durationMs => episode.durationSeconds * 1000;

  bool get completed => episode.listeningHistory?.completed ?? false;

  double get progress => episode.listeningProgress ?? 0;
}

class PodcastRepository {
  static final PodcastRepository _instance = PodcastRepository._internal();

  late final PodcastDownloadDataSource _downloads;
  late final PodcastRemoteDataSource _remote;

  static const int _historyPushIntervalSeconds = 30;

  static const double _completedThreshold = 0.95;

  static const int _pageSize = 50;
  static const int _maxPages = 40;

  final Map<String, ({DateTime at, bool completed})> _lastHistoryPush = {};

  final Map<String, ({int positionMs, bool completed})> _positions = {};

  factory PodcastRepository() => _instance;

  PodcastRepository._internal() {
    _downloads = PodcastDownloadDataSource();
    _remote = PodcastRemoteDataSource();
  }

  static bool isCompleted(int positionMs, int durationMs) =>
      durationMs > 0 && positionMs / durationMs >= _completedThreshold;

  Future<List<PodcastModel>> getPodcasts({
    String? search,
    String type = PodcastRemoteDataSource.typeAll,
  }) async {
    // The API never reports a total, so keep asking for pages until one comes
    // back short — that page is the last one.
    final List<PodcastModel> podcasts = [];
    for (int page = 0; page < _maxPages; page++) {
      final result = await _remote.getPodcasts(
        search: search,
        type: type,
        offset: podcasts.length.toString(),
        limit: _pageSize.toString(),
      );
      final data = result[DATA] as Map? ?? const {};
      final rows = (data[DATA] as List? ?? const [])
          .map((e) => PodcastModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      podcasts.addAll(rows);
      if (rows.length < _pageSize) break;
    }
    return podcasts;
  }

  Future<List<PodcastModel>> getMyPodcasts({
    String type = PodcastRemoteDataSource.myTypeAll,
    String? search,
    String? offset,
    String? limit,
  }) async {
    final result = await _remote.getMyPodcasts(
        type: type, search: search, offset: offset, limit: limit);
    final data = result[DATA] as Map? ?? const {};
    return (data[DATA] as List? ?? const [])
        .map((e) => PodcastModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<({List<PodcastModel> published, List<PodcastModel> drafts})>
      getMyPodcastsByType({String? search}) async {
    final lists = await Future.wait([
      getMyPodcasts(type: PodcastRemoteDataSource.myTypeAll, search: search),
      getMyPodcasts(type: PodcastRemoteDataSource.myTypeDraft, search: search),
    ]);
    return (published: lists[0], drafts: lists[1]);
  }

  Future<PodcastChannelEpisodes> getEpisodes({
    required String podcastSlug,
    required String offset,
    required String limit,
    String type = PodcastRemoteDataSource.typeAll,
    bool isAuthorCheck = false,
  }) async {
    final result = await _remote.getEpisodes(
        podcastSlug: podcastSlug,
        offset: offset,
        limit: limit,
        type: type,
        isAuthorCheck: isAuthorCheck);
    final data = result[DATA] as Map? ?? const {};
    if (data.isEmpty) return const PodcastChannelEpisodes();
    final channel = PodcastChannelEpisodes(
      podcast: PodcastModel.fromJson(Map<String, dynamic>.from(data)),
      episodes: (data[EPISODES] as List? ?? const [])
          .map((e) => EpisodeModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
    _cacheListeningPositions(channel.episodes);
    return channel;
  }

  Future<({List<EpisodeModel> published, List<EpisodeModel> drafts})>
      getMyEpisodesByType({required PodcastModel podcast}) async {
    final slug = podcast.slug ?? '';
    if (slug.isEmpty) {
      return (published: <EpisodeModel>[], drafts: <EpisodeModel>[]);
    }
    final lists = await Future.wait([
      _allEpisodesOfType(slug: slug, type: PodcastRemoteDataSource.typeAll),
      _allEpisodesOfType(slug: slug, type: PodcastRemoteDataSource.typeDraft),
    ]);
    return (published: lists[0], drafts: lists[1]);
  }

  Future<List<EpisodeModel>> _allEpisodesOfType({
    required String slug,
    required String type,
  }) async {
    final List<EpisodeModel> episodes = [];
    for (int page = 0; page < _maxPages; page++) {
      final result = await getEpisodes(
        podcastSlug: slug,
        offset: episodes.length.toString(),
        limit: _pageSize.toString(),
        type: type,
        isAuthorCheck: true,
      );
      episodes.addAll(result.episodes);
      if (result.episodes.length < _pageSize) break;
    }
    return episodes;
  }

  Future<String?> setEpisodeBookmark({
    required String podcastId,
    required String episodeId,
    required bool bookmark,
  }) =>
      _toggleFailure(() => _remote.bookmarkEpisode(
            podcastId: podcastId,
            episodeId: episodeId,
            status: bookmark ? "1" : "0",
          ));

  // Null when the server accepted the toggle, otherwise the reason — the API's
  // own message, so the caller can show it as is.
  Future<String?> _toggleFailure(Future<dynamic> Function() request) async {
    try {
      final result = await request();
      if (result[ERROR] == true || result[ERROR]?.toString() == 'true') {
        final message = result[MESSAGE]?.toString() ?? '';
        return message.isEmpty ? ErrorMessageKeys.defaultErrorMessage : message;
      }
      return null;
    } catch (e) {
      // The offline SocketException reaches here stringified with its type.
      final message = e.toString();
      if (message.contains(ErrorMessageKeys.noInternet)) {
        return ErrorMessageKeys.noInternet;
      }
      return message.isEmpty ? ErrorMessageKeys.defaultErrorMessage : message;
    }
  }

  Future<List<BookmarkedEpisode>> getBookmarkedEpisodes() async {
    final episodes =
        await _myEpisodes(type: PodcastRemoteDataSource.typeBookmark);
    return episodes.map((e) => BookmarkedEpisode(episode: e)).toList();
  }

  Future<List<EpisodeModel>> _myEpisodes({required String type}) async {
    if (!_isLoggedIn) return const [];
    final List<EpisodeModel> episodes = [];
    for (int page = 0; page < _maxPages; page++) {
      final result = await _remote.getMyEpisodes(
        type: type,
        offset: episodes.length.toString(),
        limit: _pageSize.toString(),
      );
      final data = result[DATA] as Map? ?? const {};
      final rows = (data[EPISODES] as List? ?? const [])
          .map((e) => EpisodeModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      episodes.addAll(rows);
      if (rows.length < _pageSize) break;
    }
    _cacheListeningPositions(episodes);
    return episodes;
  }

  Future<String?> setFollowPodcast({
    required String podcastId,
    required bool follow,
  }) =>
      _toggleFailure(() => _remote.followPodcast(
          podcastId: podcastId, status: follow ? "1" : "0"));

  Future<String> savePodcast({
    String? podcastId,
    required String title,
    required String slug,
    required String description,
    required DateTime publishDate,
    required bool isDraft,
    String metaTitle = '',
    String metaDescription = '',
    String metaKeyword = '',
    String schemaMarkup = '',
    File? image,
  }) async {
    final result = await _remote.savePodcast(
      podcastId: podcastId,
      title: title,
      slug: slug,
      description: description,
      publishedDate: DateFormat('yyyy-MM-dd').format(publishDate),
      draft: isDraft ? "1" : "0",
      metaTitle: metaTitle,
      metaDescription: metaDescription,
      metaKeyword: _commaSeparated(metaKeyword),
      schemaMarkup: schemaMarkup,
      image: image,
    );
    return _writeMessage(result);
  }

  static String _commaSeparated(String raw) => raw
      .split(',')
      .map((keyword) => keyword.trim())
      .where((keyword) => keyword.isNotEmpty)
      .join(',');

  Future<String> deletePodcast({required String podcastId}) async {
    final result = await _remote.deletePodcast(podcastId: podcastId);
    return _writeMessage(result);
  }

  Future<String> saveEpisode({
    String? episodeId,
    required String podcastId,
    required String episodeNo,
    required String title,
    required String slug,
    required String description,
    required DateTime publishDate,
    required String sourceType,
    required bool isDraft,
    String? audioUrl,
    File? audioFile,
    File? image,
  }) async {
    final result = await _remote.saveEpisode(
      episodeId: episodeId,
      podcastId: podcastId,
      episodeNo: episodeNo,
      title: title,
      slug: slug,
      description: description,
      publishedDate: DateFormat('yyyy-MM-dd').format(publishDate),
      sourceType: sourceType,
      draft: isDraft ? "1" : "0",
      audioUrl: audioUrl,
      audioFile: audioFile,
      image: image,
    );
    return _writeMessage(result);
  }

  Future<String> deleteEpisode({required String episodeId}) async {
    final result = await _remote.deleteEpisode(episodeId: episodeId);
    return _writeMessage(result);
  }

  String _writeMessage(Map<String, dynamic> result) {
    final message = result[MESSAGE]?.toString() ?? '';
    if (result[ERROR] == true || result[ERROR]?.toString() == 'true') {
      throw ApiException(message);
    }
    return message;
  }

  PlayableAudio resolvePlaybackSource(PlayableAudio audio) =>
      _downloads.resolveSource(audio);

  Future<void> ensureNotificationPermission() =>
      _downloads.ensureNotificationPermission();

  Future<void> ensureDownloadPermissions() =>
      _downloads.ensureDownloadPermissions();

  int getResumePositionMs(String id) {
    final position = _positions[id];
    if (position == null || position.completed) return 0;
    return position.positionMs;
  }

  Future<void> saveProgress({
    required PlayableAudio audio,
    required int positionMs,
    required int durationMs,
    bool immediate = false,
  }) async {
    if (audio.id.isEmpty) return;
    _positions[audio.id] = (
      positionMs: positionMs,
      completed: isCompleted(positionMs, durationMs),
    );
    unawaited(_pushListeningHistory(
      audio: audio,
      positionMs: positionMs,
      durationMs: durationMs,
      immediate: immediate,
    ));
  }

  Future<void> _pushListeningHistory({
    required PlayableAudio audio,
    required int positionMs,
    required int durationMs,
    required bool immediate,
  }) async {
    final episodeId = audio.id;
    if (episodeId.isEmpty || !_isLoggedIn) return;

    final completed = isCompleted(positionMs, durationMs);
    final last = _lastHistoryPush[episodeId];
    final now = DateTime.now();
    final due = immediate ||
        last == null ||
        (completed && !last.completed) ||
        now.difference(last.at).inSeconds >= _historyPushIntervalSeconds;
    if (!due) return;

    _lastHistoryPush[episodeId] = (at: now, completed: completed);
    try {
      await _remote.updateEpisodeListeningHistory(
        episodeId: episodeId,
        listenedSeconds: (positionMs / 1000).round().toString(),
        completed: completed ? "1" : "0",
      );
    } catch (_) {
      _lastHistoryPush[episodeId] = (at: now, completed: false);
    }
  }

  Future<List<ListenedEpisode>> getListeningHistory() async {
    final episodes =
        await _myEpisodes(type: PodcastRemoteDataSource.typeHistory);
    return episodes.map((e) => ListenedEpisode(episode: e)).toList();
  }

  void _cacheListeningPositions(List<EpisodeModel> episodes) {
    for (final episode in episodes) {
      final history = episode.listeningHistory;
      final id = episode.id ?? '';
      if (history == null || id.isEmpty) continue;
      _positions[id] = (
        positionMs: history.listenedSeconds * 1000,
        completed: history.completed ||
            isCompleted(history.listenedSeconds * 1000,
                episode.durationSeconds * 1000),
      );
    }
  }

  bool get _isLoggedIn =>
      (AuthLocalDataSource().checkIsAuth() ?? false) &&
      AuthLocalDataSource().getJWTtoken().trim().isNotEmpty;

  Future<bool> download(PlayableAudio audio) => _downloads.enqueue(audio);

  bool isDownloaded(String id) => _downloads.isDownloaded(id);
}
