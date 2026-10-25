import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';

class AppOpenAdManager {
  AppOpenAdManager(this._appConfigurationCubit);

  /// Held directly (instead of a [BuildContext]) so ad callbacks that fire
  /// after the owning widget is disposed never touch a dead element tree.
  final AppConfigurationCubit _appConfigurationCubit;

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = const Duration(hours: 4);

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;

  bool get isAdAvailable => _appOpenAd != null;

  void loadAd() {
    final adUnitId = _appConfigurationCubit.openAppId();

    if (adUnitId == null || adUnitId.isEmpty) return;

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (!isAdAvailable) {
      loadAd();
      return;
    }
    if (_isShowingAd) return;

    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AppOpenAd failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  /// Releases a cached ad that was loaded but never shown.
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}

/// Listens for app foreground events and shows app open ads.
class AppLifecycleReactor {
  final AppOpenAdManager appOpenAdManager;
  StreamSubscription<AppState>? _appStateSubscription;

  AppLifecycleReactor({required this.appOpenAdManager});

  void listenToAppStateChanges() {
    // Never stack listeners; a stale one would show the ad more than once.
    _appStateSubscription?.cancel();
    AppStateEventNotifier.startListening();
    _appStateSubscription =
        AppStateEventNotifier.appStateStream.listen(_onAppStateChanged);
  }

  void _onAppStateChanged(AppState appState) {
    if (appState == AppState.foreground) {
      const excludedRoutes = [
        Routes.addNews,
        Routes.editUserProfile,
        Routes.login
      ];
      if (excludedRoutes.contains(Routes.currentRoute)) {
        return;
      } else {
        appOpenAdManager.showAdIfAvailable();
      }
    }
  }

  void dispose() {
    _appStateSubscription?.cancel();
    _appStateSubscription = null;
  }
}
