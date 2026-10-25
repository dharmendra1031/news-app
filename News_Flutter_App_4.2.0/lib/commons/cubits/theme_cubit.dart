import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/core/theme/app_theme.dart';
import 'package:news/utils/ui_utils.dart';

class ThemeState {
  final AppTheme appTheme;
  ThemeState(this.appTheme);
}

class ThemeCubit extends Cubit<ThemeState> {
  SettingsLocalDataRepository settingsRepository;
  ThemeCubit(this.settingsRepository)
      : super(ThemeState(UiUtils.getAppThemeFromLabel(
            settingsRepository.getCurrentTheme())));

  void changeTheme(AppTheme appTheme) {
    settingsRepository
        .setCurrentTheme(UiUtils.getThemeLabelFromAppTheme(appTheme));
    emit(ThemeState(appTheme));
    UiUtils.setUIOverlayStyle(appTheme: appTheme);
  }
}
