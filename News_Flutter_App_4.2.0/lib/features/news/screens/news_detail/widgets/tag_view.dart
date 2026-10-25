import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';

Widget tagView(
    {required NewsModel model,
    required BuildContext context,
    bool? isFromDetailsScreen = false}) {
  List<String> tagList = [];

  if (model.tagName! != "") {
    final tagName = model.tagName!;
    tagList = tagName.split(',');
  }

  List<String> tagId = [];

  if (model.tagId != null && model.tagId! != "") {
    tagId = model.tagId!.split(",");
  }

  return model.tagName! != ""
      ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tagList.length, (index) {
              return Padding(
                  padding:
                      EdgeInsetsDirectional.only(start: index == 0 ? 0 : 10),
                  child: InkWell(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(1000.0),
                        child: (isFromDetailsScreen != null &&
                                isFromDetailsScreen)
                            ? tagsContainer(
                                context: context,
                                tagList: tagList,
                                index: index)
                            : BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                child: tagsContainer(
                                    context: context,
                                    tagList: tagList,
                                    index: index))),
                    onTap: () {
                      if (index >= tagId.length || tagId[index].isEmpty) return;
                      Navigator.of(context).pushNamed(Routes.tagScreen,
                          arguments: {
                            "tagId": tagId[index],
                            "tagName": tagList[index]
                          });
                    },
                  ));
            }),
          ),
        )
      : const SizedBox.shrink();
}

Widget tagsContainer(
    {required BuildContext context,
    required List<String> tagList,
    required int index}) {
  // FIGMA(3768-8884 light / 3768-9010 dark): outlined stadium pill — 1px
  // Border/Black on a transparent fill (solid white in dark), 14/4 padding,
  // Text/Primary label at 12px.
  final Color onColor = UiUtils.getColorScheme(context).primaryContainer;
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
      alignment: Alignment.center,
      padding:
          const EdgeInsetsDirectional.only(start: 14.0, end: 14.0, top: 4.0, bottom: 4.0),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(1000)),
          border:
              Border.all(color: isDark ? onColor : onColor.withOpacity(0.85))),
      child: CustomTextLabel(
          text: tagList[index],
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: onColor,
              fontSize: 12,
              height: 16 / 12,
              // Figma centres the glyphs in the 16px line; Flutter's default
              // weights the spare space toward the top, which sat the label
              // low in the pill.
              leadingDistribution: TextLeadingDistribution.even,
              letterSpacing: 0),
          overflow: TextOverflow.ellipsis,
          softWrap: true));
}
