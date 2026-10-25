import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/app.dart';
import 'package:news/commons/enums.dart';
import 'package:news/commons/models/app_system_setting_model.dart';
import 'package:news/commons/repositories/app_system_setting/system_repository.dart';
import 'package:news/utils/ui_utils.dart';

abstract class AppConfigurationState {}

class AppConfigurationInitial extends AppConfigurationState {
  @override
  List<Object?> get props => [];
}

class AppConfigurationFetchInProgress extends AppConfigurationState {
  @override
  List<Object?> get props => [];
}

class AppConfigurationFetchSuccess extends AppConfigurationState {
  final AppSystemSettingModel appConfiguration;

  AppConfigurationFetchSuccess({required this.appConfiguration});

  @override
  List<Object?> get props => [appConfiguration];
}

class AppConfigurationFetchFailure extends AppConfigurationState {
  final String errorMessage;

  AppConfigurationFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class AppConfigurationCubit extends Cubit<AppConfigurationState> {
  final SystemRepository _systemRepository;

  AppConfigurationCubit(this._systemRepository)
      : super(AppConfigurationInitial());

  fetchAppConfiguration() async {
    emit(AppConfigurationFetchInProgress());
    try {
      final appConfiguration = AppSystemSettingModel.fromJson(
          await _systemRepository.fetchSettings());
      emit(AppConfigurationFetchSuccess(appConfiguration: appConfiguration));
    } catch (e) {
      emit(AppConfigurationFetchFailure(e.toString()));
    }
  }

  AppSystemSettingModel getAppConfiguration() {
    return (state is AppConfigurationFetchSuccess)
        ? (state as AppConfigurationFetchSuccess).appConfiguration
        : AppSystemSettingModel.fromJson({});
  }

  String? getBreakingNewsMode() {
    return ((state is AppConfigurationFetchSuccess))
        ? getAppConfiguration().breakNewsMode
        : "";
  }

  String? getLiveStreamMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().liveStreamMode
        : "";
  }

