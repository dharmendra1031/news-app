import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/enums.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/commons/widgets/video_item.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/videos/cubits/videos_cubit.dart';
import 'package:news/features/videos/widgets/video_list_card.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/features/dashboard/widgets/app_bottom_nav_bar.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/utils/ui_utils.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({
    super.key,
    this.videos,
    this.currentVideo,
    this.initialIndex,
  });

  /// When [videos] is provided, [VideoScreen] will use this list instead of
  /// fetching from the API via [VideoCubit] in [initState].
  final List<NewsModel>? videos;

  /// Optionally mark the currently selected video when [videos] is provided.
  final NewsModel? currentVideo;

  /// Optionally specify the initial index within [videos] to show first.
  final int? initialIndex;

  @override
  VideoScreenState createState() => VideoScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const VideoScreen());
  }
}

class VideoScreenState extends State<VideoScreen> {
  late final PageController _videoScrollController = PageController()
    ..addListener(hasMoreVideoScrollListener);

  int currentIndex = 0;
  int totalItems = 0;
  String? initializedVideoId;
  late String latitude, longitude;
  VideoViewType? videoViewType;

  static const double _listPadding = 16.0;
  static const double _cardGap = 10.0;

  /// Single-column list of video cards.
  Widget _buildVideoList(BuildContext context, List<NewsModel> videos,
      {EdgeInsets? listBottomPadding}) {
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }
    return CustomScrollView(
      controller: _videoScrollController,
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(_listPadding, _listPadding,
              _listPadding, listBottomPadding?.bottom ?? _listPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(
                    bottom: index == videos.length - 1 ? 0.0 : _cardGap),
                child: VideoNewsCard(video: videos[index], videosList: videos),
              ),
              childCount: videos.length,
            ),
          ),
        ),
      ],
    );
  }

  void getVideos() {
    Future.delayed(Duration.zero, () {
      context.read<VideoCubit>().getVideo(
          langCode: context.read<AppLocalizationCubit>().state.languageCode,
          latitude: latitude,
          longitude: longitude);
    });
  }

  @override
  void initState() {
    videoViewType =
        context.read<AppConfigurationCubit>().getVideoTypePreference();

    setLatitudeLongitude();

    // If videos are injected (e.g. from SectionMoreNewsList), avoid calling API
    // in initState and use the provided list instead.
    if (widget.videos == null) {
      getVideos();
    } else {
      totalItems = widget.videos!.length;

      if (widget.initialIndex != null) {
        currentIndex = widget.initialIndex!.clamp(0, totalItems - 1);
      } else if (widget.currentVideo != null) {
        final idx = widget.videos!
            .indexWhere((v) => v.id != null && v.id == widget.currentVideo!.id);
        if (idx != -1) {
          currentIndex = idx;
        }
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _videoScrollController.dispose();
    super.dispose();
  }

  void setLatitudeLongitude() {
    latitude = SettingsLocalDataRepository().getLocationCityValues().first;
    longitude = SettingsLocalDataRepository().getLocationCityValues().last;
  }

  void hasMoreVideoScrollListener() {
    if (_videoScrollController.offset >=
            _videoScrollController.position.maxScrollExtent &&
        !_videoScrollController.position.outOfRange) {
      if (context.read<VideoCubit>().hasMoreVideo()) {
        context.read<VideoCubit>().getMoreVideo(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            latitude: latitude,
            longitude: longitude);
      } else {
        //debugPrint("No more videos");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            height: 44,
            isBackBtn: false,
            label: 'videosLbl',
            isConvertText: true),
        body: widget.videos != null
            ? _buildVideosFromList(videoViewType ?? VideoViewType.normal)
            : _buildVideos(videoViewType ?? VideoViewType.normal));
  }

  Widget _buildVideos(VideoViewType type) {
    return BlocBuilder<VideoCubit, VideoState>(builder: (context, state) {
      if (state is VideoFetchSuccess) {
        totalItems = state.video.length;
        if (type == VideoViewType.page) {
          return RefreshIndicator(
              onRefresh: () async {
                getVideos();
              },
              child: PageView.builder(
                  controller: _videoScrollController,
                  scrollDirection: Axis.vertical,
                  physics: PageScrollPhysics(),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    return _buildVideoContainer(
                        video: state.video[index],
                        hasMore: state.hasMore,
                        hasMoreVideoFetchError: state.hasMoreFetchError,
                        index: index,
                        totalCurrentVideo: state.video.length);
                  }));
        } else {
          return _buildVideoList(context, state.video,
              // Tab body: the last card must clear the floating bottom bar.
              listBottomPadding: EdgeInsets.only(
                  bottom: AppBottomNavBar.contentClearance(context)));
        }
      }
      if (state is VideoFetchFailure) {
        return ErrorContainerWidget(
            errorMsg: (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                : state.errorMessage,
            onRetry: getVideos);
      }
      return SizedBox.shrink();
    });
  }

  /// Build videos UI using an injected list instead of [VideoCubit].
  Widget _buildVideosFromList(VideoViewType type) {
    final videos = widget.videos ?? [];
    if (videos.isEmpty) {
      return const SizedBox.shrink();
    }

    if (type == VideoViewType.page) {
      return PageView.builder(
          controller: _videoScrollController,
          scrollDirection: Axis.vertical,
          physics: const PageScrollPhysics(),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            return VideoItem(model: videos[index]);
          });
    } else {
      return _buildVideoList(context, videos);
    }
  }

  _buildVideoContainer(
      {required NewsModel video,
      required int index,
      required int totalCurrentVideo,
      required bool hasMoreVideoFetchError,
      required bool hasMore}) {
    if (index == totalCurrentVideo - 1 && index != 0) {
      if (hasMore) {
        if (hasMoreVideoFetchError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
              child: IconButton(
                onPressed: () {
                  context.read<VideoCubit>().getMoreVideo(
                      langCode: context
                          .read<AppLocalizationCubit>()
                          .state
                          .languageCode,
                      latitude: SettingsLocalDataRepository()
                          .getLocationCityValues()
                          .first,
                      longitude: SettingsLocalDataRepository()
                          .getLocationCityValues()
                          .last);
                },
                icon: Icon(Icons.error, color: Theme.of(context).primaryColor),
              ),
            ),
          );
        } else {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 8.0),
                  child: UiUtils.showCircularProgress(
                      true, Theme.of(context).primaryColor)));
        }
      }
    }

    return VideoItem(model: video);
  }
}

class VideoNewsCard extends StatefulWidget {
  final NewsModel video;
  final List<NewsModel> videosList;
  const VideoNewsCard({
    super.key,
    required this.videosList,
    required this.video,
  });

  @override
  VideoNewsCardState createState() => VideoNewsCardState();
}

class VideoNewsCardState extends State<VideoNewsCard> {
  String? _timeAgo(NewsModel video) {
    final String raw = video.publishDate ?? video.date ?? '';
    if (raw.isEmpty) return null;
    try {
      return UiUtils.formatMyDateTime(DateTime.parse(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        List<NewsModel> videosList = List.from(widget.videosList)
          ..removeWhere((x) => x.id == widget.video.id);
        Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
          "from": 1,
          "model": widget.video,
          "otherVideos": videosList
        });
      },
      child: VideoListCard(
        imageUrl: widget.video.image ?? '',
        title: widget.video.title ?? '',
        timeAgo: _timeAgo(widget.video),
        views: widget.video.totalViews,
      ),
    );
  }
}
