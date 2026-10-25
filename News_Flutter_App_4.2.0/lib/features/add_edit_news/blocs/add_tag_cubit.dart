import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/tag_model.dart';
import 'package:news/features/add_edit_news/repositories/add_tag_repository.dart';

abstract class AddTagState {}

class AddTagInitial extends AddTagState {}

class AddTagInProgress extends AddTagState {}

class AddTagSuccess extends AddTagState {
  final TagModel tag;

  AddTagSuccess(this.tag);
}

class AddTagFailure extends AddTagState {
  final String errorMessage;

  AddTagFailure(this.errorMessage);
}

class AddTagCubit extends Cubit<AddTagState> {
  final AddTagRepository _addTagRepository;

  AddTagCubit(this._addTagRepository) : super(AddTagInitial());

  Future<void> addTag(
      {required String langCode, required String tagName}) async {
    emit(AddTagInProgress());
    try {
      final tag =
          await _addTagRepository.addTag(langCode: langCode, tagName: tagName);
      emit(AddTagSuccess(tag));
    } catch (e) {
      emit(AddTagFailure(e.toString()));
    }
  }
}
