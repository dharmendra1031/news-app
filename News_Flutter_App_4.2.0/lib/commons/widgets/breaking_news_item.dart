import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';

class BreakNewsItem extends StatefulWidget {
  final BreakingNewsModel model;
  final int index;
  final List<BreakingNewsModel> breakNewsList;

  const BreakNewsItem(
      {super.key,
      required this.model,
      required this.index,
      required this.breakNewsList});

  @override
  BreakNewsItemState createState() => BreakNewsItemState();
}

class BreakNewsItemState extends State<BreakNewsItem> {
  late BannerAd _bannerAd;
  @override
  void initState() {
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1")
      createBannerAd();
    super.initState();
  }

  Widget newsData() {
    return Builder(builder: (context) {
      final colorScheme = UiUtils.getColorScheme(context);
      return Padding(
          padding:
              EdgeInsetsDirectional.only(top: widget.index == 0 ? 0 : 16.0),
          child: Column(children: [
            if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1")
              nativeAdsShow(),
            GestureDetector(
              onTap: () {
                List<BreakingNewsModel> newsList = [];
                newsList.addAll(widget.breakNewsList);
                newsList.removeAt(widget.index);
                Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                  "breakModel": widget.model,
                  "breakNewsList": newsList,
                  "isFromBreak": true,
                  "fromShowMore": false
                });
              },
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      color: colorScheme.primaryContainer.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CustomNetworkImage(
                        networkImageUrl: widget.model.image!,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height / 4.2,
                        fit: BoxFit.cover,
                        isVideo: false),
                    Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 10.0, vertical: 8.0),
                        child: CustomTextLabel(
                            text: widget.model.title!,
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: colorScheme.primaryContainer,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
          ]));
    });
  }

  BannerAd createBannerAd() {
    if (context.read<AppConfigurationCubit>().bannerId() != "") {
      _bannerAd = BannerAd(
        adUnitId: context.read<AppConfigurationCubit>().bannerId()!,
        request: const AdRequest(),
        size: AdSize.mediumRectangle,
        listener: BannerAdListener(
            onAdLoaded: (_) {},
            onAdFailedToLoad: (ad, err) {
              //debugPrint("error in loading Native ad $err");
              ad.dispose();
            },
            onAdOpened: (Ad ad) => debugPrint('Native ad opened.'),
            // Called when an ad opens an overlay that covers the screen.
            onAdClosed: (Ad ad) => debugPrint('Native ad closed.'),
            // Called when an ad removes an overlay that covers the screen.
            onAdImpression: (Ad ad) => debugPrint('Native ad impression.')),
      );
    }
    return _bannerAd;
  }

  Widget bannerAdsShow() {
    return AdWidget(key: UniqueKey(), ad: createBannerAd()..load());
  }

  Widget nativeAdsShow() {
    if (context.read<AppConfigurationCubit>().getInAppAdsMode() == "1" &&
        context.read<AppConfigurationCubit>().checkAdsType() != null &&
        context.read<AppConfigurationCubit>().getAdsType() != "unity" &&
        widget.index != 0 &&
        widget.index % nativeAdsIndex == 0) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Container(
              padding: const EdgeInsets.all(7.0),
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: context.read<AppConfigurationCubit>().checkAdsType() ==
                          "google" &&
                      (context.read<AppConfigurationCubit>().bannerId() != "")
                  ? bannerAdsShow()
                  : SizedBox.shrink()));
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return newsData();
  }
}
