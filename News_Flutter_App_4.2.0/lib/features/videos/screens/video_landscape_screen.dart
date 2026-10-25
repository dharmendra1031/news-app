import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:news/commons/widgets/video_play_container.dart';
import 'package:news/utils/system_ui_helper.dart';
import 'package:news/utils/ui_utils.dart';

class VideoLandscapeScreen extends StatefulWidget {
  final String contentType;
  final String contentValue;
  final Duration startTime;

  const VideoLandscapeScreen({
    super.key,
    required this.contentType,
    required this.contentValue,
    this.startTime = Duration.zero,
  });

  @override
  State<VideoLandscapeScreen> createState() => _VideoLandscapeScreenState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
      builder: (_) => VideoLandscapeScreen(
        contentType: arguments['contentType'] ?? "",
        contentValue: arguments['contentValue'] ?? "",
        startTime: arguments['startTime'] ?? Duration.zero,
      ),
    );
  }
}

class _VideoLandscapeScreenState extends State<VideoLandscapeScreen> {
  @override
  void initState() {
    super.initState();
    _setLandscapeMode();
  }

  void _setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restorePortraitMode() {
    // Bring both system bars back and repaint the nav bar in the app's theme
    // colour (immersiveSticky had hidden them for full-screen playback).
    SystemUiHelper.showNavBar();
    UiUtils.reapplyOverlayStyle();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _onBack() {
    _restorePortraitMode();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _restorePortraitMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _restorePortraitMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: VideoPlayContainer(
                contentType: widget.contentType,
                contentValue: widget.contentValue,
                autoPlay: true,
                isLandscape: true,
                lastPosition: widget.startTime,
              ),
            ),
            Positioned.directional(
              top: 16,
              start: 16,
              textDirection: Directionality.of(context),
              child: InkWell(
                onTap: _onBack,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.0),
                  child: Container(
                    height: 35,
                    width: 35,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_backspace_rounded,
                      color: UiUtils.getColorScheme(context).surface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
