import 'package:news/features/news/models/news_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/repositories/news_by_id/news_by_id_repository.dart';

abstract class NewsByIdState {}

class NewsByIdInitial extends NewsByIdState {}

class NewsByIdFetchInProgress extends NewsByIdState {}

class NewsByIdFetchSuccess extends NewsByIdState {
  final List<NewsModel> newsById;

  NewsByIdFetchSuccess({required this.newsById});
}

class NewsByIdFetchFailure extends NewsByIdState {
  final String errorMessage;

  NewsByIdFetchFailure(this.errorMessage);
}

class NewsByIdCubit extends Cubit<NewsByIdState> {
  final NewsByIdRepository _newsByIdRepository;

  NewsByIdCubit(this._newsByIdRepository) : super(NewsByIdInitial());

  Future<List<NewsModel>> getNewsById(
      {required String newsId, required String langCode}) async {
    try {
      emit(NewsByIdFetchInProgress());
      final result = await _newsByIdRepository.getNewsById(
          langCode: langCode, newsId: newsId);
      emit(NewsByIdFetchSuccess(newsById: result['NewsById']));
      return result['NewsById'];
    } catch (e) {
      emit(NewsByIdFetchFailure(e.toString()));
      return [];
    }
  }
}
