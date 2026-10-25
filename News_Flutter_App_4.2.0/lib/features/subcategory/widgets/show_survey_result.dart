import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:news/features/news/models/news_model.dart';

showSurveyQueResult(
    NewsModel model, BuildContext context, bool isPaddingRequired) {
  return Padding(
      padding: EdgeInsets.only(
          top: 15.0,
          left: (isPaddingRequired) ? 15 : 0,
          right: (isPaddingRequired) ? 15 : 0),
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: UiUtils.getColorScheme(context).surface),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              CustomTextLabel(
                  text: model.question!,
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                      height: 1.0)),
              Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 15.0, start: 7.0, end: 7.0),
                  child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: model.optionDataList!.length,
                      itemBuilder: (context, j) {
                        return Padding(
                            padding: const EdgeInsetsDirectional.only(
                                bottom: 10.0, start: 15.0, end: 15.0),
                            child: LinearPercentIndicator(
                                animation: true,
                                animationDuration: 1000,
                                lineHeight: 40.0,
                                percent:
                                    model.optionDataList![j].percentage! / 100,
                                center: CustomTextLabel(
                                    text:
                                        "${(model.optionDataList![j].percentage!).toStringAsFixed(2)}%",
                                    textStyle:
                                        Theme.of(context).textTheme.titleSmall),
                                barRadius: const Radius.circular(16),
                                progressColor: Theme.of(context).primaryColor,
                                isRTL: false,
                                padding: const EdgeInsets.only(
                                    top: 10.0, bottom: 10.0)));
                      })),
            ],
          )));
}
