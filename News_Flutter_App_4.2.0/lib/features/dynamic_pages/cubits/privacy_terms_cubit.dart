import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/dynamic_pages/models/other_page_model.dart';
import 'package:news/features/dynamic_pages/repositories/other_pages_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class PrivacyTermsState {}

class PrivacyTermsInitial extends PrivacyTermsState {}

class PrivacyTermsFetchInProgress extends PrivacyTermsState {}

class PrivacyTermsFetchSuccess extends PrivacyTermsState {
  final OtherPageModel termsPolicy;
  final OtherPageModel privacyPolicy;

  PrivacyTermsFetchSuccess(
      {required this.termsPolicy, required this.privacyPolicy});
}

class PrivacyTermsFetchFailure extends PrivacyTermsState {
  final String errorMessage;

  PrivacyTermsFetchFailure(this.errorMessage);
}

class PrivacyTermsCubit extends Cubit<PrivacyTermsState> {
  final OtherPageRepository _otherPageRepository;

  PrivacyTermsCubit(this._otherPageRepository) : super(PrivacyTermsInitial());

  void getPrivacyTerms({required String langCode}) async {
    emit(PrivacyTermsFetchInProgress());
    try {
      final Map<String, dynamic> result =
          await _otherPageRepository.getPrivacyTermsPage(langCode: langCode);
      emit(PrivacyTermsFetchSuccess(
          privacyPolicy: OtherPageModel.fromPrivacyTermsJson(
              result[DATA]['privacy_policy']),
          termsPolicy: OtherPageModel.fromPrivacyTermsJson(
              result[DATA]['terms_policy'])));
    } catch (e) {
      emit(PrivacyTermsFetchFailure(e.toString()));
    }
  }
}
