import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/live_streaming/models/live_streaming_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/news/screens/news_detail/widgets/news_detail_app_bar.dart';
import 'package:news/features/videos/widgets/other_videos_card.dart';
import 'package:news/features/videos/widgets/video_card.dart';
import 'package:news/utils/ui_utils.dart';

class VideoDetailsScreen extends StatefulWidget {
  int from;
  LiveStreamingModel? liveModel;
  NewsModel? model;
  BreakingNewsModel? breakModel;
  List<NewsModel>? otherVideos;
  List<BreakingNewsModel>? otherBreakingVideos;
  List<LiveStreamingModel>? otherLiveVideos;

  VideoDetailsScreen(
      {super.key,
      this.model,
      required this.from,
      this.liveModel,
      this.breakModel,
      required this.otherVideos,
      this.otherLiveVideos,
      this.otherBreakingVideos});

  @override
  State<StatefulWidget> createState() => VideoDetailsState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => VideoDetailsScreen(
            from: arguments['from'],
            liveModel: arguments['liveModel'],
            model: arguments['model'],
            breakModel: arguments['breakModel'],
            otherVideos: arguments['otherVideos'],
            otherLiveVideos: arguments['otherLiveVideos'],
            otherBreakingVideos: arguments['otherBreakingVideos']));
  }
}

class VideoDetailsState extends State<VideoDetailsScreen> {
  // late VideoModel currentVideo;
  // late List<VideoModel> otherVideos;

  bool isLiveVideo = false, isBreakingNewsVideo = false, isNewsVideo = true;
  //FROM VAL 1 = news, 2 = liveNews , 3 = breakingNews

  @override
  void initState() {
    isLiveVideo = (widget.from == 2);
    isBreakingNewsVideo = (widget.from == 3);
    isNewsVideo = !(isLiveVideo || isBreakingNewsVideo);

    // currentVideo = widget.selectedVideo;
    // otherVideos = widget.videos.where((v) => v.id != currentVideo.id).toList();
    super.initState();
  }

  @override
  void dispose() {
    // set screen back to portrait mode
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  /// Same condition the old screen repeated for the heading and the list.
  bool get _hasOtherVideos =>
      (isLiveVideo &&
          widget.otherLiveVideos != null &&
          widget.otherLiveVideos!.isNotEmpty) ||
      ((widget.otherVideos != null && widget.otherVideos!.isNotEmpty) ||
          (widget.otherBreakingVideos != null &&
              widget.otherBreakingVideos!.isNotEmpty));

  int get _otherVideosCount => (isLiveVideo)
      ? widget.otherLiveVideos!.length
      : (widget.otherVideos != null && widget.otherVideos!.isNotEmpty)
          ? widget.otherVideos!.length
          : widget.otherBreakingVideos!.length;

  Future<void> _shareVideo() async {
    final NewsModel? model = widget.model;
    if (model == null) return;
    final bool isOnline = await InternetConnectivity.isNetworkAvailable();
    if (!mounted) return;
    if (isOnline) {
      UiUtils.shareNews(
          context: context,
          slug: model.slug ?? "",
          title: model.title ?? "",
          isVideo: true,
          isReels: false,
          videoId: model.id ?? "0",
          isBreakingNews: false,
          isNews: false);
    } else {
      showSnackBar(UiUtils.getTranslatedLabel(context, 'internetmsg'), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // FIGMA(3371-4337): Background/Primary screen (#EFEFEF in light), the same
    // top app bar as news details, then a 16px-padded column with 12px between
    // blocks.
    return Scaffold(
      backgroundColor: isDark ? darkBackgroundColor : backgroundColor,
      body: Column(
        children: [
          NewsDetailAppBar(
            titleKey: 'videoDetailsLbl',
            isFromBreak: !isNewsVideo,
            model: isNewsVideo ? widget.model : null,
            onBack: () => Navigator.of(context).pop(),
            onShare: _shareVideo,
            showShare: isNewsVideo && widget.model != null,
            // Hide the bookmark icon on the video details screen.
            // Code is kept intact in NewsDetailAppBar; only the rendering is
            // suppressed via showBookmark: false.
            showBookmark: false,
            lightBackgroundColor: backgroundColor,
            bookmarkAsset: 'nd_save2',
            bookmarkFilledAsset: 'nd_save2_filled',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VideoCard(
                      model: (widget.model != null) ? widget.model : null,
                      brModel:
                          (widget.breakModel != null) ? widget.breakModel : null,
                      liveModel:
                          (widget.liveModel != null) ? widget.liveModel : null),
                  if (_hasOtherVideos) ...[
                    const SizedBox(height: 12),
                    CustomTextLabel(
                        text: 'recentVidLbl',
                        textStyle: TextStyle(
                            color: UiUtils.getColorScheme(context).onPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 24 / 16)),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _otherVideosCount,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => OtherVideosCard(
                          brModel: (widget.otherBreakingVideos != null &&
                                  widget.otherBreakingVideos!.isNotEmpty)
                              ? widget.otherBreakingVideos![index]
                              : null,
                          model: (widget.otherVideos != null &&
                                  widget.otherVideos!.isNotEmpty)
                              ? widget.otherVideos![index]
                              : null,
                          liveModel: (widget.otherLiveVideos != null &&
                                  widget.otherLiveVideos!.isNotEmpty)
                              ? widget.otherLiveVideos![index]
                              : null),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
