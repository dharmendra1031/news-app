import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:news/features/add_edit_news/screens/add_news.dart';
import 'package:news/features/bookmarks/screens/bookmark_screen.dart';
import 'package:news/features/enews/screens/enews_pdf_viewer_screen.dart';
import 'package:news/features/enews/screens/enews_screen.dart';
import 'package:news/features/news/screens/image_preview_screen.dart';
import 'package:news/features/live_streaming/screens/live_streaming.dart';
import 'package:news/features/news/screens/news_detail/news_detail_screen.dart';
import 'package:news/features/news/screens/news_detail/widgets/show_more_news_list.dart';
import 'package:news/features/dynamic_pages/screens/privacy_policy_screen.dart';
import 'package:news/features/dynamic_pages/screens/contact_us_screen.dart';
import 'package:news/features/profile/user_profile.dart';
import 'package:news/features/rss_feed/screens/rssfeed_details_screen.dart';
import 'package:news/features/search/search.dart';
import 'package:news/features/add_edit_news/screens/manage_user_news.dart';
import 'package:news/features/subcategory/subcategory_screen.dart';
import 'package:news/features/news/screens/tag_news_screen.dart';
import 'package:news/features/videos/screens/video_landscape_screen.dart';
import 'package:news/features/videos/screens/video_details_screen.dart';
import 'package:news/features/category/screens/category_screen.dart';
import 'package:news/features/authentication/screens/forgot_password.dart';
import 'package:news/features/authentication/screens/request_otp_screen.dart';
import 'package:news/features/authentication/screens/verify_otp_screen.dart';
import 'package:news/features/author/screens/author_details_screen.dart';
import 'package:news/features/dashboard/dashboard_screen.dart';
import 'package:news/features/intro_slider/intro_slider.dart';
import 'package:news/features/language/screens/language_list.dart';
import 'package:news/features/settings/maintenance_screen.dart';
import 'package:news/features/splash/splash_screen.dart';
import 'package:news/features/preferences/screens/manage_preference.dart';
import 'package:news/features/podcast/screens/channel_detail_screen.dart';
import 'package:news/features/podcast/screens/create_episode_screen.dart';
import 'package:news/features/podcast/screens/create_podcast_screen.dart';
import 'package:news/features/podcast/screens/my_episodes_screen.dart';
import 'package:news/features/podcast/screens/my_podcasts_screen.dart';
import 'package:news/features/podcast/screens/podcast_dashboard_screen.dart';
import 'package:news/features/podcast/screens/podcast_player_screen.dart';
import 'package:news/features/alerts/screens/alerts_screen.dart';
import 'package:news/features/notification_preferences/screens/notification_preference_screen.dart';
import 'package:news/features/section_more_news/section_more_break_news_list.dart';
import 'package:news/features/section_more_news/section_more_news_list.dart';
import 'package:news/features/authentication/screens/login_screen.dart';
import 'package:news/commons/widgets/loading_screen.dart';
import 'package:news/core/deep_link/share_deep_link.dart';
import 'package:news/core/routes/route_tracker.dart';

class Routes {
  static const String splash = "splash";
  static const String home = "/";
  static const String introSlider = "introSlider";
  static const String languageList = "languageList";
  static const String login = "login";
  static const String privacy = "privacy";
  static const String contactUs = "contactUs";
  static const String search = "search";
  static const String live = "live";
  static const String category = "category";
  static const String subCat = "subCat";
  static const String requestOtp = "requestOtp";
  static const String verifyOtp = "verifyOtp";
  static const String managePref = "managePref";
  static const String newsVideo = "newsVideo";
  static const String bookmark = "bookmark";
  static const String newsDetails = "newsDetails";
  static const String imagePreview = "imagePreview";
  static const String videoLandscape = "videoLandscape";
  static const String tagScreen = "tagScreen";
  static const String addNews = "AddNews";
  static const String editNews = "editNews";
  static const String manageUserNews = "showNews";
  static const String forgotPass = "forgotPass";
  static const String sectionNews = "sectionNews";
  static const String sectionBreakNews = "sectionBreakNews";
  static const String showMoreRelatedNews = "showMoreRelatedNews";
  static const String editUserProfile = "editUserProfile";
  static const String maintenance = "maintenance";
  static const String rssFeedDetails = "rssFeedDetails";
  static const String authorDetails = "authorDetails";
  static const String eNews = "eNews";
  static const String eNewsPdfViewer = "eNewsPdfViewer";
  static const String podcastList = "podcastList";
  static const String myPodcasts = "myPodcasts";
  static const String myEpisodes = "myEpisodes";
  static const String createPodcast = "createPodcast";
  static const String createEpisode = "createEpisode";
  static const String podcastChannelDetail = "podcastChannelDetail";
  static const String podcastPlayer = "podcastPlayer";
  static const String alertsList = "alertsList";
  static const String notificationPreferences = "notificationPreferences";

  static String currentRoute = splash;
  static String previousRoute = "";

  static Route<dynamic> onGenerateRouted(RouteSettings routeSettings) {
    final Route<dynamic> route = _generateRoute(routeSettings);
    // Several `X.route()` factories below build their route without forwarding
    // [RouteSettings], so the name is handed to the tracker here instead of
    // being read back off the route later.
    RouteTracker.instance.registerRouteName(route, routeSettings.name);
    return route;
  }

