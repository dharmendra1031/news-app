import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/repositories/delete_image_id/delete_image_repository.dart';
import 'package:news/core/api/api.dart'; 

abstract class DeleteImageState {}

class DeleteImageInitial extends DeleteImageState {}

class DeleteImageInProgress extends DeleteImageState {}

class DeleteImageSuccess extends DeleteImageState {
  final String message;

  DeleteImageSuccess(this.message);
}

class DeleteImageFailure extends DeleteImageState {
  final String errorMessage;

  DeleteImageFailure(this.errorMessage);
}

class DeleteImageCubit extends Cubit<DeleteImageState> {
  final DeleteImageRepository _deleteImageRepository;

  DeleteImageCubit(this._deleteImageRepository) : super(DeleteImageInitial());

  void setDeleteImage({required String imageId}) {
    emit(DeleteImageInProgress());
    _deleteImageRepository.setDeleteImage(imageId: imageId).then((value) {
      emit(DeleteImageSuccess(value["message"]));
    }).catchError((e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      emit(DeleteImageFailure(apiMessageAndCodeException.errorMessage.toString()));
    });
  }
}
