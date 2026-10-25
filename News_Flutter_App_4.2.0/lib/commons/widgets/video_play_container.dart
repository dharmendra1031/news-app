import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/reels/cubits/video_shorts_cubit.dart'
    show reelsLog;
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';

class VideoPlayContainer extends StatefulWidget {
  final String contentType, contentValue;
  final bool autoPlay;

  /// Loads an uploaded video without showing or playing it. Reels mount the
  /// next reel this way while the current one plays, so its video is already
  /// buffered when the swipe lands. Flip it to false to reveal the player and
  /// start playback. Ignored for other video types.
  final bool preload;
  final bool isLandscape;
  final String from;

  Duration lastPosition;

  VideoPlayContainer(
      {super.key,
      required this.contentType,
      required this.contentValue,
      this.autoPlay = true,
      this.preload = false,
      this.isLandscape = false,
      this.from = '',
      this.lastPosition = Duration.zero});
  @override
  VideoPlayContainerState createState() => VideoPlayContainerState();
}

class VideoPlayContainerState extends State<VideoPlayContainer> {
  bool playVideo = false;

  FlickManager? flickManager;
  YoutubePlayerController? _yc;

  late VideoPlayerController _controller;
  late final WebViewController webViewController;

  bool useFallbackPlayer = false;
  late final Player player;
  late final VideoController videoController;

  Timer? _loopResetTimer;
  static const int _loopResetIntervalSeconds = 720; // Reset every 12 minutes

  /// Set while a promoted preload is still opening, so it starts on its own
  /// once ready.
  VoidCallback? _playWhenReady;

  bool get _isPreloading =>
      widget.preload &&
      widget.contentType == videoTypeToString(VideoType.video_upload);

  // Temporary reels timing logs: file name of the video, and how long an
  // uploaded video takes to open.
  String get _logName => widget.contentValue.split('/').last;

  void _logWhenReady() {
    final createdAt = DateTime.now();
    reelsLog('${widget.preload ? 'PRELOAD' : 'LIVE (not preloaded)'} '
        'video created: $_logName');
    void listener() {
      if (!_controller.value.isInitialized) return;
      _controller.removeListener(listener);
      reelsLog('video opened in '
          '${DateTime.now().difference(createdAt).inMilliseconds}ms: '
          '$_logName');
    }

    _controller.addListener(listener);
  }

  @override
  void initState() {
    super.initState();
    initialisePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentType != videoTypeToString(VideoType.video_upload)) return;

