import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/cubits/comment_news_cubit.dart';
import 'package:news/features/news/cubits/news_comment/set_comment_cubit.dart';
import 'package:news/utils/ui_utils.dart';

// FIGMA(1500-4501): bottom-docked "chat type bar" - a full-width rounded input
// box ("Share Your Thoughts") with a filled navy send button beside it. Sits at
// the bottom of the news detail screen (rising above the keyboard) while the
// comment list is open, replacing the old avatar + underline field that used to
// sit inline at the top of the comment list.
class CommentInputBar extends StatefulWidget {
  final String newsId;

  const CommentInputBar({super.key, required this.newsId});

  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  final TextEditingController _commentC = TextEditingController();
  bool _enabled = false;
  bool _isSending = false;

  @override
  void dispose() {
    _commentC.dispose();
    super.dispose();
  }

  void _send() {
    if (!_enabled || _isSending) return;
    if (context.read<AuthCubit>().getUserId() != "0") {
      context.read<SetCommentCubit>().setComment(
          newsId: widget.newsId,
          message: _commentC.text,
          langCode: context.read<AppLocalizationCubit>().state.languageCode);
    } else {
      UiUtils.loginRequired(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onColor = UiUtils.getColorScheme(context).primaryContainer;
    return BlocListener<SetCommentCubit, SetCommentState>(
      bloc: context.read<SetCommentCubit>(),
      listener: (context, state) {
        if (state is SetCommentFetchSuccess) {
          context
              .read<CommentNewsCubit>()
              .commentUpdateList(state.setComment, state.total);
          FocusScope.of(context).unfocus();
          _commentC.clear();
          setState(() {
            _enabled = false;
            _isSending = false;
          });
        }
        if (state is SetCommentFetchInProgress) {
          setState(() => _isSending = true);
        }
      },
      child: Container(
        color: UiUtils.getColorScheme(context).secondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          // Rounded input box - "chat box" in Figma.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: onColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _commentC,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: onColor),
                onChanged: (val) =>
                    setState(() => _enabled = _commentC.text.trim().isNotEmpty),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    hintText:
                        UiUtils.getTranslatedLabel(context, 'shareThoghtLbl'),
                    hintStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: onColor.withOpacity(0.3))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Filled navy send button - "share icon" in Figma.
          InkWell(
            onTap: _send,
            child: Container(
              decoration: BoxDecoration(
                  color: onColor, borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.all(8),
              child: (!_isSending)
                  ? SvgPictureWidget(
                      assetName: 'send_comment',
                      height: 24,
                      width: 24,
                      assetColor: ColorFilter.mode(
                          UiUtils.getColorScheme(context).surface,
                          BlendMode.srcIn))
                  : SizedBox(
                      height: 24,
                      width: 24,
                      child: Center(
                          child: SizedBox(
                              height: 16,
                              width: 16,
                              child: UiUtils.showCircularProgress(true,
                                  UiUtils.getColorScheme(context).surface)))),
            ),
          )
        ]),
      ),
    );
  }
}
