import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/repositories/breaking_news/break_news_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class BreakingNewsState {}

class BreakingNewsInitial extends BreakingNewsState {}

class BreakingNewsFetchInProgress extends BreakingNewsState {}

class BreakingNewsFetchSuccess extends BreakingNewsState {
  final List<BreakingNewsModel> breakingNews;

  BreakingNewsFetchSuccess({required this.breakingNews});
}

class BreakingNewsFetchFailure extends BreakingNewsState {
  final String errorMessage;

  BreakingNewsFetchFailure(this.errorMessage);
}

class BreakingNewsCubit extends Cubit<BreakingNewsState> {
  final BreakingNewsRepository _breakingNewsRepository;

  BreakingNewsCubit(this._breakingNewsRepository)
      : super(BreakingNewsInitial());

  Future<List<BreakingNewsModel>> getBreakingNews(
      {required String langCode}) async {
    emit(BreakingNewsFetchInProgress());
    try {
      final result =
          await _breakingNewsRepository.getBreakingNews(langCode: langCode);
      (!result[ERROR])
          ? emit(BreakingNewsFetchSuccess(breakingNews: result['BreakingNews']))
          : emit(BreakingNewsFetchFailure(result[MESSAGE]));
      return (!result[ERROR]) ? result['BreakingNews'] : [];
    } catch (e) {
      emit(BreakingNewsFetchFailure(e.toString()));
      return [];
    }
  }
}
