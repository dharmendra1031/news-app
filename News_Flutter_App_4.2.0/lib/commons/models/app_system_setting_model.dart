import 'package:news/commons/enums.dart';
import 'package:news/features/language/models/app_language_model.dart';
import 'package:news/core/constants/strings.dart';

class AppSystemSettingModel {
  String? breakNewsMode,
      liveStreamMode,
      catMode,
      subCatMode,
      commentMode,
      inAppAdsMode,
      iosInAppAdsMode,
      adsType,
      iosAdsType,
      adAfterPageClicks;
  String? goRewardedId, goInterId, goBannerId, goNativeId, goOpenAppId;
  String? goIOSRewardedId,
      goIOSInterId,
      goIOSBannerId,
      goIOSNativeId,
      goIOSOpenAppId;
  String? gameId, iosGameId;
  String? unityRewardedId,
      unityInterId,
      unityBannerId,
      unityIOSRewardedId,
      unityIOSInterId,
      unityIOSBannerId;
  String? locationWiseNewsMode, weatherMode, maintenanceMode, forceUpdateMode;
  LanguageModel? defaultLangDataModel;
  String? rssFeedMode,
      reelsMode,
      podcastMode,
      mobileLoginMode,
      countryCode,
      shareAppText,
      appstoreId,
      androidAppLink,
      iosAppLink;
  VideoViewType? videoTypePreference;
  String? androidAppVersion, iosAppVersion, googleGeminiApiKey;

  AppSystemSettingModel(
      {this.breakNewsMode,
      this.liveStreamMode,
      this.catMode,
      this.subCatMode,
      this.commentMode,
      this.inAppAdsMode,
      this.iosInAppAdsMode,
      this.adsType,
      this.iosAdsType,
      this.adAfterPageClicks,
      this.goRewardedId,
      this.goBannerId,
      this.goInterId,
      this.goNativeId,
      this.goOpenAppId,
      this.goIOSBannerId,
      this.goIOSInterId,
      this.goIOSNativeId,
      this.goIOSRewardedId,
      this.goIOSOpenAppId,
      this.gameId,
      this.iosGameId,
      this.unityRewardedId,
      this.unityInterId,
      this.unityBannerId,
      this.unityIOSRewardedId,
      this.unityIOSInterId,
      this.unityIOSBannerId,
      this.defaultLangDataModel,
      this.locationWiseNewsMode,
      this.weatherMode,
      this.maintenanceMode,
      this.rssFeedMode,
      this.reelsMode,
      this.podcastMode,
      this.mobileLoginMode,
      this.countryCode,
      this.shareAppText,
      this.appstoreId,
      this.androidAppLink,
      this.iosAppLink,
      this.videoTypePreference,
      this.forceUpdateMode,
      this.androidAppVersion,
      this.iosAppVersion,
      this.googleGeminiApiKey});

  factory AppSystemSettingModel.fromJson(Map<String, dynamic> json) {
    var defaultList = (json[DEFAULT_LANG]);

    LanguageModel defaultLangData;
    if (defaultList == null && defaultList.isEmpty) {
      defaultLangData = LanguageModel();
    } else {
      defaultLangData = LanguageModel.fromJson(defaultList);
    }

    return AppSystemSettingModel(
        breakNewsMode: json[BREAK_NEWS_MODE],
        liveStreamMode: json[LIVE_STREAM_MODE],
        catMode: json[CATEGORY_MODE],
        subCatMode: json[SUBCAT_MODE],
        commentMode: json[COMM_MODE],
        inAppAdsMode: json[ADS_MODE],
        iosInAppAdsMode: json[IOS_ADS_MODE],
        adsType: json[ADS_TYPE],
        iosAdsType: json[IOS_ADS_TYPE],
        adAfterPageClicks: json[AD_AFTER_PAGE_CLICKS]?.toString(),
        goRewardedId: json[GO_REWARDED_ID],
        goInterId: json[GO_INTER_ID],
        goBannerId: json[GO_BANNER_ID],
        goNativeId: json[GO_NATIVE_ID],
        goOpenAppId: json[GO_OPEN_APP_ID],
        goIOSRewardedId: json[IOS_GO_REWARDED_ID],
        goIOSNativeId: json[IOS_GO_NATIVE_ID],
        goIOSInterId: json[IOS_GO_INTER_ID],
        goIOSBannerId: json[IOS_GO_BANNER_ID],
        goIOSOpenAppId: json[IOS_GO_OPEN_APP_ID],
        gameId: json[U_AND_GAME_ID],
        iosGameId: json[IOS_U_GAME_ID],
        unityRewardedId: json[U_REWARDED_ID],
        unityInterId: json[U_INTER_ID],
        unityBannerId: json[U_BANNER_ID],
        unityIOSRewardedId: json[IOS_U_REWARDED_ID],
        unityIOSInterId: json[IOS_U_INTER_ID],
        unityIOSBannerId: json[IOS_U_BANNER_ID],
        defaultLangDataModel: defaultLangData,
        locationWiseNewsMode: json[LOCATION_WISE_NEWS_MODE],
        weatherMode: json[WEATHER_MODE],
        maintenanceMode: json[MAINTENANCE_MODE],
        rssFeedMode: json[RSS_FEED_MODE],
        reelsMode: json[NEWS_BUZZ_MODE],
        podcastMode: json[PODCAST_MODE],
        mobileLoginMode: json[MOBILE_LOGIN_MODE],
        countryCode: json[COUNTRY_CODE],
        shareAppText: json[SHARE_APP_TEXT],
        appstoreId: json[APPSTORE_ID],
        androidAppLink: json[WEB_SETTING][ANDROID_APP_LINK],
        iosAppLink: json[WEB_SETTING][IOS_APP_LINK],
        videoTypePreference: fromVideoTypeJson(json[VIDEO_TYPE_PREFERENCE]),
        forceUpdateMode: json[FORCE_UPDT_APP_MODE] ?? "0",
        androidAppVersion: json[ANDROID_APP_VERSION] ?? '',
        iosAppVersion: json[IOS_APP_VERSION] ?? '',
        googleGeminiApiKey: json[GEMINI_API_KEY]);
  }

  static VideoViewType? fromVideoTypeJson(String? value) {
    switch (value) {
      case 'normal_style':
        return VideoViewType.normal;
      case 'page_style':
        return VideoViewType.page;
      default:
        return null;
    }
  }
}
