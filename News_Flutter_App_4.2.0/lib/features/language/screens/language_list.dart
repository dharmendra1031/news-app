import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive/hive.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/authentication/cubits/register_token_cubit.dart';
import 'package:news/commons/cubits/adspace/adspace_home_page_cubit.dart';
import 'package:news/features/dashboard/dashboard_screen.dart';
import 'package:news/features/dynamic_pages/cubits/privacy_terms_cubit.dart';
import 'package:news/features/homepage/cubits/general_news_cubit.dart';
import 'package:news/features/rss_feed/cubits/get_rss_feeds_cubit.dart';
import 'package:news/commons/cubits/setting_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/cubits/breaking_news_cubit.dart';
import 'package:news/features/news/cubits/short_news_cubit.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';

import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/features/language/cubits/language_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/homepage/cubits/feature_section_cubit.dart';
import 'package:news/features/language/cubits/language_json_cubit.dart';
import 'package:news/features/live_streaming/cubits/live_stream_cubit.dart';
import 'package:news/features/dynamic_pages/cubits/other_pages_cubit.dart';
import 'package:news/features/reels/cubits/video_shorts_cubit.dart';
import 'package:news/features/videos/cubits/videos_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';

class LanguageList extends StatefulWidget {
  final String? from;
  const LanguageList({super.key, this.from});

  @override
  LanguageListState createState() => LanguageListState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => LanguageList(from: arguments['from']));
  }
}

class LanguageListState extends State<LanguageList> {
  String? selLanCode, selLanId;
  late String latitude, longitude;
  int? selLanRTL;
  bool isNetworkAvail = true;

  @override
  void initState() {
    isNetworkAvailable();
    getLanguageData();
    setLatitudeLongitude();
    super.initState();
  }

  Future getLanguageData() async {
    Future.delayed(Duration.zero, () {
      context.read<LanguageCubit>().getLanguage();
    });
  }

  void setLatitudeLongitude() {
    latitude = SettingsLocalDataRepository().getLocationCityValues().first;
    longitude = SettingsLocalDataRepository().getLocationCityValues().last;
  }

