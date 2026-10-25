import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/dynamic_pages/models/other_page_model.dart';
import 'package:news/features/dynamic_pages/repositories/other_pages_repository.dart';

abstract class OtherPageState {}

class OtherPageInitial extends OtherPageState {}

class OtherPageFetchInProgress extends OtherPageState {}

class OtherPageFetchSuccess extends OtherPageState {
  final List<OtherPageModel> otherPage;

  OtherPageFetchSuccess({required this.otherPage});
}

class OtherPageFetchFailure extends OtherPageState {
  final String errorMessage;

  OtherPageFetchFailure(this.errorMessage);
}

class OtherPageCubit extends Cubit<OtherPageState> {
  final OtherPageRepository _otherPageRepository;

  OtherPageCubit(this._otherPageRepository) : super(OtherPageInitial());

  Future<List<OtherPageModel>> _fetchPages(String langCode) async {
    final result = await _otherPageRepository.getOtherPage(langCode: langCode);
    return List<OtherPageModel>.from(result['OtherPage']);
  }

  /// Fetches the dynamic pages (About Us, Contact Us, ...) for [langCode].
  ///
  /// Pages are translated one language at a time in the Admin panel, so a
  /// language the user picked may have none configured. When that happens the
  /// pages of [defaultLangCode] are shown instead of an empty list, so entries
  /// like Contact Us never disappear from the menu. Note the API reports "no
  /// pages" as an error response rather than an empty list, which is why the
  /// retry also covers the failure path.
  void getOtherPage({required String langCode, String? defaultLangCode}) async {
    emit(OtherPageFetchInProgress());

    final String? fallbackCode = (defaultLangCode != null &&
            defaultLangCode.isNotEmpty &&
            defaultLangCode != langCode)
        ? defaultLangCode
        : null;

    try {
      final pages = await _fetchPages(langCode);
      if (pages.isEmpty && fallbackCode != null) {
        emit(OtherPageFetchSuccess(otherPage: await _fetchPages(fallbackCode)));
        return;
      }
      emit(OtherPageFetchSuccess(otherPage: pages));
    } catch (e) {
      if (fallbackCode != null) {
        try {
          emit(
              OtherPageFetchSuccess(otherPage: await _fetchPages(fallbackCode)));
          return;
        } catch (_) {
          //Default language failed too - report the original error below.
        }
      }
      emit(OtherPageFetchFailure(e.toString()));
    }
  }
}
