// The Short News reader card, in the inshorts style: one bordered, rounded card
// that fills the screen under the app bar — a full-bleed image on top, then the
// headline, a grey summary, a "tap for more at <source> / <date>" line, and a
// dark blurred strip pinned to the bottom that teases the next story.
//
// Purely presentational: [NewsSubDetails] owns the views count and ads, and the
// parent screen hands the two taps in (open the story / go to the next one).

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/utils/ui_utils.dart';

class ShortNewsCard extends StatelessWidget {
  final NewsModel news;

  /// The story after this one. Drives the bottom strip, which is left out on
  /// the last story.
  final NewsModel? nextNews;

  /// Opens the story's details screen ("tap for more").
  final VoidCallback onTap;

  /// Moves on to [nextNews] (the bottom strip).
  final VoidCallback? onNextTap;

  const ShortNewsCard({
    super.key,
    required this.news,
    required this.onTap,
    this.nextNews,
    this.onNextTap,
  });

  static const double _margin = 12.0;
  static const double _radius = 12.0;
  static const double _imageAspect = 855 / 630;

  /// The image never takes more than this share of the card, so the headline
  /// and summary keep room on short screens.
  static const double _maxImageShare = 0.45;

  static const double _titleFontSize = 18.0;
  static const double _titleLineHeight = 1.4;
  static const double _descFontSize = 16.0;
  static const double _descLineHeight = 1.55;
  static const double _metaFontSize = 13.0;

  String get _plainDescription {
    final String raw =
        (news.desc?.trim().isNotEmpty ?? false) ? news.desc! : news.shortDesc ?? '';
    return (html_parser.parse(raw).body?.text ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// The publisher slot of "tap for more at …": the author when the story has
  /// one, otherwise its category.
  String? get _source {
    final String? author = news.userAthorDetails?.name?.trim();
    if (author != null && author.isNotEmpty) return author;
    final String? category = news.categoryName?.trim();
    return (category == null || category.isEmpty) ? null : category;
  }

  /// "today" for a story from today, otherwise "4 Aug 2026". Published date
  /// first, falling back to the created date (`published_date` is often null).
  String? _dateText(BuildContext context) {
    for (final String? raw in <String?>[news.publishDate, news.date]) {
      final DateTime? parsed =
          (raw == null || raw.isEmpty) ? null : DateTime.tryParse(raw);
      if (parsed == null) continue;
      final DateTime now = DateTime.now();
      if (parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day) {
        return UiUtils.getTranslatedLabel(context, 'today').toLowerCase();
      }
      return DateFormat('d MMM yyyy').format(parsed);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(_margin),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: DecoratedBox(
          // Drawn over the children so the full-bleed image and the strip
          // don't cover the 1px outline.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
                color: isDark ? darkBorderDefaultColor : borderDefaultColor),
          ),
          child: ColoredBox(
            color: isDark ? darkSecondaryColor : secondaryColor,
            child: LayoutBuilder(builder: (context, constraints) {
              final double imageHeight = math.min(
                  constraints.maxWidth / _imageAspect,
                  constraints.maxHeight * _maxImageShare);
              return Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: imageHeight,
                            width: double.infinity,
                            child: CustomNetworkImage(
                                networkImageUrl: news.image ?? "",
                                width: double.infinity,
                                height: imageHeight,
                                fit: BoxFit.cover),
                          ),
                          Expanded(child: _textBlock(context, isDark)),
                        ],
                      ),
                    ),
                  ),
                  if (nextNews != null)
                    _NextStoryStrip(
                        backdropUrl: news.image ?? "",
                        title: nextNews!.title ?? "",
                        onTap: onNextTap),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _textBlock(BuildContext context, bool isDark) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final String description = _plainDescription;
    // Summary is grey, the "tap for more" line lighter still. The light-mode
    // tokens swap in dark mode (Text/Secondary #A0A0A0, Text/Tertiary #676767).
    final Color descColor = isDark ? textTertiaryColor : textSecondaryColor;
    final Color metaColor = isDark ? textSecondaryColor : textTertiaryColor;
    final String? source = _source;
    final String? date = _dateText(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news.title ?? "",
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _titleFontSize,
              height: _titleLineHeight,
              fontWeight: FontWeight.w500,
              color: UiUtils.getColorScheme(context).primaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          // The summary takes whatever height is left and is cut with an
          // ellipsis on the last line that fits, so it never overflows the card.
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final double lineHeight =
                  scaler.scale(_descFontSize) * _descLineHeight;
              final int lines = (constraints.maxHeight / lineHeight).floor();
              if (lines < 1 || description.isEmpty) {
                return const SizedBox.shrink();
              }
              return Text(
                description,
                maxLines: lines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _descFontSize,
                  height: _descLineHeight,
                  fontWeight: FontWeight.w400,
                  color: descColor,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(
                  fontSize: _metaFontSize, height: 18 / 13, color: metaColor),
              children: [
                TextSpan(
                    text: UiUtils.getTranslatedLabel(
                        context, source == null ? 'tapForMoreLbl' : 'tapForMoreAtLbl')),
                if (source != null)
                  TextSpan(
                      text: ' $source',
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                if (date != null) TextSpan(text: ' / $date'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The dark strip along the bottom of the card: the story's own image, blurred
/// and dimmed, behind the next headline and a "Tap to know more" line.
class _NextStoryStrip extends StatelessWidget {
  final String backdropUrl;
  final String title;
  final VoidCallback? onTap;

  const _NextStoryStrip(
      {required this.backdropUrl, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xff1E1E1E),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                    sigmaX: 20, sigmaY: 20, tileMode: TileMode.mirror),
                child: CustomNetworkImage(
                    networkImageUrl: backdropUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholderBuilder: const SizedBox.shrink(),
                    errorBuilder: const SizedBox.shrink()),
              ),
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: Color(0x99000000))),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    UiUtils.getTranslatedLabel(context, 'tapToKnowMoreLbl'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 18 / 13,
                        color: Color(0xCCFFFFFF)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
