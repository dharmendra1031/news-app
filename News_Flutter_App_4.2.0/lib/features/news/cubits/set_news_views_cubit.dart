import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/repositories/set_news_views/set_news_views_repository.dart';
import 'package:news/core/api/api.dart';

abstract class SetNewsViewsState {}

class SetNewsViewsInitial extends SetNewsViewsState {}

class SetNewsViewsInProgress extends SetNewsViewsState {}

class SetNewsViewsSuccess extends SetNewsViewsState {
  final String message;

  SetNewsViewsSuccess(this.message);
}

class SetNewsViewsFailure extends SetNewsViewsState {
  final String errorMessage;

  SetNewsViewsFailure(this.errorMessage);
}

class SetNewsViewsCubit extends Cubit<SetNewsViewsState> {
  final SetNewsViewsRepository setNewsViewsRepository;

  SetNewsViewsCubit(this.setNewsViewsRepository) : super(SetNewsViewsInitial());

  void setNewsViews({required String newsId, required bool isBreakingNews}) {
    emit(SetNewsViewsInProgress());
    setNewsViewsRepository
        .setNewsViews(newsId: newsId, isBreakingNews: isBreakingNews)
        .then((value) {
      emit(SetNewsViewsSuccess(value["message"]));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(SetNewsViewsFailure(
          apiMessageAndCodeException.errorMessage.toString()));
    });
  }
}
