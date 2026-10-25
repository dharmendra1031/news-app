import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/cubits/setting_cubit.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/authentication/cubits/register_token_cubit.dart';
import 'package:news/features/notification_preferences/cubits/notification_preference_cubit.dart';
import 'package:news/features/notification_preferences/models/notification_preference_item.dart';
import 'package:news/features/notification_preferences/widgets/notification_preference_card.dart';
import 'package:news/utils/ui_utils.dart';

/// "Notification Preferences" screen (`Routes.notificationPreferences`), opened
/// from the [ProfileScreen]. Toggles are only persisted when Save is tapped.
class NotificationPreferenceScreen extends StatefulWidget {
  const NotificationPreferenceScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
        builder: (_) => const NotificationPreferenceScreen());
  }

  @override
  State<NotificationPreferenceScreen> createState() =>
      _NotificationPreferenceScreenState();
}

class _NotificationPreferenceScreenState
    extends State<NotificationPreferenceScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _load);
  }

  void _load() {
    context.read<NotificationPreferenceCubit>().getNotificationPreference();
  }

  Future<void> _onSaved(List<NotificationPreferenceItem> items) async {
    await _syncMasterNotification(items);
    if (!mounted) return;
    showSnackBar(
        UiUtils.getTranslatedLabel(context, 'preferenceSave'), context);
    Navigator.pop(context);
  }

  /// Keeps the master push on/off (FCM token) in sync: all types off
  /// unregisters the device, enabling any type re-registers it.
  Future<void> _syncMasterNotification(
      List<NotificationPreferenceItem> items) async {
    final settingsCubit = context.read<SettingsCubit>();
    final registerTokenCubit = context.read<RegisterTokenCubit>();
    final bool previousMaster =
        settingsCubit.state.settingsModel?.notification ?? true;
    final bool newMaster = anyPreferenceEnabled(items);
    if (newMaster == previousMaster) return;

    if (newMaster) {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        settingsCubit.changeFcmToken(token);
        if (mounted) {
          registerTokenCubit.registerToken(fcmId: token, context: context);
        }
      }
    } else {
      await FirebaseMessaging.instance.deleteToken();
      if (mounted) {
        registerTokenCubit.registerToken(fcmId: '', context: context);
      }
    }
    settingsCubit.changeNotification(newMaster);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
          height: 54,
          isBackBtn: true,
          isConvertText: true,
          label: 'notificationPreferenceTitle'),
      body:
          BlocConsumer<NotificationPreferenceCubit, NotificationPreferenceState>(
        listener: (context, state) {
          if (state is NotificationPreferenceSaveSuccess) {
            _onSaved(state.items);
          } else if (state is NotificationPreferenceSaveFailure) {
            showSnackBar(
                state.errorMessage.contains(ErrorMessageKeys.noInternet)
                    ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                    : state.errorMessage,
                context);
          }
        },
        builder: (context, state) {
          if (state is NotificationPreferenceInitial ||
              state is NotificationPreferenceFetchInProgress) {
            return Center(
                child: UiUtils.showCircularProgress(
                    true, Theme.of(context).primaryColor));
          }

          if (state is NotificationPreferenceFetchFailure) {
            return ErrorContainerWidget(
                errorMsg: state.errorMessage
                        .contains(ErrorMessageKeys.noInternet)
                    ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                    : state.errorMessage,
                onRetry: _load);
          }

          final NotificationPreferenceCubit cubit =
              context.read<NotificationPreferenceCubit>();
          final List<NotificationPreferenceItem> items = cubit.currentItems;
          final bool isSaving = (state is NotificationPreferenceFetchSuccess)
              ? state.isSaving
              : false;

          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                  itemBuilder: (_, index) => NotificationPreferenceCard(
                      item: items[index],
                      onToggle: isSaving ? () {} : () => cubit.toggle(index)),
                ),
              ),
              SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 16.0, end: 16.0, top: 8.0, bottom: 8.0),
                  child: _saveButton(isSaving: isSaving, cubit: cubit),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _saveButton(
      {required bool isSaving, required NotificationPreferenceCubit cubit}) {
    return InkWell(
      onTap: isSaving ? null : cubit.save,
      child: Container(
        height: 40.0,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(4.0)),
        child: isSaving
            ? UiUtils.showCircularProgress(true, secondaryColor)
            : CustomTextLabel(
                text: 'saveLbl',
                textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18),
              ),
      ),
    );
  }
}
