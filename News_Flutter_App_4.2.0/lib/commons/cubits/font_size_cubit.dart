import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/core/constants/app_font_size.dart';

class FontSizeState {
  /// Font size, in logical pixels, for news/article body text.
  final int fontSize;

  const FontSizeState(this.fontSize);
}

/// Holds the app-wide reader font size.
///
/// The starting value is read from Hive, so the user's choice survives an app
/// restart. Every change is written straight back to Hive and emitted, which is
/// what makes the setting apply to all article screens at once.
class FontSizeCubit extends Cubit<FontSizeState> {
  final SettingsLocalDataRepository settingsRepository;

  FontSizeCubit(this.settingsRepository)
      : super(FontSizeState(settingsRepository.getNewsFontSize()));

  int get fontSize => state.fontSize;

  void changeFontSize(int value) {
    final size = value.clamp(AppFontSize.min, AppFontSize.max);
    if (size == state.fontSize) return;

    settingsRepository.setNewsFontSize(size);
    emit(FontSizeState(size));
  }
}
