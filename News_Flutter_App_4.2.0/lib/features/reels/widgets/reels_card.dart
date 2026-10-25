import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:news/commons/widgets/video_play_container.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/reels/cubits/video_short_comment_cubit.dart';
import 'package:news/features/reels/cubits/video_short_like_dislike_cubit.dart';
import 'package:news/features/reels/cubits/video_short_view_cubit.dart';
import 'package:news/features/reels/cubits/video_shorts_cubit.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/reels/models/reel_model.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/features/reels/widgets/reels_action_button.dart';
import 'package:news/features/reels/widgets/reels_blur_background.dart';
import 'package:news/features/reels/widgets/reels_comment_panel.dart';
import 'package:news/features/reels/widgets/reels_keyboard_insets.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ReelsCard extends StatefulWidget {
  final ReelModel model;
  final bool isActive;

  /// Whether this card owns the live player. Kept separate from [isActive]
  /// because the screen only moves it once a swipe has settled, so the reel
  /// being swiped away keeps playing instead of tearing its player down
  /// mid-gesture.
  final bool canPlay;

  /// Keeps this reel's video open but hidden and paused, ready to start the
  /// moment a swipe lands on it: the reel after the live one (loading ahead)
  /// and the one just left (kept so swiping back doesn't reload it). Uploaded
  /// reels only; a YouTube reel is a WebView, which costs too much to keep warm.
  final bool preload;
  final int dismissCommentsToken;
  final ValueChanged<bool>? onCommentsVisibilityChanged;

  const ReelsCard({
    super.key,
    required this.model,
    this.isActive = true,
    this.canPlay = true,
    this.preload = false,
    this.dismissCommentsToken = 0,
    this.onCommentsVisibilityChanged,
  });

  @override
  State<ReelsCard> createState() => _ReelsCardState();
}

class _ReelsCardState extends State<ReelsCard> with WidgetsBindingObserver {
  bool _showComments = false;
  bool _isLiked = false;
  int _commentsCount = 0;
  int _totalLikeCount = 0;
  String _caption = "";
  bool _isCaptionExpanded = false;

