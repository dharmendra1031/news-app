import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

abstract class AuthorState {}

class AuthorInitial extends AuthorState {}

class AuthorInProgress extends AuthorState {}

class AuthorApproved extends AuthorState {
  AuthorApproved();
}

class AuthorRequestSent extends AuthorState {
  final String responseMessage;
  AuthorRequestSent(this.responseMessage);
}

class AuthorPending extends AuthorState {
  final String errorMessage;

  AuthorPending(this.errorMessage);
}

class AuthorRejected extends AuthorState {
  final String errorMessage;

  AuthorRejected(this.errorMessage);
}

class AuthorCubit extends Cubit<AuthorState> {
  AuthorCubit() : super(AuthorInitial());

  void requestToBecomeAuthor() async {
    try {
      emit(AuthorInitial()); //CHECK here
      final result =
          await Api.sendApiRequest(body: {}, url: Api.becomeAnAuthorApi);
      (!result[ERROR])
          ? emit(AuthorRequestSent(result[MESSAGE]))
          : emit(AuthorPending(result[MESSAGE]));
    } catch (e) {
      emit(AuthorPending(e.toString()));
    }
  }
}
