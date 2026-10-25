import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:news/commons/cubits/get_user_data_by_id_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/features/notification_preferences/repositories/notification_preferences_local_data_source.dart';
import 'package:news/features/dashboard/dashboard_screen.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/strings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:io';
import 'package:news/commons/cubits/news_by_id_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/core/app.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
FirebaseMessaging messaging = FirebaseMessaging.instance;
SettingsLocalDataRepository settingsRepo = SettingsLocalDataRepository();
NotificationPreferencesLocalDataSource notifPrefsRepo =
    NotificationPreferencesLocalDataSource();

/// The `type` values that mean "a new podcast episode" / "a market alert".
///
/// Two spellings each because the backend's actual string hasn't been confirmed
/// against a real push yet — drop the spare once it has. Keep these in step
/// with [NotificationPreferencesLocalDataSource.typeToPreferenceKey], which is
/// what decides whether the user wants them at all.
const List<String> _podcastPushTypes = <String>['podcast', 'podcast_episode'];
const List<String> _alertPushTypes = <String>['market_alert', 'alert'];

/// Marks a local-notification payload as "open this named route" rather than
/// "open this news article".
///
/// A local notification carries exactly one payload string, and the app has
/// always used it for a news id — so podcast and market-alert pushes, which
/// have no news id, prefix the route they want instead. Anything without the
/// prefix keeps being treated as a news id, see [selectNotificationPayload].
const String _routePayloadPrefix = 'route:';

String _routePayload(String routeName) => '$_routePayloadPrefix$routeName';

/// The list screen a podcast / market-alert push opens, or null for every other
/// type. Neither lands on a detail screen: their payload carries no episode or
/// alert id.
String? _routeForPushType(dynamic type) {
  if (_podcastPushTypes.contains(type)) return Routes.podcastList;
  if (_alertPushTypes.contains(type)) return Routes.alertsList;
  return null;
}

backgroundMessage(NotificationResponse notificationResponse) {
  //for notification only
  if (notificationResponse.input?.isNotEmpty ?? false) {
    debugPrint(
        'notification action tapped with input: ${notificationResponse.input}');
  }
  if (notificationResponse.payload!.isNotEmpty)
    debugPrint("payload is ${notificationResponse.payload}");
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (isDemo) {
    String sale = message.data['sale'];
    if (sale == "codecanyon") {
      //open webview or open link
      if (await canLaunchUrl(Uri.parse(saleLink))) {
        //To open link in other apps or outside of Current App
        //Add -> , mode: LaunchMode.externalApplication
        await launchUrl(Uri.parse(saleLink), mode: LaunchMode.inAppBrowserView);
      }
    }
  }

  debugPrint("background message received with type ${message.data[TYPE]}");
}

void redirectToNewsDetailsScreen(
    RemoteMessage message, BuildContext context) async {
  var data = message.data;

  if (isDemo) {
    String sale = message.data['sale'] ?? '';
    if (sale == "codecanyon") {
      //open webview or open link
      if (await canLaunchUrl(Uri.parse(saleLink))) {
        await launchUrl(Uri.parse(saleLink),
            mode: LaunchMode.externalApplication);
      }
    }
  }
  // Podcast / market-alert pushes have no article behind them — they open the
  // matching list screen instead.
  final String? route = _routeForPushType(data[TYPE]);
  if (route != null) {
    UiUtils.rootNavigatorKey.currentState?.pushNamed(route);
    return;
  }

  if (data[TYPE] == "default" || data[TYPE] == "category") {
    var payload = data[NEWS_ID];
    var lanCode = data[LANGUAGE_CODE] ?? "en";

    if (lanCode == context.read<AppLocalizationCubit>().state.languageCode) {
      //show only if Current language is Same as Notification Language
      if (payload == null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const MyApp()));
      } else {
        context
            .read<NewsByIdCubit>()
            .getNewsById(
                newsId: payload,
                langCode:
                    context.read<AppLocalizationCubit>().state.languageCode)
            .then((value) {
          UiUtils.rootNavigatorKey.currentState!.pushNamed(Routes.newsDetails,
              arguments: {
                "model": value[0],
                "isFromBreak": false,
                "fromShowMore": false
              });
        }).catchError((e) {
          //debugPrint(e.toString());
        });
      }
    }
  }
}

class PushNotificationService {
  late BuildContext context;

  PushNotificationService({required this.context});

