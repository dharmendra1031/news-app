import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/live_streaming/models/live_streaming_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/videos/widgets/video_list_card.dart';
import 'package:news/utils/ui_utils.dart';

/// FIGMA(3371-4337): "video card" in the Recent News Video list — a 9px-padded
/// surface card, a 144x98 thumbnail with a 0.4 dark overlay and centred play
/// circle, and beside it the category tag (only when there is one), a two-line
/// title and the date + views row.
class OtherVideosCard extends StatelessWidget {
  final NewsModel? model;
  final BreakingNewsModel? brModel;
  final LiveStreamingModel? liveModel;
  OtherVideosCard({super.key, this.model, this.brModel, this.liveModel});

  static const double _thumbWidth = 144.0;
  static const double _thumbHeight = 98.0;

  String? _formattedDate() {
    final String raw = (liveModel != null)
        ? liveModel!.updatedDate ?? ''
        : (model?.publishDate ?? model?.date ?? '');
    final DateTime? parsed = DateTime.tryParse(raw);
    return parsed == null ? null : DateFormat('dd MMM yyyy').format(parsed);
  }

  String? _views() {
    final String? raw = (liveModel != null)
        ? liveModel!.totalViews
        : (model != null)
            ? model!.totalViews
            : brModel?.totalViews;
    return parseVideoViews(raw) == null ? null : raw!.trim();
  }

  @override
  Widget build(BuildContext context) {
    bool isLive = liveModel != null;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String? categoryName = (!isLive) ? model?.categoryName?.trim() : null;
    final bool hasCategory = categoryName != null && categoryName.isNotEmpty;
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        bool isNews = (model != null) ? true : false;
        bool isBreakingNews = (brModel != null) ? true : false;
        // bool isLive = (liveModel != null) ? true : false;
        int fromVal = (isNews)
            ? 1
            : (isBreakingNews
                ? 2
                : 3); // VAL 1 = news, 2 = liveNews , 3 = breakingNews
        // and pass current model accordingly.Do not pass other videos - set it from newsVideo screen only
        Map<String, dynamic> videoArguments = {
          "from": fromVal,
        };
        if (fromVal == 1) {
          videoArguments.addAll({"model": model});
        } else if (fromVal == 2) {
          videoArguments.addAll({"brModel": brModel});
        } else {
          videoArguments.addAll({"liveModel": liveModel});
        }
        Navigator.pushReplacementNamed(context, Routes.newsVideo,
            arguments: videoArguments);
      },
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            color: UiUtils.getColorScheme(context).surface,
            borderRadius: BorderRadius.circular(8),
            // Card and screen are the same colour in dark, so it needs an edge
            // to read as a card; in light it is white on Background/Primary.
            border:
                isDark ? Border.all(color: darkBorderDefaultColor) : null),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: _thumbWidth,
                  height: _thumbHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomNetworkImage(
                          networkImageUrl: (isLive)
                              ? liveModel!.image!
                              : (model != null)
                                  ? model!.image!
                                  : brModel!.image!,
                          height: _thumbHeight,
                          width: _thumbWidth,
                          fit: BoxFit.cover),
                      Container(color: Colors.black.withOpacity(0.4)),
                      Center(
                        child: SvgPictureWidget(
                            assetName: 'video_circle', height: 32, width: 32),
                      ),
                    ],
                  ),
                )),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasCategory) ...[
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color:
                                UiUtils.getColorScheme(context).primaryContainer,
                            borderRadius: BorderRadius.circular(4)),
                        child: CustomTextLabel(
                            text: categoryName,
                            textStyle: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                // Figma centres the glyphs in the 16px line;
                                // Flutter's default weights the spare space
                                // toward the top, which sat the label low in
                                // the chip.
                                leadingDistribution:
                                    TextLeadingDistribution.even,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? darkTextInverseColor
                                    : Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(height: 4),
                  ],
                  CustomTextLabel(
                      text: (isLive)
                          ? liveModel!.title!
                          : (model != null)
                              ? model!.title ?? ""
                              : brModel!.title ?? "",
                      textStyle: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w500,
                          color: UiUtils.getColorScheme(context).onPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (_formattedDate() != null || _views() != null) ...[
                    const SizedBox(height: 4),
                    VideoMetaRow(timeAgo: _formattedDate(), views: _views()),
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
