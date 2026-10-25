import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:news/commons/cubits/app_system_setting_cubit.dart';

const AdRequest request = AdRequest(
  //static
  keywords: <String>['foo', 'bar'],
  contentUrl: 'http://foo.com/bar.html',
  nonPersonalizedAds: true,
);
int maxFailedLoadAttempts = 3;
InterstitialAd? _interstitialAd;
int _numInterstitialLoadAttempts = 0;

void createGoogleInterstitialAd(BuildContext context) {
  final adUnitId = context.read<AppConfigurationCubit>().interstitialId();
  debugPrint('[InterstitialAd] preload requested, adUnitId="$adUnitId"');
  if (context.read<AppConfigurationCubit>().interstitialId() != "") {
    InterstitialAd.load(
        adUnitId: context.read<AppConfigurationCubit>().interstitialId()!,
        request: request,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('[InterstitialAd] loaded and ready to show');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint(
                '[InterstitialAd] load FAILED (attempt $_numInterstitialLoadAttempts): $error');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts <= maxFailedLoadAttempts) {
              createGoogleInterstitialAd(context);
            }
          },
        ));
  }
}

void showGoogleInterstitialAd(BuildContext context) {
  if (_interstitialAd == null) {
    debugPrint(
        '[InterstitialAd] SKIPPED: frequency was reached but no ad is loaded yet');
    return;
  }
  debugPrint('[InterstitialAd] showing now');
  _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
    onAdShowedFullScreenContent: (InterstitialAd ad) =>
        debugPrint('ad onAdShowedFullScreenContent.'),
    onAdDismissedFullScreenContent: (InterstitialAd ad) {
      //debugPrint('$ad onAdDismissedFullScreenContent.');
      ad.dispose();
      createGoogleInterstitialAd(context);
    },
    onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
      //debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
      createGoogleInterstitialAd(context);
    },
  );
  _interstitialAd!.show();
  _interstitialAd = null;
}
