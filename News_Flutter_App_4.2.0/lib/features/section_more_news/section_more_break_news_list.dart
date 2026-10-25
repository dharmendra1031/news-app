import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/commons/widgets/breaking_news_item.dart';
import 'package:news/commons/widgets/breaking_video_item.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/shimmer_news_list.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/homepage/cubits/section_by_id_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/commons/widgets/custom_appbar.dart';

class SectionMoreBreakingNewsList extends StatefulWidget {
  final String sectionId;
  final String title;

  const SectionMoreBreakingNewsList(
      {super.key, required this.sectionId, required this.title});

  @override
  State<StatefulWidget> createState() {
    return _SectionBreakingNewsState();
  }

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => SectionMoreBreakingNewsList(
            sectionId: arguments['sectionId'], title: arguments['title']));
  }
}

class _SectionBreakingNewsState extends State<SectionMoreBreakingNewsList> {
  late final ScrollController controller = ScrollController()
    ..addListener(hasMoreSectionScrollListener);
  Set<String> get locationValue =>
      SettingsLocalDataRepository().getLocationCityValues();

  @override
  void initState() {
    getSectionByData();
    super.initState();
  }

  void getSectionByData() {
    Future.delayed(Duration.zero, () {
      context.read<SectionByIdCubit>().getSectionById(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          sectionId: widget.sectionId,
          latitude: locationValue.first,
          longitude: locationValue.last);
    });
  }

  void hasMoreSectionScrollListener() {
    if (controller.position.maxScrollExtent == controller.offset) {
      if (context.read<SectionByIdCubit>().hasMoreSections() &&
          !(context.read<SectionByIdCubit>().state
              is SectionByIdFetchInProgress)) {
        context.read<SectionByIdCubit>().getMoreSectionById(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            sectionId: widget.sectionId);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  _buildSectionBreakingNewsContainer(
      {required BreakingNewsModel model,
      required String type,
      required int index,
      required List<BreakingNewsModel> newsList}) {
    return type == 'breaking_news'
        ? BreakNewsItem(model: model, index: index, breakNewsList: newsList)
        : BreakVideoItem(model: model);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          height: 45,
          isBackBtn: true,
          label: widget.title,
          horizontalPad: 15,
          isConvertText: false),
      body: BlocBuilder<SectionByIdCubit, SectionByIdState>(
        builder: (context, state) {
          if (state is SectionByIdFetchSuccess) {
            return Padding(
              padding: const EdgeInsetsDirectional.all(10.0),
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<SectionByIdCubit>().getSectionById(
                      sectionId: widget.sectionId,
                      langCode: context
                          .read<AppLocalizationCubit>()
                          .state
                          .languageCode,
                      latitude: locationValue.first,
                      longitude: locationValue.last);
                },
                child: ListView.builder(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: state.breakNewsModel.length,
                    itemBuilder: (context, index) {
                      return _buildSectionBreakingNewsContainer(
                          model: (state).breakNewsModel[index],
                          type: (state).type,
                          index: index,
                          newsList: (state).type == 'breaking_news'
                              ? state.breakNewsModel
                              : []);
                    }),
              ),
            );
          }
          if (state is SectionByIdFetchFailure) {
            return ErrorContainerWidget(
                errorMsg:
                    (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : state.errorMessage,
                onRetry: getSectionByData);
          }
          //state is SectionByIdFetchInProgress || state is SectionByIdInitial
          return ShimmerNewsList(isNews: false);
        },
      ),
    );
  }
}
