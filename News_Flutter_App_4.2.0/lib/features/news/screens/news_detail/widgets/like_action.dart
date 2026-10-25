import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/utils/ui_utils.dart';

/// Like / unlike handling shared by the two like buttons on the news details
/// screen (the floating one and the one in the action row). Both drive the same
/// app-wide cubits, so they have to agree on what a tap means.

String newsIdOf(NewsModel model) => model.newsId ?? model.id ?? '';

/// True while this news has a like request on the wire. Gating on the emitted
/// state instead would freeze every news, since the cubit is app-wide.
bool isLikeInProgress(BuildContext context, NewsModel model) {
  final String newsId = newsIdOf(model);
  return newsId.isNotEmpty &&
      context.read<UpdateLikeAndDisLikeStatusCubit>().isInProgress(newsId);
}

bool isNewsLiked(BuildContext context, NewsModel model) =>
    context.read<LikeAndDisLikeCubit>().isNewsLikeAndDisLike(newsIdOf(model));

void onLikeTap(BuildContext context, NewsModel model) {
  if (context.read<AuthCubit>().getUserId() == "0") {
    UiUtils.loginRequired(context);
    return;
  }

  final String newsId = newsIdOf(model);
  if (newsId.isEmpty) return;

  final updateCubit = context.read<UpdateLikeAndDisLikeStatusCubit>();
  if (updateCubit.isInProgress(newsId)) return;

  final likeCubit = context.read<LikeAndDisLikeCubit>();
  final bool willLike = !likeCubit.isNewsLikeAndDisLike(newsId);

  // Flip locally before the request goes out. The buttons read their state from
  // LikeAndDisLikeCubit, which used to stay stale until the refresh landed, so a
  // fast second tap sent the same status twice and the server rejected it.
  likeCubit.setLocalLike(model, willLike);
  model.totalLikes = _shiftTotal(model.totalLikes, willLike ? 1 : -1);

  updateCubit.setLikeAndDisLikeNews(news: model, status: willLike ? "1" : "0");
}

/// Reconciles the optimistic flip with what the server actually did.
void onLikeStatusChanged(BuildContext context,
    UpdateLikeAndDisLikeStatusState state, NewsModel model) {
  final String newsId = newsIdOf(model);
  if (newsId.isEmpty) return;

  final likeCubit = context.read<LikeAndDisLikeCubit>();

  if (state is UpdateLikeAndDisLikeStatusSuccess && state.newsId == newsId) {
    final String? total = state.news.totalLikes;
    if (total != null && total.isNotEmpty && total != "null") {
      model.totalLikes = total;
    }
    likeCubit.settleLocalLike(model);
    likeCubit.getLike(
        langCode: context.read<AppLocalizationCubit>().state.languageCode);
    return;
  }

  if (state is UpdateLikeAndDisLikeStatusFailure && state.newsId == newsId) {
    // Roll the flip back, otherwise the button shows a like the server never took
    // and every later tap repeats the request it just refused.
    likeCubit.setLocalLike(model, !state.wasLikeAndDisLikeNewsProcess);
    likeCubit.settleLocalLike(model);
    model.totalLikes = _shiftTotal(
        model.totalLikes, state.wasLikeAndDisLikeNewsProcess ? -1 : 1);
    showSnackBar(state.errorMessage, context);
  }
}

String _shiftTotal(String? total, int delta) {
  final int current = int.tryParse(total ?? '') ?? 0;
  final int next = current + delta;
  return (next < 0 ? 0 : next).toString();
}
