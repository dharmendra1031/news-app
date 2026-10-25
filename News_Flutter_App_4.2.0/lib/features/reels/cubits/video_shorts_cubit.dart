import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/reels/models/reel_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

/// Bold yellow, the same highlight the cURL logger uses, so the reels calls
/// stand out in the console.
void reelsLog(String message) =>
    debugPrint('\x1B[1m\x1B[33m[Reels] $message\x1B[0m');

abstract class VideoShortsState {}

class VideoShortsInitial extends VideoShortsState {}

class VideoShortsFetchInProgress extends VideoShortsState {}

class VideoShortsFetchSuccess extends VideoShortsState {
  final List<ReelModel> videoShorts;
  final int totalCount;

  VideoShortsFetchSuccess({
    required this.videoShorts,
    required this.totalCount,
  });
}

class VideoShortsFetchFailure extends VideoShortsState {
  final String errorMessage;

  VideoShortsFetchFailure(this.errorMessage);
}

class VideoShortsCubit extends Cubit<VideoShortsState> {
  VideoShortsCubit() : super(VideoShortsInitial());

  int _offset = 0;
  final int _limit = 10;

  bool _isLoading = false;
  int _totalCount = 0;

  final List<ReelModel> _videos = [];

  List<ReelModel> _parseVideoShortsList(dynamic raw) {
    if (raw == null) return [];

    List<dynamic> items = [];
    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map[DATA] is List) {
        items = map[DATA] as List;
      } else if (map[DATA] is Map) {
        final inner = Map<String, dynamic>.from(map[DATA]);
        if (inner[DATA] is List) {
          items = inner[DATA] as List;
        } else if (inner[NEWS] is List) {
          items = inner[NEWS] as List;
        }
      } else if (map[NEWS] is List) {
        items = map[NEWS] as List;
      }
    }

    return items
        .whereType<Map>()
        .map((e) => ReelModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  int _parseTotal(dynamic raw, int fallback) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map[TOTAL] != null) {
        return int.tryParse(map[TOTAL].toString()) ?? fallback;
      }
      if (map[DATA] is Map) {
        final inner = Map<String, dynamic>.from(map[DATA]);
        if (inner[TOTAL] != null) {
          return int.tryParse(inner[TOTAL].toString()) ?? fallback;
        }
      }
    }
    return fallback;
  }

  Future<void> getVideoShorts({
    required String langCode,
    String? slug,
    bool loadMore = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      if (!loadMore) {
        _offset = 0;
        _videos.clear();
        emit(VideoShortsFetchInProgress());
      }

      final body = <String, dynamic>{
        LANGUAGE_CODE: langCode,
        LIMIT: _limit.toString(),
        OFFSET: _offset.toString(),
      };

      if (slug != null && slug != 'null' && slug.trim().isNotEmpty) {
        body[SLUG] = slug.split('slug=').last.split('&').first;
      }

      reelsLog('${Api.getVideoShortsApi} request: $body');

      final result = await Api.sendApiRequest(
        body: body,
        url: Api.getVideoShortsApi,
      );

      if (result[ERROR] == true) {
        emit(VideoShortsFetchFailure(result[MESSAGE]?.toString() ?? ""));
        return;
      }

      final newVideos = _parseVideoShortsList(result[DATA]);

      _totalCount = _parseTotal(result[DATA], newVideos.length);

      reelsLog('${Api.getVideoShortsApi} response: '
          '${newVideos.length} reels, total $_totalCount, '
          'ids ${newVideos.map((e) => e.id).toList()}');

      _videos.addAll(newVideos);

      _offset += newVideos.length;

      emit(
        VideoShortsFetchSuccess(
          videoShorts: List.from(_videos),
          totalCount: _totalCount,
        ),
      );
    } on ApiException catch (e) {
      emit(VideoShortsFetchFailure(e.errorMessage));
    } catch (e) {
      emit(VideoShortsFetchFailure(e.toString()));
    } finally {
      _isLoading = false;
    }
  }

  void loadNextBatch(String langCode, {String? slug}) {
    if (_offset >= _totalCount) {
      _offset = 0;
    }

    getVideoShorts(
      langCode: langCode,
      slug: slug,
      loadMore: true,
    );
  }

  /// One page of the reels API. Never throws: a failure comes back as [error],
  /// so the caller can still use the other page it asked for.
  Future<_ReelsPage> _fetchPage({
    required String langCode,
    String? slug,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      LANGUAGE_CODE: langCode,
      LIMIT: _limit.toString(),
      OFFSET: offset.toString(),
    };
    if (slug != null && slug.trim().isNotEmpty) {
      body[SLUG] = slug.split('slug=').last.split('&').first;
    }

    try {
      final result = await Api.sendApiRequest(
        body: body,
        url: Api.getVideoShortsApi,
      );
      if (result[ERROR] == true) {
        return _ReelsPage.failed(result[MESSAGE]?.toString() ?? "");
      }
      final reels = _parseVideoShortsList(result[DATA]);
      return _ReelsPage(reels, _parseTotal(result[DATA], reels.length));
    } on ApiException catch (e) {
      return _ReelsPage.failed(e.errorMessage);
    } catch (e) {
      return _ReelsPage.failed(e.toString());
    }
  }

  /// Opens the list on the reel a share link points to, followed by the regular
  /// feed. `get_video_shorts` with a slug returns only that one reel, so the
  /// feed is fetched alongside it and the two are joined here. The list, offset
  /// and total kept by this cubit are set to match what is shown, which the
  /// paging in [loadNextBatch] relies on.
  ///
  /// The shared reel is looked up in [langCode] (the language the link was made
  /// in); the feed after it is the reader's own, in [feedLangCode] — the same
  /// language every later page is fetched in.
  ///
  /// A reel that can't be loaded (removed, or shared from another backend) is not
  /// fatal: the list opens on the regular feed instead. Returns false only when
  /// nothing at all could be loaded.
  Future<bool> loadSharedReel({
    required String langCode,
    required String feedLangCode,
    required String slug,
  }) async {
    // A feed load already running (the tab's own, or a swipe's next page) would
    // land on top of this one, so let it finish first. Capped, so a stalled
    // request can't hold the link up forever.
    for (var i = 0; _isLoading && i < 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _isLoading = true;

    try {
      _offset = 0;
      _totalCount = 0;
      _videos.clear();
      emit(VideoShortsFetchInProgress());

      final pages = await Future.wait([
        _fetchPage(langCode: langCode, slug: slug),
        _fetchPage(langCode: feedLangCode),
      ]);
      final shared = pages[0];
      final feed = pages[1];

      reelsLog('shared reel "$slug": ${shared.reels.length} found'
          '${shared.error != null ? ' (${shared.error})' : ''}; feed: '
          '${feed.reels.length} reels, total ${feed.total}'
          '${feed.error != null ? ' (${feed.error})' : ''}');

      final sharedIds = shared.reels.map((e) => e.id).toSet();
      _videos
        ..addAll(shared.reels)
        ..addAll(feed.reels
            .where((e) => e.id == null || !sharedIds.contains(e.id)));

      if (_videos.isEmpty) {
        emit(VideoShortsFetchFailure(shared.error ?? feed.error ?? ""));
        return false;
      }

      // Paging carries on through the feed from where the fetched page ended.
      // With no feed (it failed), the next page simply starts it from the top.
      _offset = feed.reels.length;
      _totalCount = feed.error == null ? feed.total : _videos.length;

      emit(VideoShortsFetchSuccess(
        videoShorts: List.from(_videos),
        totalCount: _totalCount,
      ));
      return true;
    } finally {
      _isLoading = false;
    }
  }

  void updateVideoShortLike({
    required String videoShortsId,
    required bool isLiked,
  }) {
    if (state is! VideoShortsFetchSuccess) return;

    final current = state as VideoShortsFetchSuccess;
    for (final item in current.videoShorts) {
      if (item.id == videoShortsId) {
        item.isLiked = isLiked;
        if (isLiked) item.isDisliked = false;
        break;
      }
    }

    emit(VideoShortsFetchSuccess(
      videoShorts: current.videoShorts,
      totalCount: current.totalCount,
    ));
  }

  void updateVideoShortCommentsCount({
    required String videoShortsId,
    required int commentsCount,
  }) {
    if (state is! VideoShortsFetchSuccess) return;

    final current = state as VideoShortsFetchSuccess;
    for (final item in current.videoShorts) {
      if (item.id == videoShortsId) {
        item.commentsCount = commentsCount;
        break;
      }
    }

    emit(VideoShortsFetchSuccess(
      videoShorts: current.videoShorts,
      totalCount: current.totalCount,
    ));
  }
}

/// What [VideoShortsCubit._fetchPage] hands back: the reels on the page and the
/// total the API reports, or the [error] message when the call failed.
class _ReelsPage {
  final List<ReelModel> reels;
  final int total;
  final String? error;

  _ReelsPage(this.reels, this.total) : error = null;

  _ReelsPage.failed(String message)
      : reels = const [],
        total = 0,
        error = message;
}
