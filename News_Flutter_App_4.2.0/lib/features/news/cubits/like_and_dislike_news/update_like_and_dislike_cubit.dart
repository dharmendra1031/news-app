import 'dart:async';

import 'package:news/features/news/repositories/like_and_dislike_news/like_and_dislike_news_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/core/error_handler/error_message_keys.dart';

abstract class UpdateLikeAndDisLikeStatusState {}

class UpdateLikeAndDisLikeStatusInitial
    extends UpdateLikeAndDisLikeStatusState {}

class UpdateLikeAndDisLikeStatusInProgress
    extends UpdateLikeAndDisLikeStatusState {
  final String newsId;

  UpdateLikeAndDisLikeStatusInProgress([this.newsId = '']);
}

class UpdateLikeAndDisLikeStatusSuccess
    extends UpdateLikeAndDisLikeStatusState {
  final NewsModel news;
  final bool
      wasLikeAndDisLikeNewsProcess; //to check that process of favorite done or not
  final String newsId;

  UpdateLikeAndDisLikeStatusSuccess(
      this.news, this.wasLikeAndDisLikeNewsProcess,
      [this.newsId = '']);
}

class UpdateLikeAndDisLikeStatusFailure
    extends UpdateLikeAndDisLikeStatusState {
  final String errorMessage;

  /// Which news failed, and whether the tap was a like or an unlike, so the
  /// screen can roll its optimistic flip back.
  final String newsId;
  final bool wasLikeAndDisLikeNewsProcess;

  UpdateLikeAndDisLikeStatusFailure(this.errorMessage,
      [this.newsId = '', this.wasLikeAndDisLikeNewsProcess = false]);
}

class UpdateLikeAndDisLikeStatusCubit
    extends Cubit<UpdateLikeAndDisLikeStatusState> {
  final LikeAndDisLikeRepository likeAndDisLikeRepository;

  UpdateLikeAndDisLikeStatusCubit(this.likeAndDisLikeRepository)
      : super(UpdateLikeAndDisLikeStatusInitial());

  /// Dio carries no timeouts, so a stalled request would otherwise pin the
  /// button in [UpdateLikeAndDisLikeStatusInProgress] until the app restarts.
  static const Duration _requestTimeout = Duration(seconds: 20);

  /// News ids with a request still on the wire. The widgets gate on the emitted
  /// state, which they only see after the next rebuild — taps landing before
  /// that would otherwise fire a second, conflicting request.
  final Set<String> _inFlight = <String>{};

  bool isInProgress(String newsId) => _inFlight.contains(newsId);

  Future<void> setLikeAndDisLikeNews(
      {required NewsModel news, required String status}) async {
    final String newsId = news.newsId ?? news.id ?? '';
    if (newsId.isEmpty) return;
    if (!_inFlight.add(newsId)) return;

    final bool isLikeProcess = status == "1";

    try {
      _safeEmit(UpdateLikeAndDisLikeStatusInProgress(newsId));

      final value = await likeAndDisLikeRepository
          .setLike(newsId: newsId, status: status)
          .timeout(_requestTimeout);

      // Only the `error` flag decides this. Matching the word "success" in the
      // message failed every like the endpoint answered without one, and the
      // data source has already thrown on a real error by this point.
      final dynamic error = value[ERROR];
      if (error == true || error.toString().toLowerCase() == "true") {
        final String message = value[MESSAGE]?.toString() ?? '';
        _safeEmit(UpdateLikeAndDisLikeStatusFailure(
            message.isEmpty ? ErrorMessageKeys.defaultErrorMessage : message,
            newsId,
            isLikeProcess));
        return;
      }

      // The endpoint omits `data` on some responses, so fall back to the model
      // we were handed rather than parsing null.
      _safeEmit(UpdateLikeAndDisLikeStatusSuccess(
          _newsFrom(value[DATA]) ?? news, isLikeProcess, newsId));
    } on TimeoutException {
      _safeEmit(UpdateLikeAndDisLikeStatusFailure(
          ErrorMessageKeys.defaultErrorMessage, newsId, isLikeProcess));
    } on ApiMessageAndCodeException catch (e) {
      _safeEmit(UpdateLikeAndDisLikeStatusFailure(
          e.errorMessage, newsId, isLikeProcess));
    } on ApiException catch (e) {
      _safeEmit(UpdateLikeAndDisLikeStatusFailure(
          e.errorMessage, newsId, isLikeProcess));
    } catch (e) {
      _safeEmit(UpdateLikeAndDisLikeStatusFailure(
          e.toString(), newsId, isLikeProcess));
    } finally {
      // Always release the news, whichever way the request ended.
      _inFlight.remove(newsId);
    }
  }

  NewsModel? _newsFrom(dynamic data) {
    if (data is Map) {
      return NewsModel.fromJson(Map<String, dynamic>.from(data));
    }
    if (data is List && data.isNotEmpty && data.first is Map) {
      return NewsModel.fromJson(Map<String, dynamic>.from(data.first as Map));
    }
    return null;
  }

  /// These cubits are created per news / video item and closed with them, so a
  /// response can land after the widget is gone.
  void _safeEmit(UpdateLikeAndDisLikeStatusState state) {
    if (!isClosed) emit(state);
  }
}
