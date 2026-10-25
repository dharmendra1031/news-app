import 'package:flick_video_player/flick_video_player.dart';
import 'package:news/features/homepage/models/feature_section_model.dart'; 
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/features/news/screens/news_details_video.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_parser/youtube_parser.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:news/utils/system_ui_helper.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/features/live_streaming/models/live_streaming_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/models/breaking_news_model.dart';

class NewsVideo extends StatefulWidget {
  int from;
  LiveStreamingModel? liveModel;
  NewsModel? model;
  BreakingNewsModel? breakModel;

  NewsVideo(
      {super.key,
      this.model,
      required this.from,
      this.liveModel,
      this.breakModel});

  @override
  State<StatefulWidget> createState() => StateVideo();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => NewsVideo(
            from: arguments['from'],
            liveModel: arguments['liveModel'],
            model: arguments['model'],
            breakModel: arguments['breakModel']));
  }
}

class StateVideo extends State<NewsVideo> {
  FlickManager? flickManager;
  YoutubePlayerController? _yc;
  bool _isNetworkAvail = true;

  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    checkNetwork();
    initialisePlayer();
  }

  initialisePlayer() {
    switch (widget.from) {
      case 1:
        if (widget.model!.contentValue != "" ||
            widget.model!.contentValue != null) {
          if (widget.model!.contentType ==
              videoTypeToString(VideoType.video_upload)) {
            _controller = VideoPlayerController.networkUrl(
                Uri.parse(widget.model!.contentValue!));
            flickManager = FlickManager(
                videoPlayerController: _controller!, autoPlay: true);
          } else if (widget.model!.contentType ==
              videoTypeToString(VideoType.video_youtube)) {
            _yc = YoutubePlayerController(
                initialVideoId:
                    YoutubePlayer.convertUrlToId(widget.model!.contentValue!) ??
                        "",
                flags: const YoutubePlayerFlags(
                    autoPlay: true, hideControls: false));
          }
        }
        break;
      case 2:
        if (widget.liveModel!.type ==
            videoTypeToString(VideoType.url_youtube)) {
          _yc = YoutubePlayerController(
              initialVideoId: getIdFromUrl(widget.liveModel!.url!) ?? "",
              flags: const YoutubePlayerFlags(
                  autoPlay: true, isLive: true, hideControls: false));
        }
        break;
      default:
        if (widget.breakModel!.contentValue != "" ||
            widget.breakModel!.contentValue != null) {
          if (widget.breakModel!.contentType ==
              videoTypeToString(VideoType.video_upload)) {
            _controller = VideoPlayerController.networkUrl(
                Uri.parse(widget.breakModel!.contentValue!));
            flickManager = FlickManager(
                videoPlayerController: _controller!, autoPlay: true);
          } else if (widget.breakModel!.contentType ==
              videoTypeToString(VideoType.video_youtube)) {
            _yc = YoutubePlayerController(
                initialVideoId: YoutubePlayer.convertUrlToId(
                        widget.breakModel!.contentValue!) ??
                    "",
                flags: const YoutubePlayerFlags(
                    autoPlay: true, hideControls: false));
          }
        }
    }
  }

  checkNetwork() async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      setState(() => _isNetworkAvail = true);
    } else {
      setState(() => _isNetworkAvail = false);
    }
  }

  @override
  void dispose() {
    // Restore both system bars and repaint the nav bar in the app's theme
    // colour after full-screen video playback.
    SystemUiHelper.showNavBar();
    UiUtils.reapplyOverlayStyle();
    if (_controller != null && _controller!.value.isPlaying)
      _controller!.pause();
    switch (widget.from) {
      case 1:
        if (widget.model!.contentType ==
            videoTypeToString(VideoType.video_upload)) {
          Future.delayed(const Duration(milliseconds: 10)).then((value) {
            flickManager!.flickControlManager!.exitFullscreen();
            flickManager!.dispose();
            _controller!.dispose();
            _controller = null;
            flickManager = null;
          });
        } else if (widget.model!.contentType ==
            videoTypeToString(VideoType.video_youtube)) {
          _yc!.dispose();
        }
        break;
      case 2:
        if (widget.liveModel!.type ==
            videoTypeToString(VideoType.url_youtube)) {
          _yc!.dispose();
        }
        break;
      default:
        if (widget.breakModel!.contentType ==
            videoTypeToString(VideoType.video_upload)) {
          _controller = null;
          flickManager!.dispose();
        } else if (widget.breakModel!.contentType ==
            videoTypeToString(VideoType.video_youtube)) {
          _yc!.dispose();
        }
    }
    Future.delayed(const Duration(milliseconds: 20)).then((value) {
      super.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true, //to show Landscape video fullscreen
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: InkWell(
              onTap: () {
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown
                ]);
                Navigator.of(context).pop();
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 20),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.0),
                      child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: UiUtils.getColorScheme(context)
                                  .primaryContainer,
                              shape: BoxShape.circle),
                          child: Icon(Icons.keyboard_backspace_rounded,
                              color:
                                  UiUtils.getColorScheme(context).surface)))),
            )),
        body: PopScope(
          canPop: true,
          onPopInvoked: (val) async {
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
            if (widget.from == 1 &&
                (widget.model!.contentType ==
                    videoTypeToString(VideoType.video_upload))) {
              _controller!.pause();

              Future.delayed(const Duration(milliseconds: 10)).then((value) {
                flickManager!.flickControlManager!.exitFullscreen();
                flickManager!.dispose();
                _controller!.dispose();
              });
            }
          },
          child: Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 15.0, end: 15.0, bottom: 5.0),
              child: _isNetworkAvail
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0)),
                      child: viewVideo())
                  : const Center(child: CustomTextLabel(text: 'internetmsg'))),
        ));
  }

  viewVideo() {
    const Widget playPauseOnlyControls = Center(
      child: FlickPlayToggle(size: 50, color: Colors.white),
    );

    Widget buildYoutube() => YoutubePlayer(
        controller: _yc!,
        showVideoProgressIndicator: false,
        progressIndicatorColor: Theme.of(context).primaryColor,
        bottomActions: const [],
        topActions: const []);

    return widget.from == 1
        ? widget.model!.contentType == videoTypeToString(VideoType.video_upload)
            ? FlickVideoPlayer(
                flickManager: flickManager!,
                flickVideoWithControls: const FlickVideoWithControls(
                    controls: playPauseOnlyControls),
                flickVideoWithControlsFullscreen: const FlickVideoWithControls(
                    videoFit: BoxFit.fitWidth, controls: playPauseOnlyControls))
            : widget.model!.contentType ==
                    videoTypeToString(VideoType.video_youtube)
                ? buildYoutube()
                : widget.model!.contentType ==
                        videoTypeToString(VideoType.video_other)
                    ? Center(
                        child: NewsDetailsVideo(
                            src: widget.model!.contentValue, type: "3"))
                    : const SizedBox.shrink()
        : widget.from == 2
            ? widget.liveModel!.type ==
                        videoTypeToString(VideoType.url_youtube) ||
                    widget.liveModel!.type ==
                        videoTypeToString(VideoType.url_other)
                ? buildYoutube()
                : Center(
                    child:
                        NewsDetailsVideo(src: widget.liveModel!.url, type: "3"))
            : widget.breakModel!.contentType ==
                    videoTypeToString(VideoType.video_upload)
                ? FlickVideoPlayer(
                    flickManager: flickManager!,
                    flickVideoWithControls: const FlickVideoWithControls(
                        controls: playPauseOnlyControls),
                    flickVideoWithControlsFullscreen:
                        const FlickVideoWithControls(
                            controls: playPauseOnlyControls))
                : widget.breakModel!.contentType ==
                        videoTypeToString(VideoType.video_youtube)
                    ? buildYoutube()
                    : widget.breakModel!.contentType ==
                            videoTypeToString(VideoType.video_other)
                        ? Center(
                            child: NewsDetailsVideo(
                                src: widget.breakModel!.contentValue,
                                type: "3"))
                        : const SizedBox.shrink();
  }
}
