import 'package:news/core/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/strings.dart';

abstract class SlugCheckState {}

class SlugCheckInitial extends SlugCheckState {}

class SlugCheckFetchInProgress extends SlugCheckState {}

class SlugCheckFetchSuccess extends SlugCheckState {
  String message;
  SlugCheckFetchSuccess({required this.message});
}

class SlugCheckFetchFailure extends SlugCheckState {
  final String errorMessage;

  SlugCheckFetchFailure(this.errorMessage);
}

class SlugCheckCubit extends Cubit<SlugCheckState> {
  SlugCheckCubit() : super(SlugCheckInitial());

  Future<void> checkSlugAvailability(
      {required String slug, required String langCode}) async {
    try {
      final result = await Api.sendApiRequest(body: {
        SLUG: slug,
        LANGUAGE_CODE: langCode,
        LIMIT: limitOfAPIData,
        OFFSET: 0
      }, url: Api.slugCheckApi);
      if (result[ERROR] == true) {
        emit(SlugCheckFetchFailure(result[MESSAGE].toString()));
      } else {
        emit(SlugCheckFetchSuccess(message: result[MESSAGE]));
      }
    } catch (e) {
      emit(SlugCheckFetchFailure(e.toString()));
    }
  }
}
