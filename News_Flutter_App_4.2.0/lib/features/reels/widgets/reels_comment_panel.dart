import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/reels/cubits/video_short_comment_cubit.dart';
import 'package:news/features/reels/cubits/video_short_set_comment_cubit.dart';
import 'package:news/features/reels/models/video_short_comment_model.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/reels/widgets/reels_keyboard_insets.dart';
import 'package:news/utils/ui_utils.dart';

class ReelsCommentPanel extends StatefulWidget {
  final String videoShortsId;
  final VoidCallback? onClose;
  final VoidCallback? onCommentPosted;

  const ReelsCommentPanel({
    super.key,
    required this.videoShortsId,
    this.onClose,
    this.onCommentPosted,
  });

  @override
  State<ReelsCommentPanel> createState() => _ReelsCommentPanelState();
}

class _ReelsCommentPanelState extends State<ReelsCommentPanel> {
  final TextEditingController _commentController = TextEditingController();
  bool _canSend = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    context
        .read<VideoShortCommentCubit>()
        .getVideoShortComments(videoShortsId: widget.videoShortsId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _close({bool dismissKeyboard = true}) {
    if (dismissKeyboard) {
      FocusScope.of(context).unfocus();
    }
    widget.onClose?.call();
  }

  void _handleBackPress() {
    if (reelsKeyboardIsOpen(context)) {
      FocusScope.of(context).unfocus();
      return;
    }
    _close();
  }

  void _sendComment() {
    if (context.read<AuthCubit>().getUserId() == "0") {
      UiUtils.loginRequired(context);
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    context.read<VideoShortSetCommentCubit>().setVideoShortComment(
          videoShortsId: widget.videoShortsId,
          comment: text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleBackPress();
        },
        child: Material(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                _buildDragHandle(colorScheme),
                Expanded(
                  child: _buildCommentList(colorScheme),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              bottom: false,
              child: _buildInputBar(colorScheme),
            ),
          ),
        ));
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 0) _close();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentList(ColorScheme colorScheme) {
    return BlocBuilder<VideoShortCommentCubit, VideoShortCommentState>(
      builder: (context, state) {
        if (state is VideoShortCommentFetchInProgress ||
            state is VideoShortCommentInitial) {
          return Center(
            child: UiUtils.showCircularProgress(
              true,
              Theme.of(context).primaryColor,
            ),
          );
        }

        if (state is VideoShortCommentFetchFailure &&
            state.videoShortsId == widget.videoShortsId) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CustomTextLabel(
                text: state.errorMessage.contains(ErrorMessageKeys.noInternet)
                    ? 'internetmsg'
                    : (state.errorMessage == "No Data Found" ||
                            state.errorMessage == "No comments Found")
                        ? 'noComments'
                        : state.errorMessage,
                textAlign: TextAlign.center,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primaryContainer.withOpacity(0.7),
                    ),
              ),
            ),
          );
        }

        if (state is! VideoShortCommentFetchSuccess ||
            state.videoShortsId != widget.videoShortsId) {
          return const SizedBox.shrink();
        }

        if (state.comments.isEmpty) {
          return Center(
            child: CustomTextLabel(
              text: 'noComments',
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                  ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: state.comments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _CommentTile(
              model: state.comments[index],
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: BlocListener<VideoShortSetCommentCubit, VideoShortSetCommentState>(
        listener: (context, state) async {
          if (state is VideoShortSetCommentInProgress) {
            setState(() => _isSending = true);
            return;
          }

          if (state is VideoShortSetCommentSuccess &&
              state.videoShortsId == widget.videoShortsId) {
            FocusManager.instance.primaryFocus?.unfocus();

            _commentController.clear();

            setState(() {
              _isSending = false;
              _canSend = false;
            });

            await Future.delayed(const Duration(milliseconds: 150));

            if (!mounted) return;

            context
                .read<VideoShortCommentCubit>()
                .getVideoShortComments(videoShortsId: widget.videoShortsId);

            context.read<VideoShortSetCommentCubit>().reset();
            widget.onCommentPosted?.call();

            return;
          }

          if (state is VideoShortSetCommentFailure) {
            setState(() => _isSending = false);
            showSnackBar(state.errorMessage, context);
            context.read<VideoShortSetCommentCubit>().reset();
          }
        },
        child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _buildInputRow()),
      ),
    );
  }

  Widget _buildInputRow() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputTextColor = colorScheme.onSurface;
    return Row(
      children: [
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is Authenticated &&
                context.read<AuthCubit>().getProfile().isNotEmpty) {
              return CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  context.read<AuthCubit>().getProfile(),
                ),
              );
            }

            return UiUtils.setFixedSizeboxForProfilePicture(
              childWidget: const Icon(Icons.account_circle, size: 36),
            );
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _commentController,
            onChanged: (val) {
              setState(() => _canSend = val.trim().isNotEmpty);
            },
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: inputTextColor,
                ),
            decoration: InputDecoration(
              hintText: UiUtils.getTranslatedLabel(
                context,
                'shareThoghtLbl',
              ),
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: inputTextColor.withOpacity(0.5),
                  ),
              filled: true,
              fillColor: isDark
                  ? inputTextColor.withOpacity(0.1)
                  : backgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: darkSecondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isDark
                ? BorderSide(color: inputTextColor.withOpacity(0.3))
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: _canSend && !_isSending ? _sendComment : null,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 44,
              height: 44,
              child: _isSending
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: UiUtils.showCircularProgress(
                        true,
                        secondaryColor,
                      ),
                    )
                  : SvgPictureWidget(
                      assetName: 'reel_com_send',
                      assetColor: ColorFilter.mode(
                        secondaryColor,
                        BlendMode.srcIn,
                      ),
                      fit: BoxFit.scaleDown,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final VideoShortCommentModel model;
  final ColorScheme colorScheme;

  const _CommentTile({
    required this.model,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (model.user != null &&
            model.user!.name != null &&
            model.user!.name!.isNotEmpty)
        ? model.user!.name!
        : '';

    return model.user != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (model.user!.profile != null && model.user!.profile!.isNotEmpty)
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(model.user!.profile ?? ''),
                    )
                  : UiUtils.setFixedSizeboxForProfilePicture(
                      childWidget: const Icon(Icons.account_circle, size: 36),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primaryContainer,
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.comment ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                colorScheme.primaryContainer.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }
}
