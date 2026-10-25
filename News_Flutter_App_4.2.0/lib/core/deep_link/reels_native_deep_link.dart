import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/widgets/loading_screen.dart';
import 'package:news/core/deep_link/share_deep_link.dart';
import 'package:news/utils/ui_utils.dart';

class ReelsNativeDeepLink {
  ReelsNativeDeepLink._();

  static const MethodChannel _channel =
      MethodChannel('com.news.wrteam/reels_deeplink');

  static String? _cachedFullUrl;

  /// Full reels URL from Android [Intent.data] or iOS universal link.
  static String? get cachedFullUrl => _cachedFullUrl;

  static Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onReelsLink' && call.arguments is String) {
        _cacheReelsUrl(call.arguments as String);
        _navigateWarmReelsLinkIfReady();
      }
    });

    try {
      final initial =
          await _channel.invokeMethod<String>('getInitialReelsLink');
      _cacheReelsUrl(initial);
    } catch (_) {}
  }

  static void _cacheReelsUrl(String? url) {
    if (url == null || url.trim().isEmpty) return;
    if (!_isReelsUrl(url)) return;
    _cachedFullUrl = url.trim();
  }

  static bool _isReelsUrl(String url) {
    return ShareDeepLink.isReelsPath(ShareDeepLink.uriFrom(url).path);
  }

  /// Reels only: recover full URL + `?slug=` when Flutter passes path-only route.
  static String resolveReelsRouteName(String routeName) {
    final trimmed = routeName.trim();
    if (trimmed.isEmpty || !_isReelsUrl(trimmed)) return trimmed;
    if (ShareDeepLink.parseSlug(trimmed) != null) return trimmed;

    final platformRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName.trim();
    if (platformRoute.isNotEmpty &&
        platformRoute != '/' &&
        platformRoute != trimmed &&
        _isReelsUrl(platformRoute)) {
      if (ShareDeepLink.parseSlug(platformRoute) != null) return platformRoute;
      if (platformRoute.length > trimmed.length) return platformRoute;
    }

    final native = _cachedFullUrl;
    if (native != null &&
        native.isNotEmpty &&
        ShareDeepLink.parseSlug(native) != null) {
      return native;
    }

    return trimmed;
  }

  static void _navigateWarmReelsLinkIfReady() {
    final url = _cachedFullUrl;
    if (url == null || ShareDeepLink.parseSlug(url) == null) return;

    void tryNavigate() {
      final context = UiUtils.rootNavigatorKey.currentContext;
      if (context == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tryNavigate());
        return;
      }
      if (Routes.currentRoute == Routes.splash) return;

      final path = ShareDeepLink.normalizeRouteName(url);
      final slug = ShareDeepLink.parseSlug(url)!;

      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => LoadingScreen(
            routeSettingsName: path,
            newsSlug: slug,
          ),
        ),
      );
    }

    tryNavigate();
  }
}
