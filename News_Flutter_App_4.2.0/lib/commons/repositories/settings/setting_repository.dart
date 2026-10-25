import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';

class SettingsRepository {
  static final SettingsRepository _settingsRepository =
      SettingsRepository._internal();
  late SettingsLocalDataRepository _settingsLocalDataSource;

  factory SettingsRepository() {
    _settingsRepository._settingsLocalDataSource =
        SettingsLocalDataRepository();
    return _settingsRepository;
  }

  SettingsRepository._internal();

  Map<String, dynamic> getCurrentSettings() {
    return {
      "showIntroSlider": _settingsLocalDataSource.getIntroSlider(),
      "languageCode": _settingsLocalDataSource.getCurrentLanguageCode(),
      "theme": _settingsLocalDataSource.getCurrentTheme(),
      "notification": _settingsLocalDataSource.getNotification(),
      "token": _settingsLocalDataSource.getFcmToken()
    };
  }

  void changeIntroSlider(bool value) =>
      _settingsLocalDataSource.setIntroSlider(value);

  void changeFcmToken(String value) =>
      _settingsLocalDataSource.setFcmToken(value);

  void changeNotification(bool value) =>
      _settingsLocalDataSource.setNotification(value);
}
