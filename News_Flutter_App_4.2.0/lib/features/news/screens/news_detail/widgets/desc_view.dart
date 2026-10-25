import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:news/features/news/screens/news_details_video.dart'; 
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// Converts YouTube URLs to proper embed format to avoid error 153
String convertToYouTubeEmbedUrl(String? url) {
  if (url == null || url.isEmpty) return url ?? '';

  // Check if it's already an embed URL
  if (url.contains('youtube.com/embed/')) {
    // Ensure it has required parameters
    Uri uri = Uri.parse(url);
    Map<String, String> queryParams = Map.from(uri.queryParameters);
    queryParams['enablejsapi'] = '1';
    queryParams['origin'] =
        uri.host.isNotEmpty ? 'https://${uri.host}' : 'https://www.youtube.com';
    queryParams['rel'] = '0';
    queryParams['modestbranding'] = '1';
    return uri.replace(queryParameters: queryParams).toString();
  }

  // Extract video ID from various YouTube URL formats
  String? videoId = YoutubePlayer.convertUrlToId(url);
  if (videoId != null && videoId.isNotEmpty) {
    // Convert to embed URL with required parameters
    return 'https://www.youtube.com/embed/$videoId?enablejsapi=1&origin=https://www.youtube.com&rel=0&modestbranding=1';
  }

  // If not a YouTube URL, return as is
  return url;
}

/// Widget that plays video inline and detects fullscreen requests
class InlineVideoPlayer extends StatefulWidget {
  final String? src;
  final String? videoHtml;
  final String type;
  final BuildContext context;

  const InlineVideoPlayer({
    super.key,
    this.src,
    this.videoHtml,
    required this.type,
    required this.context,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  YoutubePlayerController? _youtubeController;
  String? _youtubeVideoId;
  InAppWebViewController? _webViewController;
  bool _wasYouTubePlaying = false;
  bool _wasWebViewVideoPlaying = false;
  Duration _currentPlaybackTime = Duration.zero; // Track current playback time
  Timer? _timeTrackingTimer; // Timer to periodically update current time

  @override
  void initState() {
    super.initState();
    // Check if it's a YouTube URL and initialize YouTube player
    // Always use native YouTube player for YouTube URLs to avoid error 153
    if (widget.type == "1" && widget.src != null) {
      // Check both original and converted URLs
      String? urlToCheck = widget.src;
      if (_isYouTubeUrl(urlToCheck!)) {
        _youtubeVideoId = YoutubePlayer.convertUrlToId(urlToCheck);
        if (_youtubeVideoId != null && _youtubeVideoId!.isNotEmpty) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: _youtubeVideoId!,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              controlsVisibleAtStart: true,
            ),
          );

          // Listen to player state changes to detect fullscreen
          _youtubeController!.addListener(_onYouTubePlayerStateChange);
        }
      }
    }