  late ReelModel currentModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _parseCaption();
    _syncStateFromModel();
    if (widget.isActive) {
      _scheduleViewRecord();
    }
    currentModel = widget.model;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Keep title / action bar aligned while the keyboard animates after sheet close.
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(ReelsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleViewRecord();
    }
    if (oldWidget.dismissCommentsToken != widget.dismissCommentsToken) {
      if (_showComments) Navigator.of(context).maybePop();
      _closeComments();
    }
    if (oldWidget.model.id != widget.model.id ||
        oldWidget.model.isLiked != widget.model.isLiked ||
        oldWidget.model.sharesCount != widget.model.sharesCount ||
        oldWidget.model.commentsCount != widget.model.commentsCount ||
        oldWidget.model.totalLikeCount != widget.model.totalLikeCount) {
      showUpdatedValues();
    }
    if (oldWidget.model.description != widget.model.description) {
      _parseCaption();
    }
  }

  void _scheduleViewRecord() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recordViewIfNeeded();
    });
  }

  void _syncStateFromModel() {
    _isLiked = widget.model.isLiked;
    _commentsCount = widget.model.commentsCount;
    _totalLikeCount = widget.model.totalLikeCount;
  }

  showUpdatedValues() {
    print("Updated totalLikes: $_totalLikeCount");
    _isLiked = currentModel.isLiked;
    _commentsCount = currentModel.commentsCount;
    _totalLikeCount = currentModel.totalLikeCount;
  }

  void _parseCaption() {
    final raw = widget.model.description ?? '';
    _caption = html_parser.parse(raw).body?.text.trim() ?? '';
  }

  String get _videoShortsId => widget.model.id ?? '';

  void _recordViewIfNeeded() {
    if (_videoShortsId.isEmpty || !widget.isActive) return;
    context
        .read<VideoShortViewCubit>()
        .setVideoShortView(videoShortsId: _videoShortsId);
  }

  void _toggleComments() {
    if (_showComments) {
      Navigator.of(context).maybePop();
      return;
    }
    _presentCommentsSheet();
  }

  void _closeComments() {
    _dismissCommentsSheet();
  }

  void _onCommentPosted() {
    setState(() {
      _commentsCount++;
      currentModel.commentsCount = _commentsCount;
    });

    _syncCommentsCountToCubit();
  }

  void _dismissCommentsSheet() {
    if (!_showComments) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _showComments = false;
    });

    widget.onCommentsVisibilityChanged?.call(false);
  }

  void _syncCommentsCountToCubit() {
    final videoShortsId = _videoShortsId;
    if (videoShortsId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VideoShortsCubit>().updateVideoShortCommentsCount(
            videoShortsId: videoShortsId,
            commentsCount: _commentsCount,
          );
    });
  }

  Future<void> _presentCommentsSheet() async {
    if (_videoShortsId.isEmpty) return;

    setState(() => _showComments = true);
    widget.onCommentsVisibilityChanged?.call(true);

    context.read<VideoShortCommentCubit>().getVideoShortComments(
          videoShortsId: _videoShortsId,
        );

    try {
      await showModalBottomSheet(
          context: Navigator.of(context, rootNavigator: true).context,
          useRootNavigator: true,
          enableDrag: true,
          isDismissible: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            final mq = MediaQuery.of(sheetContext);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
              height: mq.size.height * .55,
              child: ReelsCommentPanel(
                videoShortsId: _videoShortsId,
                onClose: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(sheetContext);
                },
                onCommentPosted: _onCommentPosted,
              ),
            );
          });
      ;
    } finally {
      if (mounted) _dismissCommentsSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabBarPadding = _showComments
            ? 0.0
            : reelsTabBarBottomPadding(
                context,
                ignoreKeyboard: false,
              );

        final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

        final controlsBottom = tabBarPadding + safeBottom + 40;

        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackgroundVideo(),
              _buildGradient(),
              _buildCaptionInfo(controlsBottom),
              _buildActionBar(controlsBottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoLayer() {
    final videoUrl = widget.model.videoUrl ?? '';
    final hasVideo = videoUrl.isNotEmpty;
    final bool isUpload = widget.model.videoType == VideoType.video_upload;

    if ((widget.canPlay || (widget.preload && isUpload)) && hasVideo) {
      // Same element from preload to playback (the key and slot don't change),
      // so the video that finished loading ahead of the swipe is the one that
      // starts, not a fresh one.
      final player = VideoPlayContainer(
        key: ValueKey('reels_${widget.model.id}'),
        contentType: videoTypeToString(widget.model.videoType),
        contentValue: videoUrl,
        autoPlay: true,
        preload: !widget.canPlay,
        from: 'reels',
      );

      // Uploaded reels are shot vertical and fill the page. YouTube reels take
      // the page's shape too (VideoPlayContainer gives the player the box's own
      // aspect ratio), so a vertical short fills the screen and the player
      // letterboxes anything wider itself. Only the embedded-URL players still
      // carry a fixed frame, so they get loose constraints and sit centred over
      // the blurred backdrop.
      final bool fillsPage = isUpload || widget.model.isYoutube;

      return fillsPage ? player : Center(child: player);
    }

    return _buildThumbnail();
  }

  Widget _buildBackgroundVideo() {
    final videoUrl = widget.model.videoUrl ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // YouTube reels now cover the page, and the player paints its own bars
        // when the source is wider than the screen. Plain black behind it
        // matches those bars; a blurred poster would never show through.
        // The blur is a second native player on the same URL, and it is only
        // seen while a reel is arriving: from halfway through the swipe until
        // its player mounts, whose own black background then covers it. So it
        // exists only in that gap; a playing, preloaded or kept reel stays
        // plain black and doesn't pay for a second player.
        widget.model.isYoutube || widget.canPlay || !widget.isActive
            ? const ColoredBox(color: Colors.black)
            : ReelsBlurBackground(videoUrl: videoUrl),
        Positioned.fill(
          child: _buildVideoLayer(),
        ),
      ],
    );
  }

  Widget _buildThumbnail() {
    // A reel without a live player is either off-screen or mid-swipe, so this
    // is what the incoming reel shows while the finger is still moving.
    // YouTube reels can stand in with the video's own poster; uploads have no
    // poster URL, so they keep falling back to the placeholder asset.
    final String posterUrl = widget.model.isYoutube
        ? _youtubeThumbnailUrl(widget.model.videoUrl ?? '')
        : '';

    return CustomNetworkImage(
      networkImageUrl: posterUrl,
      // Cover, never contain: YouTube posters come back 4:3 with the clip
      // padded inside them, so containing one in a portrait page draws a short
      // band in the middle of the screen that reads as the video playing small
      // for a moment before the real player fills the page.
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      isVideo: true,
      // Nothing at all while the poster loads or when there is none. The reel
      // already paints black (YouTube) or the blurred first frame (uploads)
      // behind this, and the app logo flashing over that between reels looks
      // like content rather than a placeholder.
      placeholderBuilder: const SizedBox.shrink(),
    );
  }

  String _youtubeThumbnailUrl(String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null || videoId.isEmpty) return '';
    return YoutubePlayer.getThumbnail(videoId: videoId);
  }

  Widget _buildGradient() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.15),
            Colors.transparent,
            Colors.black.withOpacity(0.65),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }

  Widget _buildCaptionInfo(double controlsBottom) {
    final title = widget.model.title ?? '';

    return Positioned(
      left: 14,
      right: 72,
      bottom: controlsBottom + 25,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: secondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: secondaryColor.withOpacity(0.95),
                      fontSize: 13,
                      height: 1.35,
                    );

                final showReadMore = _shouldShowReadMore(
                  _caption,
                  style,
                  constraints.maxWidth,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _caption,
                      maxLines: _isCaptionExpanded ? null : 3,
                      overflow: _isCaptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: style,
                    ),
                    if (showReadMore)
                      GestureDetector(
                        onTap: () => setState(() {
                          _isCaptionExpanded = !_isCaptionExpanded;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isCaptionExpanded ? 'Read less' : 'Read more',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            )
          ]),
    );
  }

  bool _shouldShowReadMore(String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  Widget _buildActionBar(double controlsBottom) {
    return Positioned(
      right: 12,
      bottom: controlsBottom + 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLikeButton(),
          const SizedBox(height: 20),
          ReelsActionButton(
            icon: _showComments
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            isActive: _showComments,
            count: _commentsCount.toString(),
            onTap: _toggleComments,
          ),
          const SizedBox(height: 20),
          _buildShareButton(),
        ],
      ),
    );
  }

  /// The like cubit is shared by every mounted reel, so a card must ignore the
  /// states raised for its neighbours — otherwise one reel's error snackbar
  /// fires on all of them.
  bool _isLikeStateForThisReel(VideoShortLikeDislikeState state, String id) {
    if (state is VideoShortLikeDislikeInProgress) {
      return state.videoShortsId == id;
    }
    if (state is VideoShortLikeDislikeSuccess) return state.videoShortsId == id;
    if (state is VideoShortLikeDislikeFailure) return state.videoShortsId == id;
    return false;
  }

  /// Like state as the server last confirmed it, kept so a request that fails
  /// can be undone without guessing.
  bool _likeBeforeRequest = false;
  int _likeCountBeforeRequest = 0;

  /// Like total to show when the response carries no authoritative count.
  /// Derived from the pre-tap values so a rejected request can't drift it.
  int _resolveLikeCount(bool liked, int? serverCount) {
    if (serverCount != null) return serverCount;
    if (liked == _likeBeforeRequest) return _likeCountBeforeRequest;
    return liked
        ? _likeCountBeforeRequest + 1
        : max(0, _likeCountBeforeRequest - 1);
  }

  void _applyLikeState(String videoShortsId, bool isLiked, int? serverCount) {
    final int resolvedCount = _resolveLikeCount(isLiked, serverCount);
    setState(() {
      _isLiked = isLiked;
      _totalLikeCount = resolvedCount;
      currentModel.isLiked = isLiked;
      currentModel.totalLikeCount = resolvedCount;
    });

    // Keep the list in step, or the next rebuild would hand the card back the
    // stale value and the two would disagree with the server again.
    context.read<VideoShortsCubit>().updateVideoShortLike(
          videoShortsId: videoShortsId,
          isLiked: isLiked,
        );
  }

  void _onLikeTap(String videoShortsId) {
    if (videoShortsId.isEmpty) return;
    if (context.read<AuthCubit>().getUserId() == "0") {
      UiUtils.loginRequired(context);
      return;
    }

    final cubit = context.read<VideoShortLikeDislikeCubit>();
    if (cubit.isInProgress(videoShortsId)) return;

    final bool willLike = !_isLiked;
    _likeBeforeRequest = _isLiked;
    _likeCountBeforeRequest = _totalLikeCount;

    // Show the tap immediately; the response confirms it, corrects it, or the
    // failure path puts it back.
    _applyLikeState(videoShortsId, willLike, null);

    cubit.setVideoShortLikeDislike(
      videoShortsId: videoShortsId,
      action: willLike ? 'like' : 'dislike',
    );
  }

  Widget _buildLikeButton() {
    final videoShortsId = widget.model.id ?? '';

    return BlocConsumer<VideoShortLikeDislikeCubit, VideoShortLikeDislikeState>(
      listenWhen: (_, state) => _isLikeStateForThisReel(state, videoShortsId),
      listener: (context, state) {
        if (state is VideoShortLikeDislikeSuccess) {
          _applyLikeState(videoShortsId, state.isLiked, state.totalLikeCount);
        } else if (state is VideoShortLikeDislikeFailure) {
          // A refusal means the server already holds the state we asked for, so
          // adopt it. Only a request that never landed gets rolled back.
          final bool resolvedLike = state.serverIsLiked ??
              (state.wasRefusedByServer
                  ? state.action == 'like'
                  : _likeBeforeRequest);

          _applyLikeState(videoShortsId, resolvedLike, null);
          showSnackBar(state.errorMessage, context);
        }
      },
      builder: (context, state) {
        // Gate on the request actually in flight for this reel, not on the last
        // emitted state: the cubit is app-wide and outlives the screen, so a
        // stranded InProgress would disable the button for the whole session.
        final inProgress = context
            .read<VideoShortLikeDislikeCubit>()
            .isInProgress(videoShortsId);

        return ReelsActionButton(
          icon:
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          isActive: _isLiked,
          count: _totalLikeCount.toString(),
          onTap: inProgress ? () {} : () => _onLikeTap(videoShortsId),
        );
      },
    );
  }

  Widget _buildShareButton() {
    return ReelsActionButton(
      icon: Icons.share_rounded,
      onTap: _onShare,
    );
  }

  Future<void> _onShare() async {
    if (!(await InternetConnectivity.isNetworkAvailable())) {
      showSnackBar(
        UiUtils.getTranslatedLabel(context, 'internetmsg'),
        context,
      );
      return;
    }

    await UiUtils.shareNews(
      context: context,
      slug: widget.model.slug ?? '',
      title: widget.model.title ?? '',
      isVideo: false,
      videoId: widget.model.id ?? '',
      isBreakingNews: false,
      isNews: false,
      isReels: true,
    );
  }
}
