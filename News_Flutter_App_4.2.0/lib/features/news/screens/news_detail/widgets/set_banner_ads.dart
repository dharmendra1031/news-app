import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart' as unity;
import 'package:news/commons/cubits/app_system_setting_cubit.dart';

setBannerAd(BuildContext context, BannerAd? bannerAd) {
  if (context.read<AppConfigurationCubit>().bannerId() != "") {
    switch (context.read<AppConfigurationCubit>().checkAdsType()) {
      case "google":
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
          child: SizedBox(
              width: double.maxFinite,
              height: bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: bannerAd)),
        );

      case "unity":
        return unity.UnityBannerAd(
          placementId: context.read<AppConfigurationCubit>().bannerId()!,
          onLoad: (placementId) => debugPrint('Banner loaded: $placementId'),
          onClick: (placementId) => debugPrint('Banner clicked: $placementId'),
          onFailed: (placementId, error, message) =>
              debugPrint('Banner Ad $placementId failed: $error $message'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
