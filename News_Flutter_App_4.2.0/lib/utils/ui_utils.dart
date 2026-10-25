import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/core/deep_link/share_deep_link.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/language/cubits/language_json_cubit.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/label_keys.dart';
import 'package:news/core/theme/app_theme.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/news/screens/news_detail/widgets/interstitial_ads/google_interstitial_ads.dart';
import 'package:news/features/news/screens/news_detail/widgets/interstitial_ads/unity_interstitial_ads.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class UiUtils {
  static GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Assigns [value] to [notifier] without ever notifying mid-frame.
  ///
  /// Navigator observers and `build` bodies both run while the tree is being
  /// built; rebuilding a listener from there throws. Defer to the end of the
  /// frame in that case.
  static void setNotifier<T>(ValueNotifier<T> notifier, T value) {
    if (notifier.value == value) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (notifier.value != value) notifier.value = value;
      });
      return;
    }
    notifier.value = value;
  }

  static bool _isShareInProgress = false;

  static Future<void> shareApp({required BuildContext context}) async {
    if (_isShareInProgress) return;
    _isShareInProgress = true;
    try {
      String str =
          "$appName\n\n${context.read<AppConfigurationCubit>().getShareAppText()}\n\n${context.read<AppConfigurationCubit>().getAndroidAppLink()}\n";
      bool isIOSAppLive = context
              .read<AppConfigurationCubit>()
              .getiOSAppLink()
              ?.trim()
              .isNotEmpty ??
          false;
      if (isIOSAppLive) {
        str += "\n\n${context.read<AppConfigurationCubit>().getiOSAppLink()}";
      }
      await Share.share(str,
          sharePositionOrigin: Rect.fromLTWH(
              0,
              0,
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2));
    } catch (e) {
      debugPrint('shareApp failed: $e');
    } finally {
      _isShareInProgress = false;
    }
  }

  static Future<void> setDynamicStringValue(String key, String value) async {
    Hive.box(settingsBoxKey).put(key, value);
  }

  static Future<void> setDynamicListValue(String key, String value) async {
    List<String>? valueList = getDynamicListValue(key);
    if (!valueList.contains(value)) {
      if (valueList.length > 4) valueList.removeAt(0);
      valueList.add(value);

      Hive.box(settingsBoxKey).put(key, valueList);
    }
  }

  static List<String> getDynamicListValue(String key) {
    return Hive.box(settingsBoxKey).get(key) ?? [];
  }

  static String getSvgImagePath(String imageName) {
    return "assets/images/svgImage/$imageName.svg";
  }

  static String getPlaceholderPngPath() {
    return "assets/images/placeholder.png";
  }

  static ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

