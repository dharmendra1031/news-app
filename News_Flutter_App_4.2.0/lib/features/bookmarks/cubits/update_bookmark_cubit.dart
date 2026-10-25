import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class UpdateBookmarkStatusState {}

class UpdateBookmarkStatusInitial extends UpdateBookmarkStatusState {}

class UpdateBookmarkStatusInProgress extends UpdateBookmarkStatusState {}

class UpdateBookmarkStatusSuccess extends UpdateBookmarkStatusState {
  final NewsModel news;
  final bool
      wasBookmarkNewsProcess; //to check that process of Bookmark done or not
  UpdateBookmarkStatusSuccess(this.news, this.wasBookmarkNewsProcess);
}

class UpdateBookmarkStatusFailure extends UpdateBookmarkStatusState {
  final String errorMessage;

  UpdateBookmarkStatusFailure(this.errorMessage);
}

class UpdateBookmarkStatusCubit extends Cubit<UpdateBookmarkStatusState> {
  final BookmarkRepository bookmarkRepository;

  UpdateBookmarkStatusCubit(this.bookmarkRepository)
      : super(UpdateBookmarkStatusInitial());

  void setBookmarkNews({required NewsModel news, required String status}) {
    emit(UpdateBookmarkStatusInProgress());
    bookmarkRepository
        .setBookmark(
            newsId: (news.newsId != null) ? news.newsId! : news.id!,
            status: status)
        .then((value) {
      if (value[MESSAGE].toString().toLowerCase().contains("success")) {
        emit(UpdateBookmarkStatusSuccess(news, status == "1" ? true : false));
      } else {
        emit(UpdateBookmarkStatusFailure(value));
      }
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(UpdateBookmarkStatusFailure(
          apiMessageAndCodeException.errorMessage.toString()));
    });
  }
}