    // Start periodic time tracking
    _startTimeTracking();
  }

  void _startTimeTracking() {
    // Update current time periodically
    _timeTrackingTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Get current time from YouTube player
      if (_youtubeController != null) {
        _currentPlaybackTime = _youtubeController!.value.position;
        return;
      }

      // Get current time from webview video
      if (_webViewController != null) {
        try {
          String? timeStr =
              await _webViewController!.evaluateJavascript(source: '''
            (function() {
              var video = document.querySelector('video');
              if (video) {
                return Math.floor(video.currentTime);
              }
              return ${_currentPlaybackTime.inSeconds};
            })();
          ''');

          if (timeStr != null) {
            int seconds =
                int.tryParse(timeStr) ?? _currentPlaybackTime.inSeconds;
            _currentPlaybackTime = Duration(seconds: seconds);
          }
        } catch (e) {
          // Silently handle errors during time tracking
        }
      }
    });
  }

  void _onYouTubePlayerStateChange() {
    if (_youtubeController != null) {
      // Track playing state before fullscreen
      if (_youtubeController!.value.isPlaying && !_wasYouTubePlaying) {
        _wasYouTubePlaying = true;
      }

      if (_youtubeController!.value.isFullScreen) {
        // Player entered fullscreen, exit it and open in new screen
        _youtubeController!.toggleFullScreenMode();
        // Use a small delay to ensure fullscreen is exited, then pause and open
        Future.delayed(const Duration(milliseconds: 100), () async {
          // Get current time and pause if it was playing
          _currentPlaybackTime = _youtubeController!.value.position;
          if (_wasYouTubePlaying) {
            _youtubeController!.pause();
          }

          // Open fullscreen with current time
          final result = await Navigator.of(widget.context).push(
            MaterialPageRoute(
              builder: (context) => NewsDetailsVideo(
                src: widget.type == "1" ? widget.src : widget.videoHtml,
                type: widget.type,
                startTime: _currentPlaybackTime,
              ),
            ),
          );

          // Resume from the time returned from fullscreen
          Duration resumeTime =
              result is Duration ? result : _currentPlaybackTime;
          if (resumeTime.inSeconds > 0) {
            _youtubeController!.seekTo(resumeTime);
          }
          if (_wasYouTubePlaying) {
            _youtubeController!.play();
            _wasYouTubePlaying = false;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _timeTrackingTimer?.cancel();
    _youtubeController?.removeListener(_onYouTubePlayerStateChange);
    _youtubeController?.dispose();
    super.dispose();
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Future<Duration> _getCurrentPlaybackTime() async {
    // Get current playback time from YouTube video
    if (_youtubeController != null) {
      Duration time = _youtubeController!.value.position;
      _currentPlaybackTime = time; // Update tracked time
      return time;
    }

    // Get current playback time from webview video
    if (_webViewController != null) {
      try {
        String? timeStr =
            await _webViewController!.evaluateJavascript(source: '''
          (function() {
            var video = document.querySelector('video');
            var iframe = document.querySelector('iframe');
            
            if (video) {
              return Math.floor(video.currentTime);
            } else if (iframe) {
              // For iframes, we can't directly get time, return tracked time
              return ${_currentPlaybackTime.inSeconds};
            }
            return ${_currentPlaybackTime.inSeconds};
          })();
        ''');

        if (timeStr != null) {
          int seconds = int.tryParse(timeStr) ?? _currentPlaybackTime.inSeconds;
          Duration time = Duration(seconds: seconds);
          _currentPlaybackTime = time; // Update tracked time
          return time;
        }
      } catch (e) {
        debugPrint("Error getting playback time: $e");
      }
    }

    return _currentPlaybackTime;
  }

  Future<void> _pauseVideo() async {
    // Get current playback time before pausing
    _currentPlaybackTime = await _getCurrentPlaybackTime();

    // Pause YouTube video if playing
    if (_youtubeController != null && _youtubeController!.value.isPlaying) {
      _wasYouTubePlaying = true;
      _youtubeController!.pause();
    }

    // Pause webview videos (iframe or video element)
    if (_webViewController != null) {
      try {
        // Check if video/iframe is playing and pause it
        String? isPlaying =
            await _webViewController!.evaluateJavascript(source: '''
          (function() {
            var iframe = document.querySelector('iframe');
            var video = document.querySelector('video');
            
            if (video) {
              return !video.paused;
            } else if (iframe) {
              // For iframes, try to pause via postMessage
              try {
                iframe.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
              } catch(e) {
                return false;
              }
            }
            return false;
          })();
        ''');

        if (isPlaying == 'true') {
          _wasWebViewVideoPlaying = true;

          // Pause the video
          await _webViewController!.evaluateJavascript(source: '''
            (function() {
              var video = document.querySelector('video');
              var iframe = document.querySelector('iframe');
              
              if (video) {
                video.pause();
              } else if (iframe) {
                try {
                  iframe.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', '*');
                } catch(e) {
                  console.log('Error pausing iframe:', e);
                }
              }
            })();
          ''');
        }
      } catch (e) {
        debugPrint("Error pausing video: $e");
      }
    }
  }

  Future<void> _resumeVideo({Duration? fromTime}) async {
    // Use provided time or current tracked time
    Duration resumeTime = fromTime ?? _currentPlaybackTime;

    // Resume YouTube video if it was playing, seek to the time
    if (_youtubeController != null) {
      if (resumeTime.inSeconds > 0) {
        _youtubeController!.seekTo(resumeTime);
      }
      if (_wasYouTubePlaying) {
        _youtubeController!.play();
        _wasYouTubePlaying = false;
      }
    }

    // Resume webview videos if they were playing, seek to the time
    if (_webViewController != null) {
      try {
        await _webViewController!.evaluateJavascript(source: '''
          (function() {
            var video = document.querySelector('video');
            var iframe = document.querySelector('iframe');
            
            if (video) {
              video.currentTime = ${resumeTime.inSeconds};
              if (${_wasWebViewVideoPlaying}) {
                video.play().catch(function(e) {
                  console.log('Error resuming video:', e);
                });
              }
            } else if (iframe) {
              // For iframes, seek and play via postMessage
              try {
                iframe.contentWindow.postMessage('{"event":"command","func":"seekTo","args":[${resumeTime.inSeconds}, true]}', '*');
                if (${_wasWebViewVideoPlaying}) {
                  iframe.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                }
              } catch(e) {
                console.log('Error resuming iframe:', e);
              }
            }
          })();
        ''');
        _wasWebViewVideoPlaying = false;
      } catch (e) {
        debugPrint("Error resuming video: $e");
      }
    }
  }

  void _openFullScreen() async {
    // Get current playback time and pause video before opening fullscreen
    await _pauseVideo();

    // Open fullscreen with current playback time, wait for return with updated time
    final result = await Navigator.of(widget.context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailsVideo(
          src: widget.type == "1" ? widget.src : widget.videoHtml,
          type: widget.type,
          startTime: _currentPlaybackTime, // Pass current time to fullscreen
        ),
      ),
    );

    // Resume video from the time returned from fullscreen (or current time if no result)
    Duration resumeTime = result is Duration ? result : _currentPlaybackTime;
    await _resumeVideo(fromTime: resumeTime);
  }

  @override
  Widget build(BuildContext context) {
    // For YouTube videos, use native YouTube player to avoid error 153
    if (_youtubeController != null && _youtubeVideoId != null) {
      return Container(
        height: 220,
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: ClipRect(
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: false,
            progressIndicatorColor: Theme.of(context).primaryColor,
            bottomActions: const [],
            topActions: const [],
          ),
        ),
      );
    }

    String htmlContent;

    if (widget.type == "1") {
      // For iframes (non-YouTube)
      if (widget.src == null || widget.src!.isEmpty) {
        return Container(
          height: 220,
          width: MediaQuery.of(context).size.width,
          color: Colors.black87,
          child: Center(
            child: Text(
              'Video source not available',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      htmlContent = '''
        <html>
        <head>
        <script>
        document.addEventListener('fullscreenchange', function() {
          if (document.fullscreenElement) {
            // Fullscreen requested, notify Flutter
            window.flutter_inappwebview.callHandler('onFullscreenRequest');
          }
        });
        document.addEventListener('webkitfullscreenchange', function() {
          if (document.webkitFullscreenElement) {
            window.flutter_inappwebview.callHandler('onFullscreenRequest');
          }
        });
        document.addEventListener('mozfullscreenchange', function() {
          if (document.mozFullScreenElement) {
            window.flutter_inappwebview.callHandler('onFullscreenRequest');
          }
        });
        document.addEventListener('MSFullscreenChange', function() {
          if (document.msFullscreenElement) {
            window.flutter_inappwebview.callHandler('onFullscreenRequest');
          }
        });
        </script>
        </head>
        <body style="margin:0;padding:0;">
        <iframe src="${widget.src!}" allow="autoplay; fullscreen; picture-in-picture; encrypted-media" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen style="width:100%;height:100vh;border:none;"></iframe>
        </body>
        </html>
      ''';
    } else {
      // For video elements
      if (widget.videoHtml == null || widget.videoHtml!.isEmpty) {
        return Container(
          height: 220,
          width: MediaQuery.of(context).size.width,
          color: Colors.black87,
          child: Center(
            child: Text(
              'Video source not available',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }

      htmlContent = '''
        <html>
        <head>
        <script>
        var video;
        document.addEventListener('DOMContentLoaded', function() {
          video = document.querySelector('video');
          if (video) {
            video.addEventListener('webkitbeginfullscreen', function() {
              window.flutter_inappwebview.callHandler('onFullscreenRequest');
            });
            video.addEventListener('fullscreenchange', function() {
              if (document.fullscreenElement || document.webkitFullscreenElement) {
                window.flutter_inappwebview.callHandler('onFullscreenRequest');
              }
            });
          }
        });
        </script>
        </head>
        <body style="margin:0;padding:0;">
        ${widget.videoHtml!}
        </body>
        </html>
      ''';
    }

    return Container(
      height: 220,
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(data: htmlContent),
        // iOS otherwise jumps to the native full-screen player on play
        initialSettings: InAppWebViewSettings(allowsInlineMediaPlayback: true),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint("Console: ${consoleMessage.message}");
        },
        onLoadStop: (controller, url) async {
          // Add JavaScript handler for fullscreen requests
          controller.addJavaScriptHandler(
            handlerName: 'onFullscreenRequest',
            callback: (args) {
              // Exit webview fullscreen first
              controller.evaluateJavascript(source: '''
                if (document.exitFullscreen) {
                  document.exitFullscreen();
                } else if (document.webkitExitFullscreen) {
                  document.webkitExitFullscreen();
                } else if (document.mozCancelFullScreen) {
                  document.mozCancelFullScreen();
                } else if (document.msExitFullscreen) {
                  document.msExitFullscreen();
                }
              ''');

              // Open in new screen (will pause video automatically)
              _openFullScreen();
            },
          );
        },
      ),
    );
  }
}

/// CMS article bodies frequently contain whitespace-only blocks
/// (`<p>&nbsp;</p>`, `<p></p>`, empty `<div>`s) and long runs of `<br>` that
/// render as large empty gaps. Strip them so the article doesn't show extra
/// white space between paragraphs.
String cleanNewsHtml(String html) {
  var cleaned = html;
  final emptyBlock = RegExp(
    r'<(p|div)[^>]*>(?:\s|&nbsp;|<br\s*/?>)*</\1>',
    caseSensitive: false,
  );
  // A few passes collapse nested empties (e.g. an empty <p> inside an empty
  // <div>).
  for (var i = 0; i < 3; i++) {
    cleaned = cleaned.replaceAll(emptyBlock, '');
  }
  // Collapse runs of <br> into a single line break.
  cleaned = cleaned.replaceAll(
    RegExp(r'(?:<br\s*/?>\s*){2,}', caseSensitive: false),
    '<br>',
  );
  // Trim leading/trailing whitespace and <br>.
  cleaned = cleaned
      .replaceAll(
          RegExp(r'^(?:\s|&nbsp;|<br\s*/?>)+', caseSensitive: false), '')
      .replaceAll(
          RegExp(r'(?:\s|&nbsp;|<br\s*/?>)+$', caseSensitive: false), '');
  return cleaned.trim();
}

Widget descView(
    {required String desc,
    required double fontValue,
    required BuildContext context}) {
  // FIGMA(3768-8884 light / 3768-9010 dark): News/body/medium — Regular 14 / 20
  // in Text/Secondary, which is #676767 in light and #A0A0A0 in dark.
  final Color bodyColor = Theme.of(context).brightness == Brightness.dark
      ? textTertiaryColor
      : textSecondaryColor;
  return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: HtmlWidget(
        cleanNewsHtml(desc),
        // Replace the default ~1em paragraph margins with the Figma gap: paragraphs
        // are separated by one blank 20px line. The last paragraph gets no
        // margin so nothing extra trails the article. (Empty paragraphs are
        // already stripped by [cleanNewsHtml], so gaps don't stack.)
        customStylesBuilder: (element) {
          if (element.localName == 'p') {
            return {
              'margin': element.nextElementSibling != null ? '0 0 20px 0' : '0'
            };
          }
          return null;
        },
        onTapUrl: (String? url) async {
          if (await canLaunchUrl(Uri.parse(url!))) {
            await launchUrl(Uri.parse(url));
            return true;
          } else {
            throw 'Could not launch $url';
          }
        },
        onErrorBuilder: (context, element, error) =>
            CustomTextLabel(text: '$element error: $error'),
        onLoadingBuilder: (context, element, loadingProgress) =>
            UiUtils.showCircularProgress(true, Theme.of(context).primaryColor),
        renderMode: RenderMode.column,
        // set the default styling for text
        textStyle: TextStyle(
            fontSize: fontValue.toDouble(),
            height: 20 / 14,
            color: bodyColor),
        customWidgetBuilder: (element) {
          if ((element.toString() == "<html iframe>") ||
              (element.toString() == "<html video>")) {
            String? src = element.attributes["src"];
            bool isIframe = element.toString() == "<html iframe>";

            // For YouTube videos, pass original URL (not converted) - InlineVideoPlayer will handle it
            // For non-YouTube videos, convert URLs if needed
            String? processedSrc = src;
            bool isYouTube = processedSrc != null &&
                (processedSrc.contains('youtube.com') ||
                    processedSrc.contains('youtu.be'));

            if (!isYouTube && processedSrc != null) {
              // Only convert non-YouTube URLs if needed
              processedSrc = convertToYouTubeEmbedUrl(processedSrc);
            }

            // Play inline first, detect fullscreen and open in new screen
            return InlineVideoPlayer(
              src: isIframe ? processedSrc : null,
              videoHtml: isIframe ? null : element.outerHtml,
              type: isIframe ? "1" : "2",
              context: context,
            );
          }
          return null;
        },
      ));
}
