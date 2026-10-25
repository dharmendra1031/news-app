import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/parser.dart' show parse;
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/font_size_bottom_sheet.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/news/cubits/comment_news_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/news/screens/news_detail/widgets/like_action.dart';
import 'package:news/utils/ui_utils.dart';

/// FIGMA(3768-8884 light / 3768-9010 dark): floating action bar docked near the
/// bottom of the news details screen. Comment, Like, Text Size and Speak Loud —
/// icon glyphs over a rounded bar. The bar is inverted against the screen: a
/// #1E1E1E bar with white content in light mode, and a white bar with dark
/// content in dark mode. Replaces the old light action row that used to sit on
/// top of the hero image.
class NewsDetailActionBar extends StatelessWidget {
  final bool isFromBreak;
  final NewsModel? model;
  final BreakingNewsModel? breakModel;
  final int fontVal;
  final ValueChanged<int> updateFont;
  final bool isPlaying;
  final Function speak;
  final Function stop;
  final Function(bool) updateComEnabled;

  const NewsDetailActionBar({
    super.key,
    required this.isFromBreak,
    required this.fontVal,
    required this.updateFont,
    required this.isPlaying,
    required this.speak,
    required this.stop,
    required this.updateComEnabled,
    this.model,
    this.breakModel,
  });

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Background/Inverse, Icon/Inverse and Text/Inverse Dark.
  static Color _barColor(BuildContext context) =>
      _isDark(context) ? secondaryColor : darkBackgroundColor;
  static Color _iconColor(BuildContext context) =>
      _isDark(context) ? darkBackgroundColor : secondaryColor;
  static Color _labelColor(BuildContext context) =>
      _isDark(context) ? darkTextInverseColor : secondaryColor;

  @override
  Widget build(BuildContext context) {
    final bool commentsOn = !isFromBreak &&
        context.read<AppConfigurationCubit>().getCommentsMode() == "1";

    // FIGMA(3768-8884): the bar floats just above the system bottom bar with a
    // ~5px gap. app.dart already reserves the Android system-nav strip app-wide
    // (MaterialApp.builder), so here we only add that small gap — adding the
    // inset again double-counts it and pushes the bar a whole nav bar too high.
    // On iOS the home-indicator inset is still ours to clear, and its visible
    // strip is far thinner than the ~34pt safe-area inset, so hug it directly
    // (~13pt for the pill + ~5px gap).
    final double inset = MediaQuery.of(context).viewPadding.bottom;
    final double bottomGap =
        Platform.isIOS ? (inset > 0 ? 18.0 : 6.0) : 5.0;

    final items = <Widget>[
      if (commentsOn) _commentItem(context),
      if (!isFromBreak && model != null) _likeItem(context, model!),
      _textSizeItem(context),
      _speakItem(context),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomGap),
      child: Container(
        decoration: BoxDecoration(
          color: _barColor(context),
          borderRadius: BorderRadius.circular(12),
          // The dark design has no shadow under the bar.
          boxShadow: _isDark(context)
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
        ),
        padding: const EdgeInsets.all(8),
        // 10px between the slots, as in Figma (four 78px slots in the 358px bar).
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: items[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context,
      {required String asset,
      required Widget label,
      required VoidCallback onTap,
      Color? tint}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPictureWidget(
              assetName: asset,
              height: 24,
              width: 24,
              assetColor: ColorFilter.mode(
                  tint ?? _iconColor(context), BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            label,
          ],
        ),
      ),
    );
  }

  Widget _text(BuildContext context, String value, {Color? color}) {
    return CustomTextLabel(
      text: value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textStyle: TextStyle(
          color: color ?? _labelColor(context),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14),
    );
  }

  Widget _commentItem(BuildContext context) {
    return BlocBuilder<CommentNewsCubit, CommentNewsState>(
      bloc: context.read<CommentNewsCubit>(),
      builder: (context, state) {
        final int count =
            state is CommentNewsFetchSuccess ? state.totalCommentNewsCount : 0;
        return _item(
          context,
          asset: 'nd_comment',
          label: _text(
              context,
              count > 0
                  ? '$count'
                  : UiUtils.getTranslatedLabel(context, 'comLbl').trim()),
          onTap: () {
            if (model?.isCommentEnabled == 0) {
              showSnackBar(
                  UiUtils.getTranslatedLabel(context, 'disabledCommentsMsg'),
                  context);
            } else {
              updateComEnabled(true);
            }
          },
        );
      },
    );
  }

  Widget _likeItem(BuildContext context, NewsModel model) {
    return BlocBuilder<LikeAndDisLikeCubit, LikeAndDisLikeState>(
      bloc: context.read<LikeAndDisLikeCubit>(),
      builder: (context, likeState) {
        return BlocConsumer<UpdateLikeAndDisLikeStatusCubit,
            UpdateLikeAndDisLikeStatusState>(
          bloc: context.read<UpdateLikeAndDisLikeStatusCubit>(),
          listener: (context, state) =>
              onLikeStatusChanged(context, state, model),
          builder: (context, state) {
            final bool isLike = isNewsLiked(context, model);
            final int likes = int.tryParse(model.totalLikes ?? '') ?? 0;
            return _item(
              context,
              asset: isLike ? 'nd_like_filled' : 'nd_like',
              tint: isLike ? Theme.of(context).primaryColor : null,
              label: _text(
                  context,
                  likes > 0
                      ? '$likes'
                      : UiUtils.getTranslatedLabel(context, 'likeLbl')),
              onTap: () => onLikeTap(context, model),
            );
          },
        );
      },
    );
  }

  Widget _textSizeItem(BuildContext context) {
    return _item(
      context,
      asset: 'nd_text_size',
      label: _text(context, UiUtils.getTranslatedLabel(context, 'txtSizeLbl')),
      onTap: () => changeFontSizeSheet(context,
          fontSize: fontVal, onFontSizeChanged: updateFont),
    );
  }

  Widget _speakItem(BuildContext context) {
    return _item(
      context,
      asset: 'nd_speak',
      tint: isPlaying ? Theme.of(context).primaryColor : null,
      label: _text(context, UiUtils.getTranslatedLabel(context, 'speakLoudLbl'),
          color: isPlaying ? Theme.of(context).primaryColor : null),
      onTap: () {
        if (isPlaying) {
          stop();
        } else {
          final textToSpeak = breakModel != null
              ? "${breakModel!.title}\n${breakModel!.desc}"
              : "${model!.title}\n${model!.desc}";
          final document = parse(textToSpeak);
          final parsed = parse(document.body!.text).documentElement!.text;
          speak(parsed);
        }
      },
    );
  }
}
