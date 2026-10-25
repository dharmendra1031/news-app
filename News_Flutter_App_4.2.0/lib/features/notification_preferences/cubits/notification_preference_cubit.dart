import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/notification_preferences/models/notification_preference_item.dart';
import 'package:news/features/notification_preferences/repositories/notification_preference_repository.dart';

/// Drives the [NotificationPreferenceScreen]: fetch, in-memory toggling, save.
/// A failed fetch falls back to the Hive cache when there is one.

abstract class NotificationPreferenceState {}

class NotificationPreferenceInitial extends NotificationPreferenceState {}

class NotificationPreferenceFetchInProgress
    extends NotificationPreferenceState {}

class NotificationPreferenceFetchFailure extends NotificationPreferenceState {
  final String errorMessage;

  NotificationPreferenceFetchFailure(this.errorMessage);
}

class NotificationPreferenceFetchSuccess extends NotificationPreferenceState {
  final List<NotificationPreferenceItem> items;
  final bool isSaving;

  NotificationPreferenceFetchSuccess(
      {required this.items, this.isSaving = false});
}

class NotificationPreferenceSaveSuccess extends NotificationPreferenceState {
  final List<NotificationPreferenceItem> items;

  NotificationPreferenceSaveSuccess({required this.items});
}

class NotificationPreferenceSaveFailure extends NotificationPreferenceState {
  final List<NotificationPreferenceItem> items;
  final String errorMessage;

  NotificationPreferenceSaveFailure(
      {required this.items, required this.errorMessage});
}

class NotificationPreferenceCubit extends Cubit<NotificationPreferenceState> {
  final NotificationPreferenceRepository _repository;

  NotificationPreferenceCubit(this._repository)
      : super(NotificationPreferenceInitial());

  List<NotificationPreferenceItem> get currentItems {
    final NotificationPreferenceState s = state;
    if (s is NotificationPreferenceFetchSuccess) return s.items;
    if (s is NotificationPreferenceSaveSuccess) return s.items;
    if (s is NotificationPreferenceSaveFailure) return s.items;
    return const <NotificationPreferenceItem>[];
  }

  Future<void> getNotificationPreference() async {
    emit(NotificationPreferenceFetchInProgress());
    try {
      final List<NotificationPreferenceItem> items =
          await _repository.getNotificationPreference();
      if (items.isEmpty) {
        emit(
            NotificationPreferenceFetchFailure(ErrorMessageKeys.noDataMessage));
        return;
      }
      emit(NotificationPreferenceFetchSuccess(items: items));
    } catch (e) {
      final List<NotificationPreferenceItem> cached =
          _repository.getCachedPreferences();
      if (cached.isEmpty) {
        emit(NotificationPreferenceFetchFailure(e.toString()));
      } else {
        emit(NotificationPreferenceFetchSuccess(items: cached));
      }
    }
  }

  void toggle(int index) {
    final List<NotificationPreferenceItem> items =
        List<NotificationPreferenceItem>.from(currentItems);
    if (index < 0 || index >= items.length) return;
    items[index] = items[index].copyWith(enabled: !items[index].enabled);
    emit(NotificationPreferenceFetchSuccess(items: items));
  }

  Future<void> save() async {
    final List<NotificationPreferenceItem> items = currentItems;
    if (items.isEmpty) return;

    emit(NotificationPreferenceFetchSuccess(items: items, isSaving: true));
    try {
      final List<NotificationPreferenceItem> saved =
          await _repository.setNotificationPreference(items);
      emit(NotificationPreferenceSaveSuccess(items: saved));
    } catch (e) {
      emit(NotificationPreferenceSaveFailure(
          items: items, errorMessage: e.toString()));
    }
  }
}
