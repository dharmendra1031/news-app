import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;
import 'package:news/core/routes/register_cubits.dart';
import 'package:news/core/routes/route_tracker.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/authentication/cubits/register_token_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/setting_cubit.dart';
import 'package:news/commons/cubits/theme_cubit.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/deep_link/reels_native_deep_link.dart';
import 'package:news/core/theme/app_theme.dart';
import 'package:news/features/podcast/repositories/podcast_download_data_source.dart';
import 'package:news/features/podcast/screens/widgets/podcast_mini_player.dart';
import 'package:news/firebase_options.dart';
import 'package:news/utils/system_ui_helper.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Global analytics instance
final FirebaseAnalytics firebaseAnalytics = FirebaseAnalytics.instance;

late PackageInfo packageInfo;

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Keep the system navigation bar visible app-wide (edge-to-edge) so it can be
  // painted to match the current theme via SystemUiOverlayStyle. Immersive
  // full-screen surfaces (Reels / landscape video) hide it themselves and
  // restore it on exit. (see SystemUiHelper / MainActivity).
  SystemUiHelper.showNavBar();

  MobileAds.instance.initialize();

  packageInfo = await PackageInfo.fromPlatform();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  await Hive.openBox(authBoxKey);

  await Hive.openBox(settingsBoxKey);

  await Hive.openBox(locationCityBoxKey);
  await Hive.openBox(videoPreferenceKey);

  // Podcast module: the downloads index (the only thing the module keeps on the
  // device — listening history and bookmarks both live on the server alone),
  // background-audio service (lock-screen + notification controls) and the
  // background download service.
  await Hive.openBox(podcastDownloadsBoxKey);
  // Leftover from when listening progress was stored on the device. Deleting it
  // costs nothing: every position it held was pushed to
  // `update_episode_listening_history` as it was recorded, and the History tab
  // reads them back from there.
  await Hive.deleteBoxFromDisk(podcastHistoryBoxKey);

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.news.wrteam.channel.audio',
    androidNotificationChannelName: 'Podcast playback',
    androidNotificationOngoing: true,
  );

  await PodcastDownloadDataSource().init();

  await ReelsNativeDeepLink.init();

  runApp(MultiBlocProvider(
      providers: RegisterCubits().providers, child: const MyApp()));
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // final pushNotificationService = PushNotificationService(context: context);
    // pushNotificationService.initialise();
    var brightness = PlatformDispatcher.instance.platformBrightness;

    if (SettingsLocalDataRepository().getCurrentTheme().isEmpty) {
      (brightness == Brightness.dark)
          ? context.read<ThemeCubit>().changeTheme(AppTheme.Dark)
          : context.read<ThemeCubit>().changeTheme(AppTheme.Light);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appTheme = context.read<ThemeCubit>().state.appTheme;
      UiUtils.setUIOverlayStyle(appTheme: appTheme);
    });
  }

  void getFCMID() {
    String currentFCMId =
        context.read<SettingsCubit>().getSettings().token.trim();
    if (currentFCMId.isEmpty)
      FirebaseMessaging.instance.getToken().then((token) async {
        if (!mounted) return;

        if (token != null) {
          context
              .read<RegisterTokenCubit>()
              .registerToken(fcmId: token, context: context);
          if (token != context.read<SettingsCubit>().getSettings().token) {
            context.read<SettingsCubit>().changeFcmToken(token);
          }
        }
      }).catchError((e) {
        // Handle error if needed
        print("Error getting FCM token: $e");
      });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      if (Hive.box(settingsBoxKey).get(currentLanguageCodeKey) != null ||
          Hive.box(settingsBoxKey).get(currentLanguageCodeKey) != "") {
        initializeDateFormatting();
        intl.Intl.defaultLocale = Hive.box(settingsBoxKey)
            .get(currentLanguageCodeKey); //set default Locale @Start
      }

      final currentTheme = context.watch<ThemeCubit>().state.appTheme;
      getFCMID();
      return BlocBuilder<AppLocalizationCubit, AppLocalizationState>(
        builder: (context, state) {
          return MaterialApp(
              navigatorKey: UiUtils.rootNavigatorKey,
              theme: appThemeData[currentTheme],
              // Switch theme instantly. Animating the cross-fade re-lerps every
              // theme color across the whole tree each frame, which janks on
              // image/list-heavy screens. Instant swap is smooth and lag-free.
              themeAnimationDuration: Duration.zero,
              debugShowCheckedModeBanner: false,
              initialRoute: Routes.splash,
              title: appName,
              navigatorObservers: [
                FirebaseAnalyticsObserver(analytics: firebaseAnalytics),
                // Tells the persistent podcast mini player which screen is on
                // top, since it lives above the Navigator and has no route.
                RouteTracker.instance,
              ],
              onGenerateRoute: Routes.onGenerateRouted,
              builder: (context, widget) {
                // On Android 15+ (target SDK 35+) edge-to-edge is enforced: the
                // OS ignores `systemNavigationBarColor` and draws the navigation
                // bar transparent. Paint the reserved nav-bar strip ourselves so
                // it matches the screen background the content sits on (the
                // dashboard's bottom bar now floats above this strip rather than
                // filling it) in both light and dark. On older Android the opaque
                // system bar covers this strip (harmless).
                final navBarStripColor =
                    Theme.of(context).scaffoldBackgroundColor;
                return ScrollConfiguration(
                    behavior: GlobalScrollBehavior(),
                    child: Directionality(
                        textDirection: state.isRTL == '' || state.isRTL == 0
                            ? TextDirection.ltr
                            : TextDirection.rtl,
                        child: ColoredBox(
                          color: navBarStripColor,
                          child: Padding(
                            // Use `paddingOf` (not `viewPaddingOf`) so this
                            // nav-bar spacing collapses to 0 while the keyboard
                            // is open. `viewPadding` ignores the keyboard and
                            // would leave a nav-bar-height gap above the keyboard
                            // (the Scaffold already insets by the keyboard height
                            // via resizeToAvoidBottomInset).
                            padding: EdgeInsets.only(
                              bottom: (!kIsWeb &&
                                      defaultTargetPlatform ==
                                          TargetPlatform.android)
                                  ? MediaQuery.paddingOf(context).bottom
                                  : 0,
                            ),
                            // The podcast mini player is mounted here, above
                            // the Navigator, so one instance floats over every
                            // screen and outlives route changes. It shows
                            // itself only while an episode is loaded.
                            child: PodcastMiniPlayerHost(child: widget!),
                          ),
                        )));
              });
        },
      );
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
