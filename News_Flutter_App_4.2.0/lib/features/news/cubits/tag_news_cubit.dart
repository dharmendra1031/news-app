import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/repositories/tag_news/tag_news_repository.dart';

abstract class TagNewsState {}

class TagNewsInitial extends TagNewsState {}

class TagNewsFetchInProgress extends TagNewsState {}

class TagNewsFetchSuccess extends TagNewsState {
  final List<NewsModel> tagNews;

  TagNewsFetchSuccess({required this.tagNews});
}

class TagNewsFetchFailure extends TagNewsState {
  final String errorMessage;

  TagNewsFetchFailure(this.errorMessage);
}

class TagNewsCubit extends Cubit<TagNewsState> {
  final TagNewsRepository _tagNewsRepository;

  TagNewsCubit(this._tagNewsRepository) : super(TagNewsInitial());

  void getTagNews(
      {required String tagId,
      required String langCode,
      String? latitude,
      String? longitude}) async {
    try {
      emit(TagNewsFetchInProgress());
      final result = await _tagNewsRepository.getTagNews(
          langCode: langCode,
          tagId: tagId,
          latitude: latitude,
          longitude: longitude);
      emit(TagNewsFetchSuccess(tagNews: result['TagNews']));
    } catch (e) {
      emit(TagNewsFetchFailure(e.toString()));
    }
  }
}
