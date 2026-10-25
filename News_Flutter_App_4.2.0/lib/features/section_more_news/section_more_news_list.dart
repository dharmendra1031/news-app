import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/news_item.dart';
import 'package:news/commons/widgets/video_item.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/homepage/cubits/section_by_id_cubit.dart';
import 'package:news/commons/enums.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart'; 
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/videos/screens/video_screen.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/commons/widgets/shimmer_news_list.dart'; 

class SectionMoreNewsList extends StatefulWidget {
  final String sectionId;
  final String title;

  const SectionMoreNewsList(
      {super.key, required this.sectionId, required this.title});

  @override
  State<StatefulWidget> createState() {
    return _SectionNewsState();
  }

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => SectionMoreNewsList(
            sectionId: arguments['sectionId'], title: arguments['title']));
  }
}

class _SectionNewsState extends State<SectionMoreNewsList> {
  late final ScrollController controller = ScrollController()
    ..addListener(hasMoreSectionScrollListener);

  // Used when rendering videos in a vertical page view for non-news types.
  late final PageController _videoScrollController = PageController();

  Set<String> get locationValue =>
      SettingsLocalDataRepository().getLocationCityValues();

  bool _navigatedToVideos = false;

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
    _videoScrollController.dispose();
    super.dispose();
  }

  Widget _buildSectionNewsContainer(
      {required NewsModel model,
      required String type,
      required int index,
      required List<NewsModel> newsList}) {
    if (type == 'news' || type == 'user_choice' || type == 'author_news') {
      return NewsItem(
          model: model,
          index: index,
          newslist: newsList,
          fromShowMore: false,
          homeMeta: true);
    }
//check if video type is page or normal
    if (context.read<AppConfigurationCubit>().getVideoTypePreference() ==
        VideoViewType.page) {
      return VideoItem(model: model);
    } else {
      return Padding(
        // padding: const EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsetsDirectional.only(top: 15.0, start: 15, end: 15),
        child: VideoNewsCard(
          video: model,
          videosList: newsList,
        ),
      );
    }
  }

  Widget _buildVideoContainer(
      {required NewsModel video,
      required int index,
      required int totalCurrentVideo,
      required bool hasMoreVideoFetchError,
      required bool hasMore}) {
    // For now, simply reuse the standard video item widget.
    return VideoItem(model: video);
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
            // If this section is of type "videos", navigate to VideoScreen and
            // avoid refetching videos in its initState by passing the list.
            if (state.type == 'videos' && !_navigatedToVideos) {
              _navigatedToVideos = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(
                  CupertinoPageRoute(
                    builder: (_) => VideoScreen(
                      videos: state.newsModel,
                    ),
                  ),
                );
              });

              // While navigation is scheduled, render an empty widget.
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
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
                child: ((state).type == 'news' ||
                        (state).type == 'user_choice' ||
                        (state).type == 'author_news')
                    ? ListView.builder(
                        controller: controller,
                        physics: const AlwaysScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: state.newsModel.length,
                        itemBuilder: (context, index) {
                          return _buildSectionNewsContainer(
                              model: (state).newsModel[index],
                              type: (state).type,
                              index: index,
                              newsList: ((state).type == 'news' ||
                                      state.type == 'user_choice' ||
                                      (state).type == 'author_news')
                                  ? state.newsModel
                                  : []);
                        })
                    : PageView.builder(
                        controller: _videoScrollController,
                        scrollDirection: Axis.vertical,
                        physics: PageScrollPhysics(),
                        itemCount: state.newsModel.length,
                        itemBuilder: (context, index) {
                          return _buildVideoContainer(
                              video: (state).newsModel[index],
                              hasMore: state.hasMore,
                              hasMoreVideoFetchError: state.hasMoreFetchError,
                              index: index,
                              totalCurrentVideo: state.newsModel.length);
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
          return ShimmerNewsList(isNews: true);
        },
      ),
    );
  }
}
