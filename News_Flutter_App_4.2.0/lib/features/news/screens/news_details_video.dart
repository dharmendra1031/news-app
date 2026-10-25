import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class NewsDetailsVideo extends StatefulWidget {
  String? src;
  String type;
  Duration? startTime; // Start playback from this time

  NewsDetailsVideo({super.key, this.src, required this.type, this.startTime});

  @override
  State<StatefulWidget> createState() => StateNewsDetailsVideo();
}

class StateNewsDetailsVideo extends State<NewsDetailsVideo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;
  var iframe;
  InAppWebViewController? webViewController;
  YoutubePlayerController? _youtubeController;
  String? _youtubeVideoId;
  Duration _currentTime = Duration.zero; // Track current playback time
  Timer? _timeTrackingTimer; // Timer to periodically update current time

  /// Checks if URL is a YouTube URL and extracts video ID
  bool _isYouTubeUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  @override
  void initState() {
    super.initState();

    // Initialize current time from startTime if provided
    if (widget.startTime != null) {
      _currentTime = widget.startTime!;
    }

    checkNetwork();

    // Start periodic time tracking
    _startTimeTracking();

    // Check if it's a YouTube URL - use native YouTube player to avoid error 153
    if ((widget.type == "1") || (widget.type == "3")) {
      if (_isYouTubeUrl(widget.src) && widget.src != null) {
        // Extract video ID for YouTube player
        _youtubeVideoId = YoutubePlayer.convertUrlToId(widget.src!);
        if (_youtubeVideoId != null && _youtubeVideoId!.isNotEmpty) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: _youtubeVideoId!,
            flags: YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              hideControls: false,
              startAt: widget.startTime != null ? widget.startTime!.inSeconds : 0,
            ),
          );
          return; // Use YouTube player instead of iframe
        }
      }

      // For non-YouTube iframes, use webview with proper URL loading
      // Validate that src is not null before constructing iframe
      if (widget.src == null || widget.src!.isEmpty) {
        debugPrint("Warning: widget.src is null or empty for type ${widget.type}");
        iframe = '''
          <html>
          <body style="margin:0;padding:0;display:flex;align-items:center;justify-content:center;height:100vh;">
          <p style="color:#666;text-align:center;">Video source not available</p>
          </body>
          </html>
        ''';
      } else {
        // Add start time parameter to YouTube embed URL if provided
        String srcUrl = widget.src!;
        if (widget.startTime != null && widget.startTime!.inSeconds > 0) {
          Uri uri = Uri.parse(srcUrl);
          Map<String, String> queryParams = Map.from(uri.queryParameters);
          queryParams['start'] = widget.startTime!.inSeconds.toString();
          srcUrl = uri.replace(queryParameters: queryParams).toString();
        }

        iframe = '''
          <html>
          <head>
          <script>
          document.addEventListener('fullscreenchange', function() {
            if (!document.fullscreenElement) {
              var iframe = document.querySelector('iframe');
              if (iframe) {
                try {
                  iframe.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                } catch(e) {
                  console.log('Error playing video:', e);
                }
              }
            }
          });
          document.addEventListener('webkitfullscreenchange', function() {
            if (!document.webkitFullscreenElement) {
              var iframe = document.querySelector('iframe');
              if (iframe) {
                try {
                  iframe.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                } catch(e) {
                  console.log('Error playing video:', e);
                }
              }
            }
          });
          </script>
          </head>
          <body style="margin:0;padding:0;">
          <iframe src="$srcUrl" allow="autoplay; fullscreen; picture-in-picture; encrypted-media" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen style="width:100%;height:100vh;border:none;"></iframe>
          </body>
          </html>
        ''';
      }
    } else {
      // For video elements, validate src is not null
      if (widget.src == null || widget.src!.isEmpty) {
        debugPrint("Warning: widget.src is null or empty for type ${widget.type}");
        iframe = '''
          <html>
          <body style="margin:0;padding:0;display:flex;align-items:center;justify-content:center;height:100vh;">
          <p style="color:#666;text-align:center;">Video source not available</p>
          </body>
          </html>
        ''';
      } else {
        // Get start time in seconds
        int startTimeSeconds = widget.startTime != null ? widget.startTime!.inSeconds : 0;

        // The article's inline player passes the whole <video ...> element as
        // HTML (not a URL). Use it as-is; only wrap a plain URL in a <video>.
        final String videoSrc = widget.src!.trim();
        final String videoMarkup = videoSrc.startsWith('<')
            ? videoSrc
            : '<video controls playsinline><source src="$videoSrc"></video>';

        iframe = '''
          <html>
          <head>
          <style>
          html, body { margin: 0; padding: 0; height: 100%; background: #000; }
          video { width: 100%; height: 100%; object-fit: contain; background: #000; }
          </style>
          <script>
          var video;
          document.addEventListener('DOMContentLoaded', function() {
            video = document.querySelector('video');
            if (video) {
              video.controls = true;
              // Seek to start time if provided
              if ($startTimeSeconds > 0) {
                video.currentTime = $startTimeSeconds;
              }
              
              document.addEventListener('fullscreenchange', function() {
                if (!document.fullscreenElement && video) {
                  video.play().catch(function(e) {
                    console.log('Error playing video:', e);
                  });
                }
              });
              document.addEventListener('webkitfullscreenchange', function() {
                if (!document.webkitFullscreenElement && video) {
                  video.play().catch(function(e) {
                    console.log('Error playing video:', e);
                  });
                }
              });
            }
          });
          </script>
          </head>
          <body>
          $videoMarkup
          </body>
          </html>
        ''';
      }
    }
  }

  checkNetwork() async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      setState(() {
        _isNetworkAvail = true;
      });
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  void _startTimeTracking() {
    // Update current time periodically
    _timeTrackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Get current time from YouTube player
      if (_youtubeController != null) {
        _currentTime = _youtubeController!.value.position;
        return;
      }

      // Get current time from webview video
      if (webViewController != null) {
        try {
          String? timeStr = await webViewController!.evaluateJavascript(source: '''
            (function() {
              var video = document.querySelector('video');
              var iframe = document.querySelector('iframe');
              
              if (video) {
                return Math.floor(video.currentTime);
              } else if (iframe) {
                // For iframes, we can't directly get time, return tracked time
                return ${_currentTime.inSeconds};
              }
              return ${_currentTime.inSeconds};
            })();
          ''');

          if (timeStr != null) {
            int seconds = int.tryParse(timeStr) ?? _currentTime.inSeconds;
            _currentTime = Duration(seconds: seconds);
          }
        } catch (e) {
          // Silently handle errors during time tracking
        }
      }
    });
  }

  Future<Duration> _getCurrentPlaybackTime() async {
    // Get current time from YouTube player
    if (_youtubeController != null) {
      return _youtubeController!.value.position;
    }

    // Get current time from webview video
    if (webViewController != null) {
      try {
        String? timeStr = await webViewController!.evaluateJavascript(source: '''
          (function() {
            var video = document.querySelector('video');
            var iframe = document.querySelector('iframe');
            
            if (video) {
              return Math.floor(video.currentTime);
            } else if (iframe) {
              // For iframes, we can't directly get time, return tracked time
              return ${_currentTime.inSeconds};
            }
            return ${_currentTime.inSeconds};
          })();
        ''');

        if (timeStr != null) {
          int seconds = int.tryParse(timeStr) ?? _currentTime.inSeconds;
          return Duration(seconds: seconds);
        }
      } catch (e) {
        debugPrint("Error getting playback time: $e");
      }
    }

    return _currentTime;
  }

  @override
  void dispose() async {
    // Stop time tracking timer
    _timeTrackingTimer?.cancel();

    // Get current playback time before disposing
    _currentTime = await _getCurrentPlaybackTime();

    // Return current time to previous screen
    if (mounted) {
      Navigator.of(context).pop(_currentTime);
    }

    // set screen back to portrait mode
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure portrait mode when opening from fullscreen request
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    return SafeArea(child: Scaffold(key: _scaffoldKey, body: _isNetworkAvail ? viewVideo() : const SizedBox.shrink()));
  }

  //news video link set
  viewVideo() {
    // Use native YouTube player for YouTube videos to avoid error 153
    if (_youtubeController != null && _youtubeVideoId != null) {
      return Center(
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: false,
          progressIndicatorColor: Theme.of(context).primaryColor,
          bottomActions: const [],
          topActions: const [],
        ),
      );
    }

    // For non-YouTube videos, use webview
    // Use direct URL loading for iframes instead of data URI to avoid origin issues
    if ((widget.type == "1") || (widget.type == "3")) {
      // If it's a direct URL (not HTML), load it directly
      if (widget.src != null && !widget.src!.trim().startsWith('<')) {
        try {
          Uri? uri = Uri.tryParse(widget.src!);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            return Center(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint("Console: ${consoleMessage.message}");
                },
              ),
            );
          }
        } catch (e) {
          debugPrint("Error parsing URL: $e");
        }
      }

      // Fallback to data URI for HTML content
      WebUri frm = WebUri.uri(Uri.dataFromString(iframe, mimeType: 'text/html'));
      return Center(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: frm),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("Console: ${consoleMessage.message}");
          },
        ),
      );
    } else {
      // For video elements, use data URI
      WebUri frm = WebUri.uri(Uri.dataFromString(iframe, mimeType: 'text/html'));
      return Center(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: frm),
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("Console: ${consoleMessage.message}");
          },
          onLoadStop: (controller, url) async {
            // Seek to start time if provided
            if (widget.startTime != null && widget.startTime!.inSeconds > 0) {
              await controller.evaluateJavascript(source: '''
                (function() {
                  var video = document.querySelector('video');
                  if (video) {
                    video.currentTime = ${widget.startTime!.inSeconds};
                  }
                })();
              ''');
            }

            // Inject JavaScript to handle fullscreen exit for video elements
            // Remove existing listeners first to prevent duplicates, then add new ones
            await controller.evaluateJavascript(source: '''
              (function() {
                var video = document.querySelector('video');
                if (video) {
                  // Remove existing listeners if they exist (stored in video element)
                  if (video._fullscreenExitHandler) {
                    document.removeEventListener('fullscreenchange', video._fullscreenExitHandler);
                    document.removeEventListener('webkitfullscreenchange', video._fullscreenExitHandler);
                    document.removeEventListener('mozfullscreenchange', video._fullscreenExitHandler);
                    document.removeEventListener('MSFullscreenChange', video._fullscreenExitHandler);
                  }
                  
                  // Create new handler function
                  var handleFullscreenExit = function() {
                    if (!document.fullscreenElement && !document.webkitFullscreenElement && !document.mozFullScreenElement && !document.msFullscreenElement) {
                      video.play().catch(function(e) {
                        console.log('Error playing video:', e);
                      });
                    }
                  };
                  
                  // Store handler reference on video element for future removal
                  video._fullscreenExitHandler = handleFullscreenExit;
                  
                  // Add event listeners
                  document.addEventListener('fullscreenchange', handleFullscreenExit);
                  document.addEventListener('webkitfullscreenchange', handleFullscreenExit);
                  document.addEventListener('mozfullscreenchange', handleFullscreenExit);
                  document.addEventListener('MSFullscreenChange', handleFullscreenExit);
                }
              })();
            ''');
          },
        ),
      );
    }
  }
}
