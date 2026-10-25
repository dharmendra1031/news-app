import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/cubits/related_news_cubit.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/theme/theme_colors.dart';

/// Compact count e.g. 1000 -> "1K", 1_200_000 -> "1.2M". Matches the Figma
/// "1K read" label.
String _compactCount(int n) {
  if (n >= 1000000) {
    return "${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M";
  }
  if (n >= 1000) {
    return "${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K";
  }
  return "$n";
}

/// FIGMA(3768-8884 light / 3768-9010 dark): "Related News" — a heading over a
/// vertical list of "News Item" rows split by 1px dividers, replacing the old
/// image carousel.
class RelatedNewsList extends StatefulWidget {
  final NewsModel model;

  /// Loads the next page; used by the footer's retry button after a failed
  /// load. Scrolling near the bottom is handled by the owning scroll view.
  final VoidCallback onLoadMore;

  const RelatedNewsList(
      {super.key, required this.model, required this.onLoadMore});

  @override
  RelatedNewsListState createState() => RelatedNewsListState();
}

class RelatedNewsListState extends State<RelatedNewsList> {
  List<NewsModel> relatedList = [];

  Widget getRelatedList() {
    return BlocConsumer<RelatedNewsCubit, RelatedNewsState>(
        bloc: context.read<RelatedNewsCubit>(),
        listener: (context, state) {
          if (state is RelatedNewsFetchSuccess) {
            setState(() {
              relatedList.clear();
              relatedList.addAll(state.relatedNews);
              relatedList.removeWhere((element) =>
                  (element.id == widget.model.id!) ||
                  (element.id == widget.model.newsId!));
            });
          }
        },
        builder: (context, state) {
          if (state is RelatedNewsFetchSuccess && relatedList.isNotEmpty) {
            return Padding(
                // 20px container padding + 12px header padding above the
                // heading, 12px header padding below the list.
                padding:
                    const EdgeInsetsDirectional.only(top: 32.0, bottom: 12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextLabel(
                          text: 'relatedNews',
                          textStyle: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer,
                                  fontSize: 20,
                                  height: 28 / 20,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      showRelatedNews(relatedList),
                      if (state.hasMore)
                        _loadMoreFooter(state.hasMoreFetchError),
                    ]));
          }
          return const SizedBox
              .shrink(); //state is RelatedNewsFetchInProgress || state is RelatedNewsInitial || state is RelatedNewsFetchFailure
        });
  }

  /// Spinner while the next page loads, or a retry button if it failed.
  Widget _loadMoreFooter(bool hasError) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
            child: hasError
                ? IconButton(
                    onPressed: widget.onLoadMore,
                    icon: Icon(Icons.error,
                        color: Theme.of(context).primaryColor))
                : UiUtils.showCircularProgress(
                    true, Theme.of(context).primaryColor)));
  }

  void _openNews(NewsModel model, List<NewsModel> newsList) {
    List<NewsModel> addNewsList = [];
    addNewsList.addAll(newsList);
    addNewsList.remove(model);
    UiUtils.showInterstitialAds(context: context);
    Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
      "model": model,
      "newsList": addNewsList,
      "isFromBreak": false,
      "fromShowMore": false
    });
  }

  Widget showRelatedNews(List<NewsModel> relatedNews) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      for (int i = 0; i < relatedNews.length; i++) ...[
        if (i > 0) ...[
          // Figma draws the 1px divider on the row just above its layout line:
          // 7px under the previous item, with 8px below it. The line itself is
          // 354px wide, i.e. 4px short of the 358px row.
          const SizedBox(height: 7),
          Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? darkBorderDefaultColor : borderDefaultColor)),
          const SizedBox(height: 8),
        ],
        _RelatedNewsItem(
            model: relatedNews[i],
            onTap: () => _openNews(relatedNews[i], relatedNews)),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return getRelatedList();
  }
}

/// Figma "News Item": a 78px thumbnail beside a two-line title, with a
/// "time ago • views" row underneath. The title is Inter Medium in Figma; Inter
/// isn't bundled, so this uses Roboto Medium like the homepage rows do.
class _RelatedNewsItem extends StatelessWidget {
  final NewsModel model;
  final VoidCallback onTap;

  const _RelatedNewsItem({required this.model, required this.onTap});

  String? _timeAgo(BuildContext context) {
    final String? rawDate = model.publishDate ?? model.date;
    if (rawDate == null || rawDate.isEmpty) return null;
    try {
      return UiUtils.convertToAgo(context, DateTime.parse(rawDate), 0);
    } catch (_) {
      return null;
    }
  }

  String? _viewsText(BuildContext context) {
    // Nothing is shown for 0 (or a missing/unparsable value) so the row never
    // reads "0 read".
    final int views = int.tryParse(model.totalViews ?? '') ?? 0;
    if (views <= 0) return null;
    return "${_compactCount(views)} ${UiUtils.getTranslatedLabel(context, 'read')}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Text/Secondary is #676767 in light and #A0A0A0 in dark; Icon/Secondary is
    // #676767 in light and #CECECE in dark.
    final Color metaColor = isDark ? textTertiaryColor : textSecondaryColor;
    final Color dotColor =
        isDark ? darkIconSecondaryColor : textSecondaryColor;
    final TextStyle metaStyle =
        TextStyle(fontSize: 12.0, height: 16 / 12, color: metaColor);
    final String? timeAgo = _timeAgo(context);
    final String? viewsText = _viewsText(context);
    final bool hasTime = timeAgo != null && timeAgo.isNotEmpty;
    final bool hasViews = viewsText != null && viewsText.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: CustomNetworkImage(
                  networkImageUrl: model.image ?? "",
                  width: 78.0,
                  height: 78.0,
                  isVideo: false,
                  fit: BoxFit.cover),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomTextLabel(
                    text: model.title ?? "",
                    textStyle: TextStyle(
                        fontSize: 14.0,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color:
                            UiUtils.getColorScheme(context).primaryContainer),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  if (hasTime || hasViews) ...<Widget>[
                    const SizedBox(height: 6.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (hasTime)
                          Flexible(
                            child: CustomTextLabel(
                                text: timeAgo,
                                textStyle: metaStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        if (hasTime && hasViews) ...<Widget>[
                          const SizedBox(width: 6.0),
                          Container(
                            width: 5.0,
                            height: 5.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: dotColor),
                          ),
                          const SizedBox(width: 6.0),
                        ],
                        if (hasViews)
                          Flexible(
                            child: CustomTextLabel(
                                text: viewsText,
                                textStyle: metaStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
