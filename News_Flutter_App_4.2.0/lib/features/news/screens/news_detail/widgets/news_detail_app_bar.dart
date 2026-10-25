import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/utils/ui_utils.dart';

/// FIGMA(3768-8884 light / 3768-9010 dark): news-details top app bar. A back
/// button, the "News Details" title, and a trailing bookmark + share cluster.
/// Replaces the shared [CustomAppBar] on this screen only so the actions match
/// the redesign.
class NewsDetailAppBar extends StatelessWidget {
  final NewsModel? model;
  final BreakingNewsModel? breakModel;
  final bool isFromBreak;
  final VoidCallback onBack;
  final VoidCallback onShare;

  /// Light-mode fill. Defaults to white, which is what the article screen sits
  /// on; the video details screen sits on Background/Primary instead.
  final Color? lightBackgroundColor;

  /// Live streams have nothing to share, so the video screen turns this off.
  final bool showShare;

  /// Set to false to hide the bookmark icon without removing the underlying
  /// code (e.g. on the video details screen).
  final bool showBookmark;

  /// Bookmark glyphs. The article screen uses the single bookmark; the video
  /// details frame (3371-4337) draws Iconsax "save-2" (two overlapping
  /// bookmarks) instead, so it passes that pair.
  final String bookmarkAsset;
  final String bookmarkFilledAsset;

  /// Label key for the bar title. The Short News reader reuses this bar under
  /// its own name.
  final String titleKey;

  const NewsDetailAppBar({
    super.key,
    required this.isFromBreak,
    required this.onBack,
    required this.onShare,
    this.model,
    this.breakModel,
    this.lightBackgroundColor,
    this.showShare = true,
    this.showBookmark = true,
    this.bookmarkAsset = 'nd_bookmark',
    this.bookmarkFilledAsset = 'nd_bookmark_filled',
    this.titleKey = 'newsDetailsLbl',
  });

  @override
  Widget build(BuildContext context) {
    final onColor = UiUtils.getColorScheme(context).primaryContainer;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? darkBackgroundColor
            : (lightBackgroundColor ?? Colors.white),
        border: Border(
            bottom: BorderSide(
                color: isDark ? darkBorderDefaultColor : borderDefaultColor)),
      ),
      // 8px above and below the 48px row. The 1px border is drawn inside the
      // bar's 64px height, so the bottom padding is 7 to leave 8 in total.
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 7),
      child: Row(
        children: [
          _iconButton(
            context,
            padding: 12,
            child: SvgPictureWidget(
              assetName: 'nd_back',
              height: 24,
              width: 24,
              assetColor: ColorFilter.mode(onColor, BlendMode.srcIn),
            ),
            onTap: onBack,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomTextLabel(
              text: titleKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onColor,
                    fontSize: 16,
                    height: 24 / 16,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // Trailing cluster: two 40px tabs with a 4px gap and 4px padding, so
          // it is 48px tall like the back button.
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                // showBookmark: set to false on the video details screen to
                // hide the bookmark icon (code kept intact, just not rendered).
                if (showBookmark && !isFromBreak && model != null) ...[
                  _bookmarkButton(context, model!),
                  if (showShare) const SizedBox(width: 4),
                ],
                if (showShare)
                  _iconButton(
                    context,
                    child: SvgPictureWidget(
                      assetName: 'nd_share',
                      height: 24,
                      width: 24,
                      fit: BoxFit.contain,
                      assetColor: ColorFilter.mode(onColor, BlendMode.srcIn),
                    ),
                    onTap: onShare,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(BuildContext context,
      {required Widget child, required VoidCallback onTap, double padding = 8}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(1000),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SizedBox(width: 24, height: 24, child: child),
      ),
    );
  }

  Widget _bookmarkButton(BuildContext context, NewsModel model) {
    final onColor = UiUtils.getColorScheme(context).primaryContainer;
    return BlocBuilder<BookmarkCubit, BookmarkState>(
      bloc: context.read<BookmarkCubit>(),
      builder: (context, bookmarkState) {
        return BlocConsumer<UpdateBookmarkStatusCubit, UpdateBookmarkStatusState>(
          bloc: context.read<UpdateBookmarkStatusCubit>(),
          listener: (context, state) {
            if (state is UpdateBookmarkStatusSuccess) {
              if (state.wasBookmarkNewsProcess) {
                context.read<BookmarkCubit>().addBookmarkNews(state.news);
              } else {
                context.read<BookmarkCubit>().removeBookmarkNews(state.news);
              }
            }
          },
          builder: (context, state) {
            final bool isBookmark =
                context.read<BookmarkCubit>().isNewsBookmark(model.newsId ?? model.id ?? '');
            return _iconButton(
              context,
              child: SvgPictureWidget(
                assetName: isBookmark ? bookmarkFilledAsset : bookmarkAsset,
                height: 24,
                width: 24,
                assetColor: ColorFilter.mode(
                    isBookmark ? Theme.of(context).primaryColor : onColor,
                    BlendMode.srcIn),
              ),
              onTap: () {
                if (context.read<AuthCubit>().getUserId() == "0") {
                  UiUtils.loginRequired(context);
                  return;
                }
                if (state is UpdateBookmarkStatusInProgress) return;
                context.read<UpdateBookmarkStatusCubit>().setBookmarkNews(
                    news: model, status: isBookmark ? "0" : "1");
              },
            );
          },
        );
      },
    );
  }
}