    if (oldWidget.preload && !widget.preload) {
      if (widget.from == 'reels') {
        reelsLog('swipe landed, video '
            '${_controller.value.isInitialized ? 'READY (no spinner)' : 'NOT ready (spinner)'}'
            ': $_logName');
      }
      // Deferred: playing notifies Flick's listeners, which must not happen
      // while this frame is still building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.preload && widget.autoPlay) _startPlayback();
      });
    } else if (!oldWidget.preload && widget.preload) {
      _park();
    }
  }

  @override
  void dispose() {
    _loopResetTimer?.cancel();
    try {
      if (widget.contentType == videoTypeToString(VideoType.video_upload)) {
        final pendingPlay = _playWhenReady;
        if (pendingPlay != null) _controller.removeListener(pendingPlay);
        if (_controller.value.isInitialized && _controller.value.isPlaying) {
          _controller.pause();
        }
        flickManager?.flickControlManager?.exitFullscreen();
        flickManager?.dispose();
        flickManager = null;
      } else if (widget.contentType ==
              videoTypeToString(VideoType.video_youtube) ||
          widget.contentType == videoTypeToString(VideoType.url_youtube)) {
        _yc?.dispose();
        _yc = null;
      } else if (widget.contentType ==
              videoTypeToString(VideoType.video_other) ||
          widget.contentType == videoTypeToString(VideoType.url_other)) {
        webViewController.clearCache();
      }
    } catch (e, st) {
      debugPrint("Error during dispose: $e\n$st");
    }

    super.dispose();
  }

  void pausePlayback() {
    try {
      if (widget.contentType == videoTypeToString(VideoType.video_upload)) {
        if (_controller.value.isInitialized && _controller.value.isPlaying) {
          _controller.pause();
        }
      } else if (widget.contentType ==
              videoTypeToString(VideoType.video_youtube) ||
          widget.contentType == videoTypeToString(VideoType.url_youtube)) {
        _yc?.pause();
      }
    } catch (e, st) {
      debugPrint("Error pausing playback: $e\n$st");
    }
  }

  /// A reel the user just left: kept open but hidden, so swiping back to it
  /// doesn't reload the video. Stops it and rewinds while it is out of sight,
  /// so it is ready to start from the top again.
  void _park() {
    try {
      if (widget.from == 'reels') reelsLog('parked for swipe back: $_logName');
      if (useFallbackPlayer) {
        player.pause();
        player.seek(Duration.zero);
        return;
      }
      _dropPendingPlay();
      // Also safe before the video has finished opening: it then stays paused
      // once it does.
      _controller.pause();
      if (_controller.value.isInitialized &&
          _controller.value.position > Duration.zero) {
        _controller.seekTo(Duration.zero);
      }
    } catch (e, st) {
      debugPrint("Error parking video: $e\n$st");
    }
  }

  void _dropPendingPlay() {
    final pending = _playWhenReady;
    if (pending == null) return;
    _controller.removeListener(pending);
    _playWhenReady = null;
  }

  /// Starts an uploaded video that was loaded with [VideoPlayContainer.preload]
  /// once it is revealed.
  void _startPlayback() {
    try {
      if (useFallbackPlayer) {
        player.play();
        return;
      }
      _dropPendingPlay();
      if (_controller.value.isInitialized) {
        _controller.play();
        return;
      }
      // Still opening (slow connection): play as soon as it is ready rather
      // than sitting on a paused frame.
      void listener() {
        if (!_controller.value.isInitialized) return;
        _controller.removeListener(listener);
        _playWhenReady = null;
        if (mounted && !widget.preload) _controller.play();
      }

      _playWhenReady = listener;
      _controller.addListener(listener);
    } catch (e, st) {
      debugPrint("Error starting playback: $e\n$st");
    }
  }

  Duration getCurrentPosition() {
    try {
      if (widget.contentType == videoTypeToString(VideoType.video_upload)) {
        if (_controller.value.isInitialized) {
          return _controller.value.position;
        }
      } else if (widget.contentType ==
              videoTypeToString(VideoType.video_youtube) ||
          widget.contentType == videoTypeToString(VideoType.url_youtube)) {
        return _yc?.value.position ?? Duration.zero;
      }
    } catch (e, st) {
      debugPrint("Error getting playback position: $e\n$st");
    }
    return Duration.zero;
  }

  /// Seeks to [widget.lastPosition] once Flick has initialized the controller,
  /// then detaches itself. Does not call initialize() — Flick owns that.
  void _seekToLastPositionOnInit() {
    void listener() {
      if (!_controller.value.isInitialized) return;
      _controller.removeListener(listener);
      if (widget.lastPosition > Duration.zero) {
        _controller.seekTo(widget.lastPosition);
      }
    }

    _controller.addListener(listener);
  }

  Future<void> initializeMediaKit() async {
    player = Player();

    videoController = VideoController(player);

    await player.open(
      Media(widget.contentValue),
      play: !_isPreloading,
    );
  }

  initialisePlayer() {
    print(
        "content type = ${widget.contentType} & value = ${widget.contentValue}");
    if (widget.contentValue != "") {
      if (widget.contentType == videoTypeToString(VideoType.video_upload)) {
        try {
          _controller =
              VideoPlayerController.networkUrl(Uri.parse(widget.contentValue));
          _controller.setLooping(widget.from == 'reels');

          // Let FlickManager own initialization (autoInitialize defaults to true).
          // The controller must be initialized exactly once: calling
          // VideoPlayerController.initialize() a second time ourselves throws
          // "Bad state: Future already completed" and spins up a second native
          // ExoPlayer/decoder per video that leaks and eventually exhausts the
          // codec (NO_MEMORY). Flick's own init path also drives its loading UI,
          // so we don't initialize here.
          flickManager = FlickManager(
              videoPlayerController: _controller,
              autoPlay: widget.autoPlay && !_isPreloading,
              onVideoEnd: () {
                widget.lastPosition = Duration.zero;
              });

          if (widget.from == 'reels') {
            _startLoopResetTimer();
            _logWhenReady();
          }
        } catch (e) {
          initializeMediaKit();
          useFallbackPlayer = true;
          setState(() {
            // Trigger a rebuild to use the fallback player.
          });
        }

        // Resume from a saved position once Flick has initialized the
        // controller (e.g. landscape playback). Reels start at zero, so this
        // is a no-op there.
        if (widget.lastPosition > Duration.zero) {
          _seekToLastPositionOnInit();
        }
      } else if (widget.contentType ==
              videoTypeToString(VideoType.video_youtube) ||
          widget.contentType == videoTypeToString(VideoType.url_youtube)) {
        // Reels play chrome-free and on repeat like the uploaded ones do; the
        // card draws its own action bar over the player.
        final bool isFromReels = widget.from == 'reels';
        if (isFromReels) {
          reelsLog('YouTube reel created (never preloaded): '
              '${widget.contentValue}');
        }
        _yc = YoutubePlayerController(
            initialVideoId:
                YoutubePlayer.convertUrlToId(widget.contentValue) ?? "",
            flags: YoutubePlayerFlags(
                controlsVisibleAtStart: !isFromReels,
                hideControls: isFromReels,
                loop: isFromReels,
                autoPlay: widget.autoPlay,
                // Reels live inside a vertical PageView, and the player is a
                // WebView behind a platform view. Hybrid composition (the
                // package default) puts that WebView in the Android view
                // hierarchy, which makes the engine push the entire FlutterView
                // through a FlutterImageView copy every frame
                // (PlatformViewsController.initializeRootImageViewIfNeeded) —
                // that is what makes the page drag stutter while a YouTube reel
                // plays. The texture-layer path composites the WebView as an
                // ordinary Flutter layer, so the swipe stays smooth. Everywhere
                // else the player sits in a static box, so it keeps the default.
                useHybridComposition: !isFromReels,
                startAt: widget.lastPosition.inSeconds));
      } else if (widget.contentType ==
              videoTypeToString(VideoType.video_other) ||
          widget.contentType == videoTypeToString(VideoType.url_other)) {
        print("content type = ${widget.contentType}");
        print("content value = ${widget.contentValue}");
        webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(widget.contentValue));
      }
    }
  }

  void _startLoopResetTimer() {
    _loopResetTimer?.cancel();
    _loopResetTimer = Timer.periodic(
      Duration(seconds: _loopResetIntervalSeconds),
      (timer) {
        if (mounted &&
            _controller.value.isInitialized &&
            _controller.value.isPlaying) {
          _resetLoopingVideo();
        }
      },
    );
  }

  void _resetLoopingVideo() {
    if (!mounted || !_controller.value.isInitialized) return;

    final currentDuration = _controller.value.duration;
    if (currentDuration == Duration.zero) return;

    _controller.seekTo(Duration.zero).then((_) {
      debugPrint(
          'Reset looping video to prevent codec exhaustion on Android 15');
    }).catchError((e) {
      debugPrint('Error resetting loop: $e');
    });
  }

  /// The embedded YouTube iframe already fills its host box (the package's
  /// player HTML sizes it 100% x 100%), so the only thing shaping the video is
  /// the [AspectRatio] the package wraps around it — 16:9 unless told
  /// otherwise. On Reels that left a landscape band floating on a portrait
  /// page; handing the player the page's own aspect ratio instead lets YouTube
  /// fit the video to the full page, so a vertical short fills the screen the
  /// way the web panel shows it. A 16:9 clip still letterboxes, but the bars
  /// are now painted by the player itself rather than by the page.
  Widget _buildYoutubePlayer(BuildContext context, {required bool isFromReels}) {
    Widget playerWithRatio(double aspectRatio) => YoutubePlayer(
        controller: _yc!,
        aspectRatio: aspectRatio,
        showVideoProgressIndicator: false,
        progressIndicatorColor: Theme.of(context).primaryColor,
        bottomActions: const [],
        topActions: const []);

    if (!isFromReels) return playerWithRatio(16 / 9);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reels hand the player a tight, full-page box. Anything else (an
        // unbounded parent) would make the ratio meaningless, so fall back to
        // the screen's own shape rather than dividing by infinity.
        final bool hasBoundedBox = constraints.maxWidth.isFinite &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        return playerWithRatio(hasBoundedBox
            ? constraints.maxWidth / constraints.maxHeight
            : MediaQuery.sizeOf(context).aspectRatio);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nothing is mounted while preloading. The controller keeps opening in the
    // background, but the Flick widget (which claims the wakelock and system UI
    // when it mounts) only appears once the video is revealed.
    if (_isPreloading) return const SizedBox.shrink();

    final bool isFromReels = widget.from == 'reels';
    final Widget controlsWidget = isFromReels
        ? const SizedBox.shrink()
        : const Center(
            child: FlickPlayToggle(size: 50, color: Colors.white),
          );

    final Widget player = (widget.contentType ==
            videoTypeToString(VideoType.video_upload))
        ? (!useFallbackPlayer)
            ? FlickVideoPlayer(
                flickManager: flickManager!,
                // Keep BOTH system bars visible (nav bar included) so it shows
                // and stays theme-coloured on Reels, matching the rest of the app.
                systemUIOverlay: SystemUiOverlay.values,
                flickVideoWithControls: widget.isLandscape
                    ? FlickVideoWithControls(
                        videoFit: BoxFit.contain, controls: controlsWidget)
                    : FlickVideoWithControls(controls: controlsWidget),
                flickVideoWithControlsFullscreen: widget.isLandscape
                    ? FlickVideoWithControls(
                        videoFit: BoxFit.contain, controls: controlsWidget)
                    : null)
            : Video(
                controller: videoController,
              )
        : (widget.contentType == videoTypeToString(VideoType.video_youtube) ||
                widget.contentType == videoTypeToString(VideoType.url_youtube))
            ? _buildYoutubePlayer(context, isFromReels: isFromReels)
            : (widget.contentType == videoTypeToString(VideoType.url_other) ||
                    widget.contentType ==
                        videoTypeToString(VideoType.video_other))
                ? WebViewWidget(controller: webViewController)
                : const SizedBox.shrink();

    if (widget.isLandscape) {
      return SizedBox.expand(
        child: ColoredBox(
          color: Colors.black,
          child: Center(child: player),
        ),
      );
    }

    return player;
  }
}
