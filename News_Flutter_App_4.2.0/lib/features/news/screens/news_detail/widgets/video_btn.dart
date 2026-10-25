import 'package:flutter/material.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/core/routes/routes.dart';

Widget videoBtn(
    {required BuildContext context,
    required bool isFromBreak,
    NewsModel? model,
    BreakingNewsModel? breakModel}) {
  // Only items that actually carry a video get the play button: a
  // `standard_post` (or any other non-video type) has nothing to open.
  final String? contentType =
      isFromBreak ? breakModel?.contentType : model?.contentType;
  final String? contentValue =
      isFromBreak ? breakModel?.contentValue : model?.contentValue;
  final bool hasVideo = videoTypeFromString(contentType) != VideoType.unknown &&
      (contentValue ?? "").trim().isNotEmpty;

  if (hasVideo) {
    return InkWell(
      child: SvgPictureWidget(
          assetName: 'videoPlay',
          height: 39,
          width: 39,
          assetColor: ColorFilter.mode(secondaryColor, BlendMode.srcIn)),

     
      onTap: () {
        Navigator.of(context).pushNamed(Routes.newsVideo,
            arguments: (!isFromBreak)
                ? {"from": 1, "model": model}
                : {
                    "from": 3,
                    "breakModel": breakModel,
                    "otherVideos": <NewsModel>[],
                    "otherBreakingVideos": <BreakingNewsModel>[]
                  });
      },
    );
  } else {
    return const SizedBox.shrink();
  }
}
