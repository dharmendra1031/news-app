import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/short_news/short_news_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class ShortNewsState {}

class ShortNewsInitial extends ShortNewsState {}

class ShortNewsFetchInProgress extends ShortNewsState {}

class ShortNewsFetchSuccess extends ShortNewsState {
  final List<NewsModel> shortNews;

  ShortNewsFetchSuccess({required this.shortNews});
}

class ShortNewsFetchFailure extends ShortNewsState {
  final String errorMessage;

  ShortNewsFetchFailure(this.errorMessage);
}

class ShortNewsCubit extends Cubit<ShortNewsState> {
  final ShortNewsRepository _repository;

  ShortNewsCubit(this._repository) : super(ShortNewsInitial());

  Future<List<NewsModel>> fetchShortNews({required String langCode}) async {
    emit(ShortNewsFetchInProgress());
    try {
      final result = await _repository.getShortNews(langCode: langCode);
      if (!result[ERROR]) {
        final list = result['shortNews'] as List<NewsModel>;
        if (list.isEmpty) {
          emit(ShortNewsFetchFailure(result[MESSAGE].toString()));
          return [];
        }
        emit(ShortNewsFetchSuccess(shortNews: list));
        return list;
      }
      emit(ShortNewsFetchFailure(result[MESSAGE].toString()));
      return [];
    } catch (e) {
      emit(ShortNewsFetchFailure(e.toString()));
      return [];
    }
  }
}
