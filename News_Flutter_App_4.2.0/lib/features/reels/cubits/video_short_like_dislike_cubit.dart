import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/core/error_handler/error_message_keys.dart';

abstract class VideoShortLikeDislikeState {}

class VideoShortLikeDislikeInitial extends VideoShortLikeDislikeState {}

class VideoShortLikeDislikeInProgress extends VideoShortLikeDislikeState {
  final String videoShortsId;

  VideoShortLikeDislikeInProgress(this.videoShortsId);
}

class VideoShortLikeDislikeSuccess extends VideoShortLikeDislikeState {
  final String videoShortsId;
  final String action;

  /// Server-confirmed like state. Falls back to the requested [action] when the
  /// response carries no `is_liked`.
  final bool isLiked;

  /// Server-confirmed like total, or null when the response omits it.
  final int? totalLikeCount;

  VideoShortLikeDislikeSuccess({
    required this.videoShortsId,
    required this.action,
    required this.isLiked,
    this.totalLikeCount,
  });
}

class VideoShortLikeDislikeFailure extends VideoShortLikeDislikeState {
  final String videoShortsId;
  final String errorMessage;

  /// The action the server refused, so the card knows what it was trying to do.
  final String action;

  /// Like state read off the error body, when the endpoint sends one.
  final bool? serverIsLiked;

  /// True when the server answered and refused the action, false when the
  /// request never reached it (offline, timeout, 5xx).
  ///
  /// A refusal means the reel is *already* in the state we asked for — the
  /// endpoint only rejects a like it has already recorded. Reading it that way
  /// is what lets the card resync; treating it as "nothing happened" left the
  /// card one tap behind the server, re-sending the same refused action on every
  /// tap, which is why the button stayed dead until the app restarted.
  final bool wasRefusedByServer;

  VideoShortLikeDislikeFailure(
    this.videoShortsId,
    this.errorMessage, {
    this.action = '',
    this.serverIsLiked,
    this.wasRefusedByServer = false,
  });
}

class VideoShortLikeDislikeCubit extends Cubit<VideoShortLikeDislikeState> {
  VideoShortLikeDislikeCubit() : super(VideoShortLikeDislikeInitial());

  /// Dio is built without timeouts, so a stalled request would otherwise keep a
  /// reel locked in [VideoShortLikeDislikeInProgress] until the app restarts.
  static const Duration _requestTimeout = Duration(seconds: 20);

  /// Reels with a request still on the wire. This — not the emitted state — is
  /// the real duplicate guard: the cubit is shared by every mounted reel, so an
  /// InProgress emitted for one reel says nothing about another.
  final Set<String> _inFlight = <String>{};

  bool isInProgress(String videoShortsId) => _inFlight.contains(videoShortsId);

  Future<void> setVideoShortLikeDislike({
    required String videoShortsId,
    required String action,
  }) async {
    // A second tap while the first request is still running would send the same
    // action twice; the server rejects the duplicate and the local like state
    // drifts out of sync with it.
    if (!_inFlight.add(videoShortsId)) return;

    try {
      emit(VideoShortLikeDislikeInProgress(videoShortsId));

      final result = await Api.sendApiRequest(body: {
        VIDEO_SHORTS_ID: videoShortsId,
        ACTION: action,
      }, url: Api.setVideoShortLikeDislikeApi)
          .timeout(_requestTimeout);

      final dynamic error = result[ERROR];
      if (error == true || error.toString().toLowerCase() == "true") {
        emit(VideoShortLikeDislikeFailure(
          videoShortsId,
          result[MESSAGE]?.toString() ?? ErrorMessageKeys.defaultErrorMessage,
          action: action,
          serverIsLiked: _parseBool(_pick(result, IS_LIKED)),
          wasRefusedByServer: true,
        ));
        return;
      }

      emit(VideoShortLikeDislikeSuccess(
        videoShortsId: videoShortsId,
        action: action,
        isLiked: _resolveIsLiked(result, action),
        totalLikeCount: _resolveTotalLikeCount(result),
      ));
    } on TimeoutException {
      emit(VideoShortLikeDislikeFailure(
          videoShortsId, ErrorMessageKeys.defaultErrorMessage,
          action: action));
    } on SocketException catch (e) {
      emit(VideoShortLikeDislikeFailure(videoShortsId, e.message,
          action: action));
    } on ApiException catch (e) {
      emit(VideoShortLikeDislikeFailure(videoShortsId, e.errorMessage,
          action: action,
          wasRefusedByServer: _isServerRefusal(e.errorMessage)));
    } catch (e) {
      emit(VideoShortLikeDislikeFailure(videoShortsId, e.toString(),
          action: action));
    } finally {
      // Always release the reel, whichever way the request ended.
      _inFlight.remove(videoShortsId);
    }
  }

  bool _resolveIsLiked(Map<String, dynamic> result, String action) {
    return _parseBool(_pick(result, IS_LIKED)) ?? (action == 'like');
  }

  /// [Api.sendApiRequest] reports a refused request and an unreachable server
  /// with the same exception type, so the message is all there is to go on: a
  /// canned transport message means the action never landed, anything else is
  /// the server's own words about why it said no.
  bool _isServerRefusal(String message) {
    const transportErrors = [
      ErrorMessageKeys.noInternet,
      ErrorMessageKeys.defaultErrorMessage,
      ErrorMessageKeys.serverDownMessage,
      ErrorMessageKeys.requestAgainMessage,
    ];
    return message.isNotEmpty && !transportErrors.contains(message);
  }

  int? _resolveTotalLikeCount(Map<String, dynamic> result) {
    final raw = _pick(result, TOTAL_LIKE_COUNT) ?? _pick(result, TOTAL_LIKE);
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  /// Reads [key] off the response root or its `data` payload, whichever carries
  /// it. The endpoint is not consistent about where it puts the updated counts.
  dynamic _pick(Map<String, dynamic> result, String key) {
    if (result[key] != null) return result[key];
    final data = result[DATA];
    if (data is Map && data[key] != null) return data[key];
    if (data is List && data.isNotEmpty && data.first is Map) {
      return (data.first as Map)[key];
    }
    return null;
  }

  bool? _parseBool(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    final str = raw.toString().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return null;
  }
}
