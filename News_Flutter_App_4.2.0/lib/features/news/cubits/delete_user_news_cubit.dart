import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/add_edit_news/repositories/delete_user_news/delete_user_news_repository.dart';
import 'package:news/core/api/api.dart';


abstract class DeleteUserNewsState {}

class DeleteUserNewsInitial extends DeleteUserNewsState {}

class DeleteUserNewsInProgress extends DeleteUserNewsState {}

class DeleteUserNewsSuccess extends DeleteUserNewsState {
  final String message;

  DeleteUserNewsSuccess(this.message);
}

class DeleteUserNewsFailure extends DeleteUserNewsState {
  final String errorMessage;

  DeleteUserNewsFailure(this.errorMessage);
}

class DeleteUserNewsCubit extends Cubit<DeleteUserNewsState> {
  final DeleteUserNewsRepository _deleteUserNewsRepository;

  DeleteUserNewsCubit(this._deleteUserNewsRepository) : super(DeleteUserNewsInitial());

  void setDeleteUserNews({
    required String newsId,
  }) {
    emit(DeleteUserNewsInProgress());
    _deleteUserNewsRepository
        .setDeleteUserNews(
      newsId: newsId,
    )
        .then((value) {
      emit(DeleteUserNewsSuccess(value["message"]));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(DeleteUserNewsFailure(apiMessageAndCodeException.errorMessage.toString()));
    });
  }
}