  Widget getLangList() {
    return BlocBuilder<AppLocalizationCubit, AppLocalizationState>(
        builder: (context, stateLocale) {
      return BlocBuilder<LanguageCubit, LanguageState>(
          builder: (context, state) {
        if (state is LanguageFetchSuccess) {
          return ListView.separated(
              // FIGMA(2896-16361): list inset 16, cards spaced 16 apart
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: ((context, index) {
                final colorScheme = UiUtils.getColorScheme(context);
                final bool isSelected =
                    (selLanCode ?? stateLocale.languageCode) ==
                        state.language[index].code!;
                return InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onTap: () {
                    setState(() {
                      Intl.defaultLocale = state.language[index].code;
                      selLanCode = state.language[index].code!;
                      selLanId = state.language[index].id!;
                      selLanRTL = state.language[index].isRTL!;
                    });
                  },
                  // FIGMA(2896-16329/16357): white card, radius 8, padding 8;
                  // selected = secondary 10% fill + 1px secondary border.
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withOpacity(0.1)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : Colors.transparent),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // FIGMA(2896-16330): flag 65x39, radius 4, cover.
                        // Some languages have no flag uploaded in the CMS
                        // (API image is ""), so fall back to a bundled flag
                        // icon to avoid a blank/broken thumbnail.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: (state.language[index].image != null &&
                                  state.language[index].image!.isNotEmpty)
                              ? CustomNetworkImage(
                                  networkImageUrl:
                                      state.language[index].image!,
                                  isVideo: false,
                                  height: 39,
                                  fit: BoxFit.cover,
                                  width: 65)
                              : SvgPictureWidget(
                                  assetName: 'flag_icon',
                                  height: 39,
                                  width: 65,
                                  fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 16),
                        // FIGMA(2896-16331): Roboto Regular 16, tracking 0.15
                        CustomTextLabel(
                            text:
                                state.language[index].languageDisplayName ??
                                    state.language[index].language!,
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: colorScheme.primaryContainer,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.15)),
                      ],
                    ),
                  ),
                );
              }),
              separatorBuilder: (context, index) {
                return const SizedBox(height: 16.0);
              },
              itemCount: state.language.length);
        }
        if (state is LanguageFetchFailure) {
          return Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 30.0),
            child: ErrorContainerWidget(
                errorMsg:
                    (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : state.errorMessage,
                onRetry: getLanguageData),
          );
        }
        return const Padding(
            padding: EdgeInsets.only(bottom: 10.0, left: 30.0, right: 30.0),
            child: SizedBox.shrink());
      });
    });
  }

  saveBtn() {
    return BlocConsumer<LanguageJsonCubit, LanguageJsonState>(
        bloc: context.read<LanguageJsonCubit>(),
        listener: (context, state) {
          if (state is LanguageJsonFetchSuccess) {
            final langId =
                selLanId ?? context.read<AppLocalizationCubit>().state.id;
            final langCode = selLanCode ??
                context.read<AppLocalizationCubit>().state.languageCode;

            UiUtils.setDynamicStringValue(
              langCode,
              jsonEncode(state.languageJson),
            ).then((_) {
              // Update languageId
              homeScreenKey?.currentState?.languageId = langId;
              homeScreenKey?.currentState?.languageCode = langCode;

              // Fetch general data
              context.read<OtherPageCubit>().getOtherPage(
                  langCode: langCode,
                  defaultLangCode: context
                      .read<AppConfigurationCubit>()
                      .getDefaultLanguageCode());
              context.read<SectionCubit>().getSection(
                  langCode: langCode, latitude: latitude, longitude: longitude);
              context.read<LiveStreamCubit>().getLiveStream(langCode: langCode);
              context.read<GeneralNewsCubit>().getGeneralNews(
                  langCode: langCode, latitude: latitude, longitude: longitude);
              context.read<VideoCubit>().getVideo(
                  langCode: langCode, latitude: latitude, longitude: longitude);
              context.read<CategoryCubit>().getCategory(langCode: langCode);
              context.read<ShortNewsCubit>().fetchShortNews(langCode: langCode);

              // Conditional based on config
              final config = context.read<AppConfigurationCubit>();
              if (config.getReelsMode() == "1") {
                context
                    .read<VideoShortsCubit>()
                    .getVideoShorts(langCode: langCode);
              }
              if (config.getWeatherMode() == "1") {
                homeScreenKey?.currentState?.getWeatherData();
              }
              if (config.getRSSFeedMode() == "1") {
                // context.read<RSSFeedCubit>().getRSSFeed(langCode: langCode);
                context
                    .read<GetRssFeedsCubit>()
                    .getRssFeeds(languageCode: langCode);
              }
              if (config.getBreakingNewsMode() == "1") {
                context
                    .read<BreakingNewsCubit>()
                    .getBreakingNews(langCode: langCode);
              }
              context.read<AdSpaceHomePageCubit>().getAdspaceForHomePage(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode,
                  page: "home_page");

              context.read<PrivacyTermsCubit>().getPrivacyTerms(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode);

              // If user is logged in
              final auth = context.read<AuthCubit>();
              if (auth.getUserId() != "0") {
                context.read<LikeAndDisLikeCubit>().getLike(langCode: langCode);
                context.read<BookmarkCubit>().getBookmark(langCode: langCode);
                updateUserLanguageWithFCMid();
              }
            });

            if (widget.from != null &&
                widget.from == "firstLogin" &&
                context.read<CategoryCubit>().getCatList().isNotEmpty) {
              //check if it is firstLogin - then goto Home or else pop
              Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.managePref, (route) => false,
                  arguments: {"from": 2});
            } else if (widget.from == "firstLogin") {
              Navigator.of(context)
                  .pushReplacementNamed(Routes.home, arguments: false);
            } else {
              Navigator.pop(context);
            }
          }
        },
        builder: (context, state) {
          if (state is LanguageJsonFetchSuccess) {
            return InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                child: Container(
                    height: 45.0,
                    margin: const EdgeInsetsDirectional.all(20),
                    width: MediaQuery.of(context).size.width * 0.9,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(4.0)),
                    child: CustomTextLabel(
                        text: 'saveLbl',
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                color: backgroundColor,
                                fontWeight: FontWeight.bold))),
                onTap: () {
                  setState(() {
                    if (selLanCode != null &&
                        context
                                .read<AppLocalizationCubit>()
                                .state
                                .languageCode !=
                            selLanCode) {
                      context
                          .read<AppLocalizationCubit>()
                          .changeLanguage(selLanCode!, selLanId!, selLanRTL!);
                      context
                          .read<LanguageJsonCubit>()
                          .getLanguageJson(lanCode: selLanCode!);

                      Hive.box(settingsBoxKey)
                          .put(currentLanguageCodeKey, selLanCode ?? "");
                    } else {
                      if (widget.from != null &&
                          widget.from == "firstLogin" &&
                          context
                              .read<CategoryCubit>()
                              .getCatList()
                              .isNotEmpty) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.managePref, (route) => false,
                            arguments: {"from": 2});
                      } else if (widget.from == "firstLogin") {
                        Navigator.of(context).pushReplacementNamed(Routes.home,
                            arguments: false);
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  });
                });
          }
          return const SizedBox.shrink();
        });
  }

  void updateUserLanguageWithFCMid() async {
    String currentFCMId =
        context.read<SettingsCubit>().getSettings().token.trim();

    if (currentFCMId.isEmpty) {
      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        currentFCMId = newToken;
        context
            .read<RegisterTokenCubit>()
            .registerToken(fcmId: currentFCMId, context: context);
      }
    } else {
      context
          .read<RegisterTokenCubit>()
          .registerToken(fcmId: currentFCMId, context: context);
    }

    context.read<SettingsCubit>().changeFcmToken(currentFCMId);
  }

  isNetworkAvailable() async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      setState(() {
        isNetworkAvail = true;
      });
    } else {
      setState(() {
        isNetworkAvail = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            height: 45,
            isBackBtn: true,
            label: 'chooseLanLbl',
            horizontalPad: 15,
            isConvertText: true),
        bottomNavigationBar:
            (isNetworkAvail) ? saveBtn() : const SizedBox.shrink(),
        body: getLangList());
  }
}
