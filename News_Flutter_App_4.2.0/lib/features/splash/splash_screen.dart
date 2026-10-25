import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:news/features/dynamic_pages/cubits/privacy_terms_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/language/cubits/language_cubit.dart';
import 'package:news/features/language/cubits/language_json_cubit.dart';
import 'package:news/commons/cubits/setting_cubit.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/app_theme.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/core/constants/hive_box_keys.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    fetchAppConfigurations();
  }

  fetchAppConfigurations() {
    context.read<AppConfigurationCubit>().fetchAppConfiguration();
  }

  fetchLanguages({required AppConfigurationFetchSuccess state}) async {
    String currentLanguage =
        Hive.box(settingsBoxKey).get(currentLanguageCodeKey) ?? "";
    //state.appConfiguration.defaultLangDataModel!.code ?? ""; //
    if (currentLanguage == "" &&
        state.appConfiguration.defaultLangDataModel != null) {
      context.read<AppLocalizationCubit>().changeLanguage(
          state.appConfiguration.defaultLangDataModel!.code!,
          state.appConfiguration.defaultLangDataModel!.id!,
          state.appConfiguration.defaultLangDataModel!.isRTL!);
      context.read<LanguageJsonCubit>().fetchCurrentLanguageAndLabels(
          state.appConfiguration.defaultLangDataModel!.code!);
    } else {
      context
          .read<LanguageJsonCubit>()
          .fetchCurrentLanguageAndLabels(currentLanguage);
    }
  }

  @override
  void dispose() {
    // _splashIconController!.dispose();
    // _newsImgController!.dispose();
    // _slideControllerBottom!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //The splash always uses the light look (background = `backgroundColor`,
    //the Figma "Background/Primary" #EFEFEF) regardless of the device theme,
    //so the status bar icons must stay dark. AnnotatedRegion is used instead of
    //an imperative setSystemUIOverlayStyle() call because the latter can be
    //reset on the next frame, leaving the icons the wrong brightness.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: UiUtils.overlayStyleForTheme(AppTheme.Light),
      child: Scaffold(backgroundColor: backgroundColor, body: buildScale()),
    );
  }

  Future<void> navigationPage() async {
    Future.delayed(const Duration(seconds: 4), () async {
      final currentSettings = context.read<SettingsCubit>().state.settingsModel;
      if (context.read<AppConfigurationCubit>().getMaintenanceMode() == "1") {
        //app is in maintenance mode - no function should be performed
        Navigator.of(context).pushReplacementNamed(Routes.maintenance);
      } else if (currentSettings!.showIntroSlider) {
        Navigator.of(context).pushReplacementNamed(Routes.introSlider);
      } else {
        Navigator.of(context)
            .pushReplacementNamed(Routes.home, arguments: false);
      }
    });
  }

  Widget buildScale() {
    return BlocConsumer<AppConfigurationCubit, AppConfigurationState>(
        bloc: context.read<AppConfigurationCubit>(),
        listener: (context, state) {
          if (state is AppConfigurationFetchSuccess) {
            fetchLanguages(state: state);
            context.read<PrivacyTermsCubit>().getPrivacyTerms(
                langCode:
                    context.read<AppLocalizationCubit>().state.languageCode);
          }
        },
        builder: (context, state) {
          return BlocConsumer<LanguageJsonCubit, LanguageJsonState>(
              bloc: context.read<LanguageJsonCubit>(),
              listener: (context, state) {
                if (state is LanguageJsonFetchSuccess) {
                  navigationPage();
                  context
                      .read<LanguageCubit>()
                      .getLanguage(); //Load languages for dynamic link
                }
              },
              builder: (context, langState) {
                if (state is AppConfigurationFetchFailure) {
                  return ErrorContainerWidget(
                    errorMsg: (state.errorMessage
                            .contains(ErrorMessageKeys.noInternet))
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : state.errorMessage,
                    onRetry: () {
                      fetchAppConfigurations();
                    },
                  );
                } else if (langState is LanguageJsonFetchFailure) {
                  return ErrorContainerWidget(
                    errorMsg: (langState.errorMessage
                            .contains(ErrorMessageKeys.noInternet))
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : langState.errorMessage,
                    onRetry: () {
                      fetchLanguages(
                          state: state as AppConfigurationFetchSuccess);
                    },
                  );
                } else {
                  // Figma "Splash": logo + wordmark + tagline as a tight column,
                  // centred both horizontally and vertically on the screen.
                  // The Scaffold already paints the `backgroundColor` behind this.
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        splashLogoIcon(),
                        const SizedBox(height: 12),
                        newsTextIcon(),
                        const SizedBox(height: 6),
                        subTitle(),
                      ],
                    ),
                  );
                }
              });
        });
  }

  // Figma: 09_NEWS app icon, 100 x 100.
  Widget splashLogoIcon() => SvgPictureWidget(
      assetName: "splash_icon",
      height: 100.0,
      width: 100.0,
      fit: BoxFit.contain);

  // Figma: "News" wordmark, 107.6 x 32.43.
  Widget newsTextIcon() => SvgPictureWidget(
      assetName: "news", height: 32.43, width: 107.6, fit: BoxFit.contain);

  // Figma: "Fastest Trending News" — Roboto Regular 14 / line-height 24,
  // letter-spacing 0.5, Text/Primary, centred within the 206px column.
  // `textPrimaryColor` is hard-referenced (not read from Theme) because the
  // splash stays light even when the device is in dark mode.
  Widget subTitle() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 206),
        child: CustomTextLabel(
          text: 'fastTrendNewsLbl',
          textAlign: TextAlign.center,
          collapseWhitespace: true,
          textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                height: 24 / 14,
              ),
        ),
      );
}
