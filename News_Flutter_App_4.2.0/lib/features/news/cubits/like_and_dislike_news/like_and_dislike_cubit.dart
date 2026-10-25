import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/like_and_dislike_news/like_and_dislike_news_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class LikeAndDisLikeState {}

class LikeAndDisLikeInitial extends LikeAndDisLikeState {}

class LikeAndDisLikeFetchInProgress extends LikeAndDisLikeState {}

class LikeAndDisLikeFetchSuccess extends LikeAndDisLikeState {
  final List<NewsModel> likeAndDisLike;
  final int totalLikeAndDisLikeCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  LikeAndDisLikeFetchSuccess(
      {required this.likeAndDisLike,
      required this.totalLikeAndDisLikeCount,
      required this.hasMoreFetchError,
      required this.hasMore});
}

class LikeAndDisLikeFetchFailure extends LikeAndDisLikeState {
  final String errorMessage;

  LikeAndDisLikeFetchFailure(this.errorMessage);
}

class LikeAndDisLikeCubit extends Cubit<LikeAndDisLikeState> {
  final LikeAndDisLikeRepository likeAndDisLikeRepository;
  int perPageLimit = 25;

  LikeAndDisLikeCubit(this.likeAndDisLikeRepository)
      : super(LikeAndDisLikeInitial());

  /// Liked news ids, held outside the emitted state on purpose. Every like used
  /// to trigger a refresh that passes through [LikeAndDisLikeFetchInProgress],
  /// and while that ran (or if it failed) an already liked news read back as
  /// "not liked" — so the next tap sent a second like, the server rejected it,
  /// and the button was stranded in the wrong state until the app restarted.
  final Set<String> _likedNewsIds = <String>{};

  /// Likes applied locally whose request has not settled yet. A refresh that was
  /// already on the wire when the user tapped must not overwrite them.
  final Map<String, bool> _pendingLikes = <String, bool>{};

  /// Taps fire refreshes faster than they complete; only the newest may win.
  int _fetchId = 0;

  void getLike({required String langCode}) async {
    final int fetchId = ++_fetchId;
    try {
      emit(LikeAndDisLikeFetchInProgress());
      final result = await likeAndDisLikeRepository.getLike(
          limit: perPageLimit.toString(), offset: "0", langCode: langCode);
      if (isClosed || fetchId != _fetchId) return;

      final likeAndDisLike = result['LikeAndDisLike'] as List<NewsModel>;
      _likedNewsIds
        ..clear()
        ..addAll(likeAndDisLike.expand(_idsOf));
      _pendingLikes.forEach((newsId, isLiked) {
        isLiked ? _likedNewsIds.add(newsId) : _likedNewsIds.remove(newsId);
      });

      emit(LikeAndDisLikeFetchSuccess(
          likeAndDisLike: likeAndDisLike,
          totalLikeAndDisLikeCount: result[TOTAL],
          hasMoreFetchError: false,
          hasMore: likeAndDisLike.length < result[TOTAL]));
    } catch (e) {
      if (isClosed || fetchId != _fetchId) return;
      emit(LikeAndDisLikeFetchFailure(e.toString()));
    }
  }

  bool isNewsLikeAndDisLike(String newsId) => _likedNewsIds.contains(newsId);

  /// Applies a tap immediately so the button flips without waiting for the
  /// server. [settleLocalLike] confirms it, or it is called again with the
  /// previous value to roll it back when the request fails.
  void setLocalLike(NewsModel model, bool isLiked) {
    final Set<String> ids = _idsOf(model).toSet();
    if (ids.isEmpty) return;

    for (final id in ids) {
      _pendingLikes[id] = isLiked;
      isLiked ? _likedNewsIds.add(id) : _likedNewsIds.remove(id);
    }

    if (state is LikeAndDisLikeFetchSuccess) {
      final current = state as LikeAndDisLikeFetchSuccess;
      final List<NewsModel> likeList = List.from(current.likeAndDisLike)
        ..removeWhere((element) => _idsOf(element).any(ids.contains));
      final int removed = current.likeAndDisLike.length - likeList.length;
      if (isLiked) likeList.insert(0, model);

      final int total =
          current.totalLikeAndDisLikeCount - removed + (isLiked ? 1 : 0);
      emit(LikeAndDisLikeFetchSuccess(
          likeAndDisLike: likeList,
          totalLikeAndDisLikeCount: total < 0 ? 0 : total,
          hasMoreFetchError: false,
          hasMore: current.hasMore));
    }
  }

  /// Hands the news back to the server as the source of truth.
  void settleLocalLike(NewsModel model) {
    for (final id in _idsOf(model)) {
      _pendingLikes.remove(id);
    }
  }

  void addLikeNews(NewsModel model) => setLocalLike(model, true);

  void removeLikeNews(NewsModel model) => setLocalLike(model, false);

  Iterable<String> _idsOf(NewsModel model) => [model.newsId, model.id]
      .whereType<String>()
      .where((id) => id.isNotEmpty && id != "null");

  void resetState() {
    _fetchId++; // Drop refreshes still in flight for the signed-out user.
    _likedNewsIds.clear();
    _pendingLikes.clear();
    emit(LikeAndDisLikeFetchInProgress());
  }
}