  String? getCategoryMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().catMode
        : "";
  }

  String? getSubCatMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().subCatMode
        : "";
  }

  String? getCommentsMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().commentMode
        : "";
  }

  String? getInAppAdsMode() {
    return (state is AppConfigurationFetchSuccess)
        ? ((Platform.isAndroid)
            ? getAppConfiguration().inAppAdsMode
            : getAppConfiguration().iosInAppAdsMode)
        : "";
  }

  String? getLocationWiseNewsMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().locationWiseNewsMode
        : "";
  }

  String? getWeatherMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().weatherMode
        : "";
  }

  String? getMaintenanceMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().maintenanceMode
        : "0";
  }

  String? checkAdsType() {
    if (getInAppAdsMode() == "1") {
      return (Platform.isIOS) ? getIOSAdsType() : getAdsType();
    }
    return null;
  }

  String? getAdsType() {
    if (state is AppConfigurationFetchSuccess) {
      switch (getAppConfiguration().adsType) {
        case "1":
          return "google";
        case "3":
          return "unity";
        default:
          return "";
      }
    }
    return "";
  }

  String? getIOSAdsType() {
    if (state is AppConfigurationFetchSuccess) {
      switch (getAppConfiguration().iosAdsType) {
        case "1":
          return "google";
        case "3":
          return "unity";
        default:
          return "";
      }
    }
    return "";
  }

  String? bannerId() {
    if (state is AppConfigurationFetchSuccess) {
      if (Platform.isAndroid && getInAppAdsMode() != "0") {
        if (getAdsType() == "google") return getAppConfiguration().goBannerId;
        if (getAdsType() == "unity") return getAppConfiguration().unityBannerId;
      }
      if (Platform.isIOS && getInAppAdsMode() != "0") {
        if (getIOSAdsType() == "google")
          return getAppConfiguration().goIOSBannerId;
        if (getIOSAdsType() == "unity")
          return getAppConfiguration().unityIOSBannerId;
      }
    }
    return "";
  }

  String? rewardId() {
    if (state is AppConfigurationFetchSuccess) {
      if (Platform.isAndroid && getInAppAdsMode() != "0") {
        if (getAdsType() == "google") return getAppConfiguration().goRewardedId;
        if (getAdsType() == "unity")
          return getAppConfiguration().unityRewardedId;
      }
      if (Platform.isIOS && getInAppAdsMode() != "0") {
        if (getIOSAdsType() == "google")
          return getAppConfiguration().goIOSRewardedId;
        if (getIOSAdsType() == "unity")
          return getAppConfiguration().unityIOSRewardedId;
      }
    }
    return "";
  }

  String? openAppId() {
    if (state is AppConfigurationFetchSuccess) {
      if (Platform.isAndroid && getInAppAdsMode() != "0") {
        if (getAdsType() == "google") return getAppConfiguration().goOpenAppId;
        if (getAdsType() == "unity") return ""; //no open app ads in unity
      }
      if (Platform.isIOS && getInAppAdsMode() != "0") {
        if (getIOSAdsType() == "google")
          return getAppConfiguration().goIOSOpenAppId;
        if (getIOSAdsType() == "unity") return ""; //no open app ads in unity
      }
      return "";
    }
    return "";
  }

  String? nativeId() {
    if (state is AppConfigurationFetchSuccess) {
      if (Platform.isAndroid && getInAppAdsMode() != "0") {
        if (getAdsType() == "google") return getAppConfiguration().goNativeId;
        if (getAdsType() == "unity") return ""; //no native ads in unity
      }
      if (Platform.isIOS && getInAppAdsMode() != "0") {
        if (getIOSAdsType() == "google")
          return getAppConfiguration().goIOSNativeId;
        if (getIOSAdsType() == "unity") return ""; //no native ads in unity
      }
    }
    return "";
  }

  String? interstitialId() {
    if (state is AppConfigurationFetchSuccess) {
      if (Platform.isAndroid && getInAppAdsMode() != "0") {
        if (getAdsType() == "google") return getAppConfiguration().goInterId;
        if (getAdsType() == "unity") return getAppConfiguration().unityInterId;
      }
      if (Platform.isIOS && getInAppAdsMode() != "0") {
        if (getIOSAdsType() == "google")
          return getAppConfiguration().goIOSInterId;
        if (getIOSAdsType() == "unity")
          return getAppConfiguration().unityIOSInterId;
      }
    }
    return "";
  }

  /// Last-resort interstitial frequency, used only if the backend sends no
  /// usable `ad_after_page_clicks`. The Admin Panel owns this value — this is
  /// a safety net so a backend regression degrades to sane throttling rather
  /// than an ad on every article open.
  static const int _fallbackAdAfterPageClicks = 2;

  /// How many article/page opens should pass between interstitial ads
  /// (`ad_after_page_clicks` from the Settings API). 1 = an ad on every open,
  /// 3 = every third open; 0 or less disables interstitials without switching
  /// off the other ad formats.
  int getAdAfterPageClicks() {
    if (state is! AppConfigurationFetchSuccess) {
      return _fallbackAdAfterPageClicks;
    }
    final value = getAppConfiguration().adAfterPageClicks;
    if (value == null || value.trim().isEmpty) {
      return _fallbackAdAfterPageClicks;
    }
    return int.tryParse(value.trim()) ?? _fallbackAdAfterPageClicks;
  }

  String? unityGameId() {
    return (Platform.isAndroid)
        ? getAppConfiguration().gameId
        : getAppConfiguration().iosGameId;
  }

  String? getRSSFeedMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().rssFeedMode
        : "";
  }

  String? getReelsMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().reelsMode
        : "";
  }

  String? getPodcastMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().podcastMode
        : "";
  }

  String? getMobileLoginMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().mobileLoginMode
        : "";
  }

  String? getCountryCode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().countryCode
        : "IN"; //India bydefault
  }

  String? getShareAppText() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().shareAppText
        : "";
  }

  String? getAppstoreId() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().appstoreId
        : "";
  }

  String? getiOSAppLink() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().iosAppLink
        : "";
  }

  String? getAndroidAppLink() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().androidAppLink
        : "";
  }

  /// Language code the Admin panel marks as default (`default_language` in
  /// the Settings API). Used as the fallback when content has not been
  /// translated into the language the user picked.
  String getDefaultLanguageCode() {
    return (state is AppConfigurationFetchSuccess)
        ? (getAppConfiguration().defaultLangDataModel?.code ?? "")
        : "";
  }

  VideoViewType? getVideoTypePreference() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().videoTypePreference
        : VideoViewType.normal;
  }

  String? getForceUpdateMode() {
    return (state is AppConfigurationFetchSuccess)
        ? getAppConfiguration().forceUpdateMode
        : "";
  }

  bool needsUpdate(String enforceVersion) {
    final List<int> currentVersion = packageInfo.version
        .split('.')
        .map((String number) => int.parse(number))
        .toList();
    final List<int> enforcedVersion = enforceVersion
        .split('.')
        .map((String number) => int.parse(number))
        .toList();

    for (int i = 0; i < 3; i++) {
      if (enforcedVersion[i] > currentVersion[i]) {
        return true;
      } else if (currentVersion[i] > enforcedVersion[i]) {
        return false;
      }
    }
    return false;
  }

  String getGeminiAPiKey() {
    return ((state is AppConfigurationFetchSuccess))
        ? UiUtils.decryptKey(
            geminiKey: getAppConfiguration().googleGeminiApiKey)
        : "";
  }

  bool isUpdateRequired() {
    if (state is AppConfigurationFetchSuccess) {
      AppSystemSettingModel appConfig =
          (state as AppConfigurationFetchSuccess).appConfiguration;
      if (defaultTargetPlatform == TargetPlatform.android &&
              needsUpdate(appConfig.androidAppVersion ?? "") ||
          defaultTargetPlatform == TargetPlatform.iOS &&
              needsUpdate(appConfig.iosAppVersion ?? "")) {
        return true;
      }
    }
    return false;
  }
}
