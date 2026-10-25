import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/live_streaming/cubits/live_stream_cubit.dart';
import 'package:news/features/live_streaming/models/live_streaming_model.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/utils/ui_utils.dart';

class LiveStreaming extends StatefulWidget {
  List<LiveStreamingModel> liveNews;

  LiveStreaming({super.key, required this.liveNews});

  @override
  State<StatefulWidget> createState() => StateLive();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => LiveStreaming(liveNews: arguments['liveNews']));
  }
}

class StateLive extends State<LiveStreaming> {
  late final ScrollController liveStreamScrollController = ScrollController()
    ..addListener(_hasMoreLiveScrollListener);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    liveStreamScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            height: 45,
            isBackBtn: true,
            label: 'liveVideosLbl',
            horizontalPad: 15,
            isConvertText: true),
        body: mainListBuilder());
  }

  void _hasMoreLiveScrollListener() {
    if (liveStreamScrollController.position.atEdge &&
        !liveStreamScrollController.position.outOfRange) {
      if (liveStreamScrollController.position.pixels != 0) {
        if (context.read<LiveStreamCubit>().hasMoreLiveStream()) {
          final langCode =
              context.read<AppLocalizationCubit>().state.languageCode;
          context.read<LiveStreamCubit>().getMoreLiveStream(langCode: langCode);
        }
      }
    }
  }

  Widget mainListBuilder() {
    return BlocBuilder<LiveStreamCubit, LiveStreamState>(
        bloc: context.read<LiveStreamCubit>(),
        builder: (context, state) {
          if (state is LiveStreamFetchSuccess) {
            final liveList = state.liveStream;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView.separated(
                  controller: liveStreamScrollController,
                  itemBuilder: ((context, index) {
                    if (index == liveList.length - 1 &&
                        index != 0 &&
                        state.hasMore) {
                      if (state.hasMoreFetchError) {
                        return const SizedBox.shrink();
                      } else {
                        return Center(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 8.0),
                                child: UiUtils.showCircularProgress(
                                    true, Theme.of(context).primaryColor)));
                      }
                    }

                    List<LiveStreamingModel> liveVideos = List.from(liveList)
                      ..removeAt(index);

                    return Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 0 : 20),
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10.0)),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(Routes.newsVideo,
                                arguments: {
                                  "from": 2,
                                  "liveModel": liveList[index],
                                  "otherLiveVideos": liveVideos
                                });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomNetworkImage(
                                  networkImageUrl: liveList[index].image!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  isVideo: true,
                                  width: double.infinity),
                              const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.black45,
                                  child: Icon(Icons.play_arrow,
                                      size: 40, color: Colors.white)),
                              Positioned.directional(
                                textDirection: Directionality.of(context),
                                bottom: 10,
                                start: 20,
                                end: 20,
                                child: CustomTextLabel(
                                    text: liveList[index].title!,
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(color: secondaryColor),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 3.0);
                  },
                  itemCount: liveList.length),
            );
          }

          if (state is LiveStreamFetchFailure) {
            return Center(
                child: CustomTextLabel(
                    text: state.errorMessage,
                    textStyle: Theme.of(context).textTheme.bodyMedium));
          }

          return Center(
              child: UiUtils.showCircularProgress(
                  true, Theme.of(context).primaryColor));
        });
  }
}
