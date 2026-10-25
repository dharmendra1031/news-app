import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-bleed blurred frame from a reel video URL (paused at first frame).
class ReelsBlurBackground extends StatefulWidget {
  final String? videoUrl;

  const ReelsBlurBackground({super.key, this.videoUrl});

  @override
  State<ReelsBlurBackground> createState() => _ReelsBlurBackgroundState();
}

class _ReelsBlurBackgroundState extends State<ReelsBlurBackground> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(ReelsBlurBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initController();
    }
  }

  void _initController() {
    final url = widget.videoUrl?.trim() ?? '';
    if (url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
      ),
    );
    _controller = controller;
    controller
      ..setLooping(false)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted || _controller != controller) {
          controller.dispose();
          return;
        }
        controller.pause();
        controller.seekTo(Duration.zero);
        setState(() {});
      }).catchError((Object _, StackTrace __) {
        if (_controller == controller) {
          controller.dispose();
          _controller = null;
        }
        if (mounted) setState(() {});
      });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Widget? _buildFrame() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final frame = _buildFrame();

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (frame != null)
            ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Transform.scale(
                  scale: 1.12,
                  child: frame,
                ),
              ),
            ),
          ColoredBox(color: Colors.black.withOpacity(0.35)),
        ],
      ),
    );
  }
}
