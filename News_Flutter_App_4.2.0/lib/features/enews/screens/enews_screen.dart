import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/app.dart';
import 'package:news/features/enews/screens/enews_pdf_viewer_screen.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/enews/cubits/enews_cubit.dart';
import 'package:news/features/enews/models/enews_model.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

// FIGMA(3040-6040): eNews screen — 2-col grid, bg #EFEFEF (Background/Primary)
// Cards: white, radius 8, thumbnail 141px, date chip bottom-left with clock
// icon + navy-70 pill. View button: red #ee2934, radius 4, text only.

class ENewsScreen extends StatefulWidget {
  const ENewsScreen({super.key});

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const ENewsScreen());
  }

  @override
  State<ENewsScreen> createState() => _ENewsScreenState();
}

class _ENewsScreenState extends State<ENewsScreen> {
  static const int _perPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchENews();
    _scrollController.addListener(_onScroll);
  }

  void _fetchENews() {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      context.read<ENewsCubit>().getENews(
            languageCode:
                context.read<AppLocalizationCubit>().state.languageCode,
            perPage: _perPage,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ENewsCubit>().getMoreENews(
            languageCode:
                context.read<AppLocalizationCubit>().state.languageCode,
            perPage: _perPage,
          );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIGMA(3040-6086): AppBar — bg #EFEFEF with drop shadow, height 54px
      appBar: CustomAppBar(
          height: 45, isBackBtn: true, label: 'eNewsLbl', isConvertText: true),
      // FIGMA(3040-6040): screen bg follows theme (#EFEFEF light / #1E1E1E dark)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<ENewsCubit, ENewsState>(
        builder: (context, state) {
          if (state is ENewsFetchInProgress || state is ENewsInitial) {
            return _buildShimmer();
          }

          if (state is ENewsFetchFailure) {
            return Center(
                child: ErrorContainerWidget(
                    errorMsg: state.errorMessage, onRetry: _fetchENews));
          }

          if (state is ENewsFetchSuccess) {
            if (state.eNewsList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.newspaper,
                        size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                        UiUtils.getTranslatedLabel(
                            context, 'eNewsNotAvailable'),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ScrollConfiguration(
              behavior: GlobalScrollBehavior(),
              child: GridView.builder(
                controller: _scrollController,
                // FIGMA(3040-6040): grid padding 16px all, spacing 8px
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  // Increased height from 280→300 to prevent description cut-off
                  childAspectRatio: 171 / 300,
                ),
                itemCount: state.eNewsList.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.eNewsList.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _ENewsGridItem(eNews: state.eNewsList[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      // FIGMA: same padding/spacing as data grid
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 171 / 300,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _ShimmerCard(),
    );
  }
}

class _ENewsGridItem extends StatelessWidget {
  final ENewsModel eNews;

  const _ENewsGridItem({required this.eNews});

  void _openPdf(BuildContext context) {
    if (eNews.attachment != null && eNews.attachment!.isNotEmpty) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => ENewsPdfViewerScreen(
              title: eNews.title, pdfUrl: eNews.attachment!),
        ),
      );
    }
  }

  String? _plainDescription() {
    if (eNews.description == null || eNews.description!.trim().isEmpty) {
      return null;
    }
    // Strip basic HTML tags for display
    return eNews.description!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  String? _formattedDate() {
    if (eNews.date == null || eNews.date!.isEmpty) return null;
    try {
      return DateFormat("MMM dd,yyyy",
              Hive.box(settingsBoxKey).get(currentLanguageCodeKey))
          .format(DateTime.parse(eNews.date!));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? plainDesc = _plainDescription();
    final String? date = _formattedDate();
    final bool hasAttachment =
        eNews.attachment != null && eNews.attachment!.isNotEmpty;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // FIGMA(3040-6481): card — white bg (light) / dark surface + border (dark), radius 8
    return Material(
      color: isDark ? darkSecondaryColor : secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isDark
            ? const BorderSide(color: darkBorderDefaultColor)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasAttachment ? () => _openPdf(context) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIGMA(3040-6120): thumbnail area — 141px tall, date chip bottom-left
            _buildThumbnail(context, date),

            // FIGMA(3040-6345): content — px 7, py 8, gap 8
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIGMA(3040-6353): title + description block
                    // Use Expanded so this section always claims its fair share
                    // of vertical space and the description is never squeezed out.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // FIGMA(3040-6342): title — Roboto Medium 14/20,
                          // color #1b2d51, 2 lines max with ellipsis
                          Text(
                            eNews.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              height: 20 / 14,
                              letterSpacing: 0.1,
                              color: isDark
                                  ? secondaryColor
                                  : const Color(0xFF1B2D51),
                            ),
                          ),
                          // FIGMA(3040-6344): description — Roboto Regular 12,
                          // color rgba(27,45,81,0.5)
                          if (plainDesc != null) ...[
                            const SizedBox(height: 2),
                            Flexible(
                              child: Text(
                                plainDesc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 16 / 12,
                                  color: isDark
                                      ? textTertiaryColor
                                      : const Color(0x801B2D51),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // FIGMA(3040-6350): View button — red #ee2934, radius 4
                    _buildViewButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIGMA(3040-6350): "View" button — full width, red bg, white text
  // Roboto Medium 16/24, no icon (matches Figma exactly)
  Widget _buildViewButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        // FIGMA: primary-color #ee2934
        color: Color(0xFFEE2934),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      alignment: Alignment.center,
      child: Text(
        UiUtils.getTranslatedLabel(context, 'viewLbl'),
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          height: 24 / 16,
          letterSpacing: 0.15,
          color: Colors.white,
        ),
      ),
    );
  }

  // FIGMA(3040-6120): thumbnail — 141px, rounded top corners 8px
  // Date chip at bottom-left: navy-70 pill, clock icon + date text
  Widget _buildThumbnail(BuildContext context, String? date) {
    final bool hasThumb =
        eNews.thumbnail != null && eNews.thumbnail!.isNotEmpty;

    return SizedBox(
      height: 141,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          hasThumb
              ? CustomNetworkImage(
                  networkImageUrl: eNews.thumbnail!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : _pdfPlaceholder(context),

          // FIGMA(3040-6480): date chip — bottom-right corner, 8px inset
          // Align is used instead of Positioned for reliable placement
          if (date != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // FIGMA: secondry-70 = rgba(27,45,81,0.7)
                    color: const Color(0xB21B2D51),
                    borderRadius: BorderRadius.circular(2000),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // FIGMA(3040-6476): clock icon 16x16
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      // FIGMA(3040-6477): date text — Roboto Regular 10/16
                      // tracking 0.4, white
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                          height: 16 / 10,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pdfPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.picture_as_pdf_rounded,
        size: 48,
        color: Theme.of(context).primaryColor.withOpacity(0.5),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? darkSecondaryColor : secondaryColor,
            borderRadius: BorderRadius.circular(8),
            border: isDark ? Border.all(color: darkBorderDefaultColor) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail shimmer — 141px
              _shimmerBlock(context, double.infinity, 141),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerBlock(context, double.infinity, 14),
                          const SizedBox(height: 4),
                          _shimmerBlock(context, 110, 14),
                          const SizedBox(height: 6),
                          _shimmerBlock(context, double.infinity, 12),
                          const SizedBox(height: 4),
                          _shimmerBlock(context, 100, 12),
                        ],
                      ),
                      _shimmerBlock(context, double.infinity, 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBlock(BuildContext context, double width, double height) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2 * _animationController.value, 0),
          end: Alignment(1.0 + 2 * _animationController.value, 0),
          colors: isDark
              ? [
                  darkBorderDefaultColor,
                  textSecondaryColor.withOpacity(0.5),
                  darkBorderDefaultColor,
                ]
              : [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.grey.shade300,
                ],
        ),
      ),
    );
  }
}