// get app theme
  static String getThemeLabelFromAppTheme(AppTheme appTheme) {
    if (appTheme == AppTheme.Dark) {
      return darkThemeKey;
    }
    return lightThemeKey;
  }

  static AppTheme getAppThemeFromLabel(String label) {
    return (label == darkThemeKey) ? AppTheme.Dark : AppTheme.Light;
  }

  static String getTranslatedLabel(BuildContext context, String labelKey) {
    return context.read<LanguageJsonCubit>().getTranslatedLabels(labelKey);
  }

  static bool _isLoginOpening = false;

  static Future<void> loginRequired(BuildContext context) async {
    if (_isLoginOpening) return;

    _isLoginOpening = true;
    showSnackBar(UiUtils.getTranslatedLabel(context, 'loginReqMsg'), context);

    try {
      await Future.delayed(const Duration(milliseconds: 1000), () {
        return Navigator.of(context).pushNamed(Routes.login, arguments: {
          "isFromApp": true
        }); //pass isFromApp to get back to specified screen
      });
      return Future(() => null);
    } finally {
      _isLoginOpening = false;
    }
  }

  static Widget showCircularProgress(bool isProgress, Color color) {
    if (isProgress) {
      return Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color)));
    }
    return const SizedBox.shrink();
  }

  showUploadImageBottomsheet(
      {required BuildContext context,
      required VoidCallback? onCamera,
      required VoidCallback? onGallery}) {
    return showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        builder: (BuildContext buildContext) {
          return SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                    leading: SvgPictureWidget(
                      assetName: 'gallaryIcon',
                      width: 36,
                      height: 36,
                      assetColor: ColorFilter.mode(
                          UiUtils.getColorScheme(context)
                              .primaryContainer
                              .withOpacity(0.7),
                          BlendMode.srcIn),
                    ),
                    //Icon(Icons.photo_library, color: UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7)),
                    title: CustomTextLabel(
                        text: 'photoLibLbl',
                        textStyle: TextStyle(
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer,
                            fontSize: 16,
                            fontWeight: FontWeight.w400)),
                    onTap: onGallery),
                ListTile(
                    leading: SvgPictureWidget(
                      assetName: 'cameraIcon',
                      width: 36,
                      height: 36,
                      assetColor: ColorFilter.mode(
                          UiUtils.getColorScheme(context)
                              .primaryContainer
                              .withOpacity(0.7),
                          BlendMode.srcIn),
                    ),
                    //Icon(Icons.photo_camera, color: UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7)),
                    title: CustomTextLabel(
                        text: 'cameraLbl',
                        textStyle: TextStyle(
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer,
                            fontSize: 16,
                            fontWeight: FontWeight.w400)),
                    onTap: onCamera),
              ],
            ),
          );
        });
  }

  /// True when the timestamp has no time part (e.g. API sent `2024-06-01 00:00:00`).
  static bool _isMidnightDateOnly(DateTime input) {
    return input.hour == 0 &&
        input.minute == 0 &&
        input.second == 0 &&
        input.millisecond == 0 &&
        input.microsecond == 0;
  }

  static bool _isValidCalendarDate(DateTime input) {
    if (input.year < 1) return false;
    final normalized = DateTime(input.year, input.month, input.day);
    return normalized.year == input.year &&
        normalized.month == input.month &&
        normalized.day == input.day;
  }

  static String formatMyDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    final isPublisedDateOnly = dateTime.difference(
          DateTime(dateTime.year, dateTime.month, dateTime.day),
        ) ==
        Duration.zero;

    // If the date is older than 30 days, return the absolute date instead
    if (difference.inDays > 30 || isPublisedDateOnly) {
      return DateFormat('MMM dd,yyyy').format(dateTime); //yyyy-MM-dd
    }
    if (Intl.defaultLocale != null || Intl.defaultLocale!.isEmpty) {
      Intl.defaultLocale = 'en';
    }
    initializeDateFormatting(); //locale according to location

    final langCode = Hive.box(settingsBoxKey).get(currentLanguageCodeKey);

    // Otherwise, returns "just now", "5 minutes ago", "a month ago", etc.
    return timeago.format(dateTime, locale: langCode);
  }

  static String? convertToAgo(BuildContext context, DateTime input, int from) {
    //from - 0 : NewsItem,details, bookmarks & sectionStyle5 , 1 : Comments, 2: Notifications, 3: SectionStyle6
    if (Intl.defaultLocale != null || Intl.defaultLocale!.isEmpty) {
      Intl.defaultLocale = 'en';
    }
    initializeDateFormatting(); //locale according to location
    final langCode = Hive.box(settingsBoxKey).get(currentLanguageCodeKey);

    if (_isMidnightDateOnly(input) && _isValidCalendarDate(input)) {
      return DateFormat("MMM dd, yyyy", langCode).format(input);
    }

    Duration diff = DateTime.now().difference(input);
    bool isNegative = diff.isNegative;

    if (diff.inDays >= 365 && from == 1) {
      double years = calculateYearsDifference(input, DateTime.now());
      return "${years.toStringAsFixed(0)} ${getTranslatedLabel(context, 'years')} ${getTranslatedLabel(context, 'ago')}";
    } else {
      if (diff.inDays >= 1 || (isNegative && diff.inDays < 1)) {
        if (from == 0) {
          var newFormat = DateFormat("MMM dd, yyyy", langCode);
          final newsDate1 = newFormat.format(input);
          return newsDate1;
        } else if (from == 1) {
          int months = calculateMonthsDifference(input, DateTime.now());
          if ((months < 12 && diff.inDays >= 30) && !isNegative) {
            return "${months.toStringAsFixed(0)} ${getTranslatedLabel(context, 'months')} ${getTranslatedLabel(context, 'ago')}";
          } else if ((diff.inHours >= 1 && diff.inHours < 24)) {
            return "${getTranslatedLabel(context, 'about')} ${diff.inHours} ${getTranslatedLabel(context, 'hours')} ${input.minute} ${getTranslatedLabel(context, 'minutes')} ${getTranslatedLabel(context, 'ago')}";
          } else if ((isNegative && diff.inMinutes < 1)) {
            if (diff.inSeconds < 60 &&
                diff.inHours < 1 &&
                diff.inMinutes < 1 &&
                diff.inDays < 1) {
              return getTranslatedLabel(context, 'justNow');
              // return "${diff.inSeconds} ${getTranslatedLabel(context, 'seconds')} ${getTranslatedLabel(context, 'ago')}";
            } else {
              return "${getTranslatedLabel(context, 'about')} ${input.minute} ${getTranslatedLabel(context, 'minutes')} ${getTranslatedLabel(context, 'ago')}";
            }
          } else {
            return "${diff.inDays} ${getTranslatedLabel(context, 'days')} ${getTranslatedLabel(context, 'ago')}";
          }
        } else if (from == 2) {
          var newFormat =
              DateFormat("dd MMMM yyyy", langCode); //removed time from here
          final newsDate1 = newFormat.format(input);
          return newsDate1;
        } else if (from == 3) {
          var newFormat = DateFormat("MMMM dd, yyyy", langCode);
          final newNewsDate = newFormat.format(input);
          return newNewsDate;
        }
      } else if (diff.inHours >= 1 || (isNegative && diff.inMinutes < 1)) {
        if (input.minute == 00) {
          return "${diff.inHours} ${getTranslatedLabel(context, 'hours')} ${getTranslatedLabel(context, 'ago')}";
        } else {
          if (from == 2) {
            return "${getTranslatedLabel(context, 'about')} ${diff.inHours} ${getTranslatedLabel(context, 'hours')} ${input.minute} ${getTranslatedLabel(context, 'minutes')} ${getTranslatedLabel(context, 'ago')}";
          } else {
            return "${diff.inHours} ${getTranslatedLabel(context, 'hours')} ${input.minute} ${getTranslatedLabel(context, 'minutes')} ${getTranslatedLabel(context, 'ago')}";
          }
        }
      } else if (diff.inSeconds >= 1 && diff.inMinutes < 1) {
        return "${diff.inSeconds} ${getTranslatedLabel(context, 'seconds')} ${getTranslatedLabel(context, 'ago')}";
      } else if (diff.inMinutes >= 1 || (isNegative && diff.inMinutes < 1)) {
        return "${diff.inMinutes} ${getTranslatedLabel(context, 'minutes')} ${getTranslatedLabel(context, 'ago')}";
      } else {
        return getTranslatedLabel(context, 'justNow');
      }
    }
    return null;
  }

  static int calculateMonthsDifference(DateTime startDate, DateTime endDate) {
    int yearsDifference = endDate.year - startDate.year;
    int monthsDifference = endDate.month - startDate.month;

    return yearsDifference * 12 + monthsDifference;
  }

  static double calculateYearsDifference(DateTime startDate, DateTime endDate) {
    int monthsDifference = calculateMonthsDifference(startDate, endDate);
    return monthsDifference / 12;
  }

  /// Pluggable date picker theme builder for consistent styling across the app
  /// Usage: Theme(data: Theme.of(context).copyWith(datePickerTheme: UiUtils.buildDatePickerTheme(context)))
  static DatePickerThemeData buildDatePickerTheme(BuildContext context) {
    final colorScheme = getColorScheme(context);

    return DatePickerThemeData(
      // Base styling
      dayStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),

      // Header configuration
      headerBackgroundColor: colorScheme.primary,
      headerForegroundColor: colorScheme.onPrimary,

      // Today/Current date styling - ensures proper visibility
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary; // White text when selected
        }
        return colorScheme
            .primary; // Primary color when not selected - fixes white color issue
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary; // Primary background when selected
        }
        return Colors.transparent; // No background when not selected
      }),

      // Regular day styling
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary; // White text on selected days
        }
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withOpacity(0.38); // Disabled state
        }
        return colorScheme.onSurface; // Normal text color
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary; // Primary background for selected
        }
        return Colors.transparent; // Transparent for unselected
      }),

      // Year picker styling
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        return colorScheme.onSurface;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),

      // Weekday header styling
      weekdayStyle: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.6),
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  /// Pluggable themed date picker wrapper that applies consistent styling
  /// Fixes the currentDate white color issue across the entire app
  /// Usage: UiUtils.showThemedDatePicker(context: context, ...)
  static Future<DateTime?> showThemedDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? currentDate,
    String? helpText,
    String? cancelText,
    String? confirmText,
    Locale? locale,
    bool useRootNavigator = true,
  }) async {
    return await showDialog<DateTime>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: buildDatePickerTheme(context),
          ),
          child: DatePickerDialog(
            initialDate: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            currentDate: currentDate,
            helpText: helpText,
            cancelText: cancelText,
            confirmText: confirmText,
          ),
        );
      },
    );
  }

  static SystemUiOverlayStyle overlayStyleForTheme(AppTheme appTheme) {
    final bool isLight = appTheme == AppTheme.Light;
    // Match the app's own bottom navigation bar, which is painted with
    // `colorScheme.surface` (Light `secondaryColor` = white, Dark
    // `darkSecondaryColor`), so the system nav bar is the same colour in both
    // themes. (On target SDK 35+ this is a no-op — the colour is painted by the
    // ColoredBox strip in app.dart — but it keeps older Android matching too.)
    final Color navBarColor = isLight ? secondaryColor : darkSecondaryColor;
    // Derive the nav-bar icon brightness from the bar colour itself so the
    // Back/Home/Recents icons keep enough contrast on any theme (or if the
    // theme colours ever change): dark bar -> light icons, light bar -> dark.
    final Brightness navIconBrightness =
        ThemeData.estimateBrightnessForColor(navBarColor) == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor:
          (isLight ? backgroundColor : darkSecondaryColor).withOpacity(0.8),
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: navBarColor,
      systemNavigationBarDividerColor: navBarColor,
      systemNavigationBarIconBrightness: navIconBrightness,
      // Let our colour show through as-is instead of Android tinting it for
      // contrast (which would grey-out the bar on gesture-nav devices).
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );
  }

  /// The last overlay style applied via [setUIOverlayStyle], used to re-assert
  /// the themed system bars after a full-screen screen (video/reels) restores
  /// them on exit.
  static SystemUiOverlayStyle? _lastAppliedOverlayStyle;

  static setUIOverlayStyle({required AppTheme appTheme}) {
    final style = overlayStyleForTheme(appTheme);
    _lastAppliedOverlayStyle = style;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  /// Re-applies the most recently set themed overlay style. Call this after a
  /// screen that took over the system UI (immersive video/reels) hands it back,
  /// so the navigation bar returns to the app's current theme colour.
  static void reapplyOverlayStyle() {
    final style = _lastAppliedOverlayStyle;
    if (style != null) SystemChrome.setSystemUIOverlayStyle(style);
  }

  static userLogOut({required BuildContext contxt}) {
    final type = contxt.read<AuthCubit>().getType();
    // An empty or unrecognised stored type must still log the user out; email
    // only picks the plain Firebase sign-out.
    final provider = AuthProviders.values.firstWhere((p) => p.name == type,
        orElse: () => AuthProviders.email);
    contxt.read<BookmarkCubit>().resetState();
    contxt.read<LikeAndDisLikeCubit>().resetState();
    contxt.read<AuthCubit>().signOut(provider).then((value) {
      Navigator.of(contxt)
          .pushNamedAndRemoveUntil(Routes.login, (route) => false);
    });
  }

//widget for User Profile Picture in Comments
  static Widget setFixedSizeboxForProfilePicture(
      {required Widget childWidget}) {
    return SizedBox(height: 35, width: 35, child: childWidget);
  }

  static Future<bool> isValidLocale(String locale) async {
    try {
      await initializeDateFormatting(locale, null);
      DateFormat('EEEE', locale).format(DateTime.now()); // test formatting
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setValidDefaultLocale(String? locale) async {
    //print("locale check here - $locale - $currentLanguageCodeKey ");
    if (locale == null || locale.isEmpty || !(await isValidLocale(locale))) {
      Intl.defaultLocale = 'en';
    } else {
      Intl.defaultLocale = locale;
    }
    Hive.box(settingsBoxKey).put(currentLanguageCodeKey, Intl.defaultLocale);
  }

  static Future<void> checkIfValidLocale({required String langCode}) async {
    await setValidDefaultLocale(langCode); //pass langCode here
  }

  //Add & Edit News Screen
  //roundedRectangle dashed border widget
  static Widget dottedRRectBorder(
      {required Widget childWidget, required BuildContext context}) {
    return DottedBorder(
        options: RoundedRectDottedBorderOptions(
            color: getColorScheme(context).primaryContainer.withOpacity(0.4),
            radius: const Radius.circular(4),
            dashPattern: const [6, 3]),
        child: ClipRRect(child: Center(child: childWidget)));
  }

//Home Screen - featured sections
  static Widget setPlayButton(
      {required BuildContext context, double heightVal = 40}) {
    return SvgPictureWidget(
        assetName: "video_circle", height: heightVal, width: heightVal);
  }

  //Native Ads
  static BannerAd createBannerAd({required BuildContext context}) {
    return BannerAd(
        adUnitId: context.read<AppConfigurationCubit>().bannerId()!,
        request: const AdRequest(),
        size: AdSize.mediumRectangle,
        listener: BannerAdListener(
            onAdLoaded: (_) => debugPrint("native ad is Loaded !!!"),
            onAdFailedToLoad: (ad, err) {
              debugPrint("error in loading Native ad $err");
              ad.dispose();
            },
            onAdOpened: (Ad ad) => debugPrint('Native ad opened.'),
            // Called when an ad opens an overlay that covers the screen.
            onAdClosed: (Ad ad) => debugPrint('Native ad closed.'),
            // Called when an ad removes an overlay that covers the screen.
            onAdImpression: (Ad ad) => debugPrint('Native ad impression.')));
  }

  static Widget bannerAdsShow({required BuildContext context}) {
    return AdWidget(
        key: UniqueKey(), ad: createBannerAd(context: context)..load());
  }

  //Interstitial Ads

  /// Article/page opens counted since the last interstitial was shown. Session
  /// scoped: it starts over when the app process restarts.
  static int _pageClicksSinceLastAd = 0;

  /// Shows an interstitial once every `ad_after_page_clicks` opens (the value
  /// configured in the Admin Panel and returned by the Settings API). Every
  /// article/page open should call this — the frequency is enforced here, so
  /// call sites must not add their own counters.
  static showInterstitialAds({required BuildContext context}) {
    final appConfiguration = context.read<AppConfigurationCubit>();
    final inAppAdsMode = appConfiguration.getInAppAdsMode();
    if (inAppAdsMode != "1") {
      debugPrint(
          '[InterstitialAd] OFF: in_app_ads_mode="$inAppAdsMode" (needs "1") on ${Platform.isIOS ? "iOS" : "Android"}');
      return;
    }

    final adAfterPageClicks = appConfiguration.getAdAfterPageClicks();
    if (adAfterPageClicks <= 0) {
      debugPrint(
          '[InterstitialAd] OFF: ad_after_page_clicks=$adAfterPageClicks');
      return;
    }

    _pageClicksSinceLastAd++;
    debugPrint(
        '[InterstitialAd] page click $_pageClicksSinceLastAd/$adAfterPageClicks');
    if (_pageClicksSinceLastAd < adAfterPageClicks) return;
    _pageClicksSinceLastAd = 0;

    final adsType = appConfiguration.checkAdsType();
    debugPrint('[InterstitialAd] frequency reached, adsType="$adsType"');
    if (adsType == "google") {
      showGoogleInterstitialAd(context);
    } else {
      showUnityInterstitialAds(appConfiguration.interstitialId()!);
    }
  }

  static Future<void> shareNews(
      {required BuildContext context,
      required String title,
      required String slug,
      required bool isBreakingNews,
      required bool isNews,
      required bool isVideo,
      required String videoId,
      required bool isReels,
      bool isPodcast = false}) async {
    if (_isShareInProgress) return;
    _isShareInProgress = true;

    String contentType = "";
    if (isVideo) contentType = "video-news";
    // The web's reels page is `/<lang>/newsbuzz`; `/reels` is not a page there.
    if (isReels) contentType = ShareDeepLink.reelsPathSegment;
    if (isNews) contentType = "news";
    if (isBreakingNews) contentType = "breaking-news";
    // A podcast channel shares by its own slug, in the same `/<lang>/<type>/
    // <slug>?share=true` shape as news (e.g. `/en/podcast/top-of-the-morning`).
    if (isPodcast) contentType = "podcast";

    // The default header reads "Check out this news article:", which is wrong
    // for a podcast — it gets its own label key.
    String shareTextHeader = UiUtils.getTranslatedLabel(context,
        isPodcast ? 'sharePodcastTextHeaderLbl' : 'shareTextHeaderLbl');
    String shareLink = (isReels)
        ? "https://$shareNavigationWebUrl/${context.read<AppLocalizationCubit>().state.languageCode}/$contentType?slug=$slug&share=true"
        : "https://$shareNavigationWebUrl/${context.read<AppLocalizationCubit>().state.languageCode}/$contentType/$slug?share=true";

    String str =
        "$title\n\n${context.read<AppConfigurationCubit>().getShareAppText()}\n\n$appName\n\n${context.read<AppConfigurationCubit>().getAndroidAppLink()}\n";

//${UiUtils.getTranslatedLabel(context, 'shareTextHeaderLbl')}\n/
    bool isIOSAppLive = context
            .read<AppConfigurationCubit>()
            .getiOSAppLink()
            ?.trim()
            .isNotEmpty ??
        false;
    if (isIOSAppLive)
      str += "\n\n${context.read<AppConfigurationCubit>().getiOSAppLink()}";
    str = shareTextHeader + "\n\n" + shareLink + "\n\n" + str;
    try {
      await Share.share(str,
          subject: appName,
          sharePositionOrigin: Rect.fromLTWH(
              0,
              0,
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2));
    } catch (e) {
      debugPrint('shareNews failed: $e');
    } finally {
      _isShareInProgress = false;
    }
  }

  static Widget applyBoxShadow({required BuildContext context, Widget? child}) {
    return Container(
        decoration: BoxDecoration(
          // Header/app-bar background. Figma dark header = Dark-card (#0E1B36),
          // NOT the darkest screen bg (#061024). canvasColor is now the screen
          // bg, so map explicitly to the Dark-card colour in dark mode and keep
          // the light canvasColor untouched.
          color: Theme.of(context).brightness == Brightness.dark
              ? darkSecondaryColor
              : Theme.of(context).canvasColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(0, 3),
                blurRadius: 6),
          ],
        ),
        child: child);
  }

  static String formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    final DateFormat formatter = DateFormat("MMMM d,yyyy");
    return formatter.format(dateTime);
  }

  static gotoStores(BuildContext context) async {
    String iosLink =
        context.read<AppConfigurationCubit>().getiOSAppLink() ?? "";
    String androidLink =
        context.read<AppConfigurationCubit>().getAndroidAppLink() ?? "";

    if (await canLaunchUrl(
        Uri.parse((Platform.isIOS) ? iosLink : androidLink))) {
      await launchUrl(Uri.parse((Platform.isIOS) ? iosLink : androidLink),
          mode: LaunchMode.externalApplication);
    }

    if (Navigator.of(context).canPop()) Navigator.of(context).pop(false);
  }

  static String decryptKey({required geminiKey}) {
    // Decode Base64 to bytes
    Uint8List bytes = base64.decode(geminiKey);

    // Convert bytes to String (if it's text)
    String decodedString = utf8.decode(bytes);
    return decodedString;
  }

  static Widget showCheckbox({
    required BuildContext context,
    required bool isSelected,
  }) {
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: const Color(0xFF5E6C8F),
          width: 1.2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            )
          : null,
    );
  }

  /// [showCheckbox] wrapped in a frame using [ColorScheme.secondary] (for list tiles).
  static Widget framedShowCheckbox({
    required BuildContext context,
    required bool isSelected,
  }) {
    return showCheckbox(
      context: context,
      isSelected: isSelected,
    );
  }
}

Widget nativeAdsShow({required BuildContext context, required int index}) {
  if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1" &&
      context.read<AppConfigurationCubit>().checkAdsType() != null &&
      (context.read<AppConfigurationCubit>().getIOSAdsType() != "unity" ||
          context.read<AppConfigurationCubit>().getAdsType() != "unity") &&
      index != 0 &&
      index % nativeAdsIndex == 0) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: Container(
            padding: const EdgeInsets.all(7.0),
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10.0)),
            child: context.read<AppConfigurationCubit>().checkAdsType() ==
                        "google" &&
                    (context.read<AppConfigurationCubit>().bannerId() != "")
                ? UiUtils.bannerAdsShow(context: context)
                : SizedBox.shrink()));
  } else {
    return const SizedBox.shrink();
  }
}
