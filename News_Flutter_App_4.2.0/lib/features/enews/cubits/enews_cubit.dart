import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/enews/models/enews_model.dart';
import 'package:news/features/enews/repositories/enews_repository.dart';

abstract class ENewsState {}

class ENewsInitial extends ENewsState {}

class ENewsFetchInProgress extends ENewsState {}

class ENewsFetchSuccess extends ENewsState {
  final List<ENewsModel> eNewsList;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final bool hasMoreFetchError;

  ENewsFetchSuccess({
    required this.eNewsList,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
    required this.hasMoreFetchError,
  });
}

class ENewsFetchFailure extends ENewsState {
  final String errorMessage;
  ENewsFetchFailure(this.errorMessage);
}

class ENewsCubit extends Cubit<ENewsState> {
  final ENewsRepository _eNewsRepository;

  ENewsCubit(this._eNewsRepository) : super(ENewsInitial());

  void getENews({required String languageCode, required int perPage}) async {
    try {
      emit(ENewsFetchInProgress());
      final result = await _eNewsRepository.getENews(
        languageCode: languageCode,
        perPage: perPage.toString(),
        page: '1',
      );
      emit(ENewsFetchSuccess(
        eNewsList: result['eNews'],
        total: result['total'],
        currentPage: result['currentPage'],
        lastPage: result['lastPage'],
        hasMore: result['hasMore'],
        hasMoreFetchError: false,
      ));
    } catch (e) {
      emit(ENewsFetchFailure(e.toString()));
    }
  }

  void getMoreENews(
      {required String languageCode, required int perPage}) async {
    if (state is ENewsFetchSuccess) {
      final currentState = state as ENewsFetchSuccess;
      if (!currentState.hasMore) return;
      try {
        final nextPage = currentState.currentPage + 1;
        final result = await _eNewsRepository.getENews(
          languageCode: languageCode,
          perPage: perPage.toString(),
          page: nextPage.toString(),
        );
        final updatedList = [
          ...currentState.eNewsList,
          ...(result['eNews'] as List<ENewsModel>)
        ];
        emit(ENewsFetchSuccess(
          eNewsList: updatedList,
          total: result['total'],
          currentPage: result['currentPage'],
          lastPage: result['lastPage'],
          hasMore: result['hasMore'],
          hasMoreFetchError: false,
        ));
      } catch (e) {
        emit(ENewsFetchSuccess(
          eNewsList: currentState.eNewsList,
          total: currentState.total,
          currentPage: currentState.currentPage,
          lastPage: currentState.lastPage,
          hasMore: currentState.hasMore,
          hasMoreFetchError: true,
        ));
      }
    }
  }

  bool hasMoreENews() {
    return state is ENewsFetchSuccess
        ? (state as ENewsFetchSuccess).hasMore
        : false;
  }
}