  Future initialise() async {
    messaging.getToken();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_icon');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: false,
            requestSoundPermission: true);
    Future<dynamic> notificationHandler(RemoteMessage message) async {
      if (settingsRepo.getNotification()) {
        var data = message.data;

        var notif = message.notification;
        if (data.isNotEmpty) {
          var title = (data[TITLE] != null) ? data[TITLE].toString() : appName;
          var body = (data[MESSAGE] != null)
              ? data[MESSAGE].toString()
              : data[BODY].toString();
          var image = data[IMAGE];
          var payload = data[NEWS_ID];
          String lanCode = (data[LANGUAGE_CODE] != null)
              ? data[LANGUAGE_CODE].toString()
              : "en"; //en = ENGLISH bydefault
          (payload == null) ? payload = "" : payload = payload;
          // App-side per-type gate: honour the user's Notification Preferences.
          // A type the user switched off is dropped here; types with no
          // preference behind them (e.g. author status) always show. See
          // [NotificationPreferences]-repo.
          if (!notifPrefsRepo.shouldShowType(data[TYPE])) return;
          // Non-null for the two types that open a list screen instead of an
          // article — podcast episodes and market alerts.
          var pushRoute = _routeForPushType(data[TYPE]);
          if ((data[TYPE] == "default" ||
              data[TYPE] == "category" ||
              data[TYPE] == "comment" ||
              data[TYPE] == "comment_like" ||
              data[TYPE] == "newlyadded")) {
            if (lanCode ==
                context.read<AppLocalizationCubit>().state.languageCode) {
              //show only if Current language is Same as Notification Language
              (image != null && image != "")
                  ? generateImageNotification(title, body, image, payload)
                  : generateSimpleNotification(title, body, payload);
            }
          } else if (pushRoute != null) {
            // Deliberately NOT language-scoped the way articles are: an episode
            // or a market alert isn't published per language, and these
            // payloads carry no language_code — so the `lanCode` default of
            // "en" would hide them from every other locale.
            //
            // They carry no news id either, so the payload is a route marker
            // and the tap opens the list screen (see
            // [selectNotificationPayload]).
            var routePayload = _routePayload(pushRoute);
            (image != null && image != "")
                ? generateImageNotification(title, body, image, routePayload)
                : generateSimpleNotification(title, body, routePayload);
          } else if ((data[TYPE] == "author_approved") ||
              (data[TYPE] == "author_rejected")) {
            generateSimpleNotification(title, body, payload);
            Future.delayed(Duration.zero, () {
              context
                  .read<GetUserByIdCubit>()
                  .getUserById(); // update Author status
            });
          }
        } else if (notif != null) {
          //Direct Firebase Notification
          RemoteNotification notification = notif;
          String title = notif.title.toString();
          String msg = notif.body.toString();
          String iosImg = (notification.apple != null &&
                  notification.apple!.imageUrl != null)
              ? notification.apple!.imageUrl!
              : "";
          String androidImg = (notification.android != null &&
                  notification.android!.imageUrl != null)
              ? notification.android!.imageUrl!
              : "";
          if (title != '' && msg != '') {
            if (Platform.isIOS) {
              (iosImg != "")
                  ? generateImageNotification(
                      title, msg, notification.apple!.imageUrl!, '')
                  : generateSimpleNotification(title, msg, '');
            }
            if (Platform.isAndroid) {
              (androidImg != "")
                  ? generateImageNotification(
                      title, msg, notification.android!.imageUrl!, '')
                  : generateSimpleNotification(title, msg, '');
            }
          }
        }
      }
    }

    //for android 13 - notification permission
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    InitializationSettings initializationSettings =
        const InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      // initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationPayload(notificationResponse.payload!);
            break;
          case NotificationResponseType.selectedNotificationAction:
            //debugPrint("notification-action-id--->${notificationResponse.actionId}==${notificationResponse.payload}");
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: backgroundMessage,
    );
    messaging.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null && message.data.isNotEmpty) {
        isNotificationReceivedInbg = true;
        notificationNewsId = message.data[NEWS_ID];
        saleNotification = message.data['sale'] ?? '';
      }
    });

    _startForegroundService();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await notificationHandler(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      redirectToNewsDetailsScreen(message, context);
    });
  }

  Future<void> _startForegroundService() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('com.news.wrteam', 'news',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.startForegroundService(
            //'plain title', 'plain body',
            notificationDetails: androidNotificationDetails,
            payload: '',
            id: 1);
  }

  selectNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty || payload == "0") return;

    // Podcast / market-alert pushes name the screen to open instead of a news
    // id — see [_routePayload].
    if (payload.startsWith(_routePayloadPrefix)) {
      UiUtils.rootNavigatorKey.currentState
          ?.pushNamed(payload.substring(_routePayloadPrefix.length));
      return;
    }

    context
        .read<NewsByIdCubit>()
        .getNewsById(
            newsId: payload,
            langCode: context.read<AppLocalizationCubit>().state.languageCode)
        .then((value) {
      NewsModel model = value[0];
      UiUtils.rootNavigatorKey.currentState!.pushNamed(Routes.newsDetails,
          arguments: {
            "model": model,
            "isFromBreak": false,
            "fromShowMore": false
          });
    });
  }
}

Future<String> _downloadAndSaveImage(String url, String fileName) async {
  if (url.isNotEmpty && url != "null") {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final Response response = await get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  } else {
    //debugPrint("issue in downloading Notification image");
    return "";
  }
}

Future<void> generateImageNotification(
    String title, String msg, String image, String type) async {
  var largeIconPath = await _downloadAndSaveImage(
      image, Platform.isAndroid ? 'largeIcon' : 'largeIcon.png');
  var bigPicturePath = await _downloadAndSaveImage(
      image, Platform.isAndroid ? 'bigPicture' : 'bigPicture.png');
  var bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'big text channel id', 'big text channel name',
      channelDescription: 'big text channel description',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: bigPictureStyleInformation);
  final DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(
          categoryIdentifier: "",
          presentAlert: true,
          presentSound: true,
          attachments: <DarwinNotificationAttachment>[
        DarwinNotificationAttachment(bigPicturePath, hideThumbnail: false)
      ]);
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: darwinNotificationDetails);
  if (msg != "")
    await flutterLocalNotificationsPlugin.show(
        id: 1,
        title: title,
        body: msg,
        notificationDetails: platformChannelSpecifics,
        payload: type);
}

Future<void> generateSimpleNotification(
    String title, String msg, String type) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'com.news.wrteam', //your package name
      'news',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker');
  DarwinNotificationDetails darwinNotificationDetails =
      const DarwinNotificationDetails(
          categoryIdentifier: "", presentAlert: true, presentSound: true);
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: darwinNotificationDetails);
  if (msg.isNotEmpty)
    await flutterLocalNotificationsPlugin.show(
        id: 1,
        title: title,
        body: msg,
        notificationDetails: platformChannelSpecifics,
        payload: type);
}