  static Route<dynamic> _generateRoute(RouteSettings routeSettings) {
    previousRoute = currentRoute;
    currentRoute = routeSettings.name ?? "";

    if (ShareDeepLink.isShareDeepLink(routeSettings.name!)) {
      final effectiveRoute =
          ShareDeepLink.resolveRouteName(routeSettings.name!);
      final String? currNewsSlug = ShareDeepLink.parseSlug(effectiveRoute);
      final normalizedRoute = ShareDeepLink.normalizeRouteName(effectiveRoute);

      if (previousRoute == splash) {
        //app is closed
        isShared = true;

        routeSettingsName = normalizedRoute;
        newsSlug = currNewsSlug;
        debugPrint(
            '[ShareDeepLink] cold start link received: ${routeSettings.name}');
        return CupertinoPageRoute(builder: (_) => const Splash());
      } else {
        //app is running
        return CupertinoPageRoute(
            builder: (_) => LoadingScreen(
                routeSettingsName: normalizedRoute,
                newsSlug: currNewsSlug ?? ""));
      }
    }
    switch (routeSettings.name) {
      case splash:
        {
          return CupertinoPageRoute(builder: (_) => const Splash());
        }
      case home:
        {
          return DashBoard.route(routeSettings);
        }
      case introSlider:
        {
          return CupertinoPageRoute(builder: (_) => const IntroSliderScreen());
        }
      case login:
        {
          return LoginScreen.route(routeSettings);
        }
      case languageList:
        {
          return LanguageList.route(routeSettings);
        }
      case privacy:
        {
          return PrivacyPolicy.route(routeSettings);
        }
      case contactUs:
        {
          return ContactUsScreen.route(routeSettings);
        }
      case search:
        {
          return CupertinoPageRoute(builder: (_) => const Search());
        }
      case live:
        {
          return LiveStreaming.route(routeSettings);
        }
      case category:
        {
          return CupertinoPageRoute(builder: (_) => const CategoryScreen());
        }
      case subCat:
        {
          return SubCategoryScreen.route(routeSettings);
        }
      case requestOtp:
        {
          return CupertinoPageRoute(builder: (_) => const RequestOtp());
        }
      case verifyOtp:
        {
          return VerifyOtp.route(routeSettings);
        }
      case managePref:
        {
          return ManagePref.route(routeSettings);
        }
      case newsVideo:
        {
          return VideoDetailsScreen.route(routeSettings);
        }
      case bookmark:
        {
          return CupertinoPageRoute(builder: (_) => const BookmarkScreen());
        }
      case newsDetails:
        {
          return NewsDetailScreen.route(routeSettings);
        }
      case imagePreview:
        {
          return ImagePreview.route(routeSettings);
        }
      case videoLandscape:
        {
          return VideoLandscapeScreen.route(routeSettings);
        }
      case tagScreen:
        {
          return NewsTag.route(routeSettings);
        }
      case addNews:
        {
          return AddNews.route(routeSettings);
        }
      case manageUserNews:
        {
          return CupertinoPageRoute(builder: (_) => const ManageUserNews());
        }
      case forgotPass:
        {
          return CupertinoPageRoute(builder: (_) => const ForgotPassword());
        }

      case sectionNews:
        {
          return SectionMoreNewsList.route(routeSettings);
        }
      case podcastList:
        {
          return PodcastDashboardScreen.route(routeSettings);
        }
      case myPodcasts:
        {
          return MyPodcastsScreen.route(routeSettings);
        }
      case myEpisodes:
        {
          return MyEpisodesScreen.route(routeSettings);
        }
      case createPodcast:
        {
          return CreatePodcastScreen.route(routeSettings);
        }
      case createEpisode:
        {
          return CreateEpisodeScreen.route(routeSettings);
        }
      case podcastChannelDetail:
        {
          return ChannelDetailScreen.route(routeSettings);
        }
      case podcastPlayer:
        {
          return PodcastPlayerScreen.route(routeSettings);
        }
      case alertsList:
        {
          return AlertsScreen.route(routeSettings);
        }
      case notificationPreferences:
        {
          return NotificationPreferenceScreen.route(routeSettings);
        }
      case sectionBreakNews:
        {
          return SectionMoreBreakingNewsList.route(routeSettings);
        }
      case showMoreRelatedNews:
        {
          return ShowMoreNewsList.route(routeSettings);
        }
      case editUserProfile:
        {
          return UserProfileScreen.route(routeSettings);
        }
      case maintenance:
        {
          return CupertinoPageRoute(builder: (_) => const MaintenanceScreen());
        }
      case rssFeedDetails:
        {
          return RSSFeedDetailsScreen.route(routeSettings);
        }
      case authorDetails:
        {
          return AuthorDetailsScreen.route(routeSettings);
        }
      case eNews:
        {
          return ENewsScreen.route(routeSettings);
        }
      case eNewsPdfViewer:
        {
          return ENewsPdfViewerScreen.route(routeSettings);
        }

      default:
        {
          return CupertinoPageRoute(builder: (context) => const Scaffold());
        }
    }
  }
}
