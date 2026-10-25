// The "Live News" carousel on the home screen (Figma "Live news Conatainer",
// node 3717:7957): a radar-icon header followed by a horizontally scrolling
// row of live-stream thumbnail cards, with dot pagination tracking scroll
// position. Tapping a card opens it the same way the full "Live Videos" list
// screen does.

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/live_streaming/models/live_streaming_model.dart';
import 'package:news/utils/ui_utils.dart';

class LiveNewsHomeSection extends StatefulWidget {
  final List<LiveStreamingModel> liveStream;

  const LiveNewsHomeSection({super.key, required this.liveStream});

  @override
  State<LiveNewsHomeSection> createState() => _LiveNewsHomeSectionState();
}

class _LiveNewsHomeSectionState extends State<LiveNewsHomeSection> {
  static const double _cardWidth = 176.0;
  static const double _cardGap = 12.0;
  static const double _cardStep = _cardWidth + _cardGap;

  final ScrollController _scrollController = ScrollController();
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateActiveIndex);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateActiveIndex);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateActiveIndex() {
    final int index = (_scrollController.offset / _cardStep)
        .round()
        .clamp(0, widget.liveStream.length - 1);
    if (index != _activeIndex) setState(() => _activeIndex = index);
  }

  void _openLiveVideo(BuildContext context, int index) {
    final otherLiveVideos = List<LiveStreamingModel>.from(widget.liveStream)
      ..removeAt(index);
    Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
      "from": 2,
      "liveModel": widget.liveStream[index],
      "otherLiveVideos": otherLiveVideos,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.liveStream.isEmpty) return const SizedBox.shrink();

    final colorScheme = UiUtils.getColorScheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPictureWidget(assetName: "radar", height: 22.0, width: 22.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: CustomTextLabel(
                text: 'liveNewsLbl',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textStyle: TextStyle(
                  fontSize: 20.0,
                  height: 28 / 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 192.0,
          child: ListView.separated(
            // The rail runs off the screen edges in the design, past the 16px
            // page gutter this section sits inside, instead of being clipped
            // 16px short of them while it slides.
            clipBehavior: Clip.none,
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.liveStream.length,
            separatorBuilder: (_, __) => const SizedBox(width: _cardGap),
            itemBuilder: (context, index) => _LiveNewsCard(
              model: widget.liveStream[index],
              onTap: () => _openLiveVideo(context, index),
            ),
          ),
        ),
        if (widget.liveStream.length > 1) ...[
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < widget.liveStream.length; i++)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: i == 0 ? 0.0 : 8.0),
                  child: Container(
                    height: 8.0,
                    width: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _activeIndex ? primaryColor : textTertiaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Figma "Live news container": a 176x192 thumbnail with a bottom-weighted
/// dark scrim, a top-right viewer-count tag, and a centered play badge.
class _LiveNewsCard extends StatelessWidget {
  final LiveStreamingModel model;
  final VoidCallback onTap;

  const _LiveNewsCard({required this.model, required this.onTap});

  bool get _hasViewerCount =>
      model.totalViews != null &&
      model.totalViews != "null" &&
      model.totalViews!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          width: 176.0,
          height: 192.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomNetworkImage(
                  networkImageUrl: model.image ?? "",
                  width: 176.0,
                  height: 192.0,
                  fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.52, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              if (_hasViewerCount)
                Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: CustomTextLabel(
                      text:
                          '${model.totalViews} ${UiUtils.getTranslatedLabel(context, 'viewerLbl')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textStyle: const TextStyle(
                        fontSize: 12.0,
                        height: 16 / 12,
                        fontWeight: FontWeight.w400,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),
              Center(child: UiUtils.setPlayButton(context: context, heightVal: 24.0)),
            ],
          ),
        ),
      ),
    );
  }
}
