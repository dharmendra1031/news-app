import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';

class AppLocalizationState {
  String languageCode;
  String id;
  int isRTL;

  AppLocalizationState(
    this.languageCode,
    this.id,
    this.isRTL,
  );
}

class AppLocalizationCubit extends Cubit<AppLocalizationState> {
  final SettingsLocalDataRepository _settingsRepository;

  AppLocalizationCubit(this._settingsRepository)
      : super(AppLocalizationState(
            _settingsRepository.getCurrentLanguageCode(),
            _settingsRepository.getCurrentLanguageId(),
            _settingsRepository.getCurrentLanguageRTL()));

  void changeLanguage(String lanCode, String lanId, int lanRTL) {
    _settingsRepository.setLanguagePreferences(
        code: lanCode, id: lanId, rtl: lanRTL);
    emit(AppLocalizationState(lanCode, lanId, lanRTL));
  }
}
