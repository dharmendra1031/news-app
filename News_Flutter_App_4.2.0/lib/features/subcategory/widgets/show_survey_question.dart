import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/cubits/get_survey_answer_cubit.dart';
import 'package:news/features/news/cubits/set_survey_answer_cubit.dart';
import 'package:news/features/news/cubits/survey_question_cubit.dart';
import 'package:news/core/theme/theme_colors.dart';

import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';

class ShowSurveyQue extends StatefulWidget {
  final NewsModel model;
  final int index;
  final String surveyId;
  final bool isPaddingRequired;
  final Function(NewsModel, int) updateList;

  const ShowSurveyQue(
      {super.key,
      required this.model,
      required this.index,
      required this.surveyId,
      required this.updateList,
      this.isPaddingRequired = true});

  @override
  ShowSurveyQueState createState() => ShowSurveyQueState();
}

class ShowSurveyQueState extends State<ShowSurveyQue> {
  String? optSel;

  // SetSurveyAnsCubit / GetSurveyAnsCubit are app-wide, so every survey card on
  // screen hears every submit. Only the card that was tapped may react.
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return showSurveyQue();
  }

  // Light / dark palette for the survey card.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardColor => _isDark ? const Color(0xff262626) : secondaryColor;
  Color get _cardBorder =>
      _isDark ? darkBorderDefaultColor : borderDefaultColor;
  Color get _questionColor => _isDark ? secondaryColor : textPrimaryColor;
  Color get _optionColor => _isDark ? const Color(0xff333333) : backgroundColor;
  Color get _optionTextColor =>
      _isDark ? darkIconSecondaryColor : textPrimaryColor;
  Color get _accent => _isDark ? darkIconColor : primaryColor;
  // Figma Button/Primary/BG (#E00000) + Button/Primary/Text (#FFFFFF) in both themes.
  Color get _submitColor => primaryColor;
  Color get _submitTextColor => secondaryColor;

  Widget showSurveyQue() {
    return BlocConsumer<SetSurveyAnsCubit, SetSurveyAnsState>(
        bloc: context.read<SetSurveyAnsCubit>(),
        listener: (context, state) {
          if (!isSubmitting) return;
          if (state is SetSurveyAnsFetchSuccess) {
            showSnackBar(state.message, context);
            //debugPrint("Set survey ans success****${widget.model.id} ***** ${widget.model.question!} **** ${widget.surveyId}");
            context.read<SurveyQuestionCubit>().removeQuestion(widget.surveyId);
            context.read<GetSurveyAnsCubit>().getSurveyAns(
                langCode:
                    context.read<AppLocalizationCubit>().state.languageCode);
          }
          if (state is SetSurveyAnsFetchFailure) {
            isSubmitting = false;
            showSnackBar(state.errorMessage, context);
          }
        },
        builder: (context, state) {
          return BlocConsumer<GetSurveyAnsCubit, GetSurveyAnsState>(
              bloc: context.read<GetSurveyAnsCubit>(),
              listener: (context, state) {
                if (!isSubmitting) return;
                if (state is GetSurveyAnsFetchSuccess) {
                  isSubmitting = false;
                  final matches = state.getSurveyAns
                      .where((element) => element.id == widget.model.id);
                  if (matches.isEmpty) {
                    debugPrint(
                        "Survey result missing: question ${widget.model.id} not in answered ids ${state.getSurveyAns.map((e) => e.id).toList()}");
                  }
                  for (var element in matches) {
                    NewsModel newModel = element;
                    newModel.from = 2;
                    widget.updateList(newModel, widget.index);
                  }
                }
                if (state is GetSurveyAnsFetchFailure) {
                  isSubmitting = false;
                  showSnackBar(state.errorMessage, context);
                }
              },
              builder: (context, state) {
                return Padding(
                    padding: EdgeInsets.only(
                        top: 15.0,
                        left: (widget.isPaddingRequired) ? 15 : 0,
                        right: (widget.isPaddingRequired) ? 15 : 0),
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: _cardBorder),
                            color: _cardColor),
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            CustomTextLabel(
                                text: widget.model.question!,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        color: _questionColor,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3)),
                            Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    top: 15.0, start: 7.0, end: 7.0),
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount:
                                        widget.model.optionDataList!.length,
                                    itemBuilder: (context, j) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10.0),
                                        child: InkWell(
                                          child: Container(
                                              height: 50,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                  border: Border.all(
                                                      color: optSel == widget.model.optionDataList![j].id
                                                          ? _accent
                                                          : Colors.transparent),
                                                  color: optSel == widget.model.optionDataList![j].id
                                                      ? _accent.withOpacity(0.12)
                                                      : _optionColor),
                                              child: CustomTextLabel(
                                                  text: widget
                                                      .model
                                                      .optionDataList![j]
                                                      .options!,
                                                  textStyle: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                          color: optSel == widget.model.optionDataList![j].id
                                                              ? _accent
                                                              : _optionTextColor,
                                                          height: 1.0),
                                                  textAlign: TextAlign.center)),
                                          onTap: () {
                                            setState(() {
                                              optSel = widget
                                                  .model.optionDataList![j].id;
                                            });
                                          },
                                        ),
                                      );
                                    })),
                            Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: InkWell(
                                  child: Container(
                                    height: 40.0,
                                    width: MediaQuery.of(context).size.width *
                                        0.35,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: _submitColor,
                                        borderRadius:
                                            BorderRadius.circular(7.0)),
                                    child: CustomTextLabel(
                                      text: 'submitBtn',
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              color: _submitTextColor,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.6),
                                    ),
                                  ),
                                  onTap: () async {
                                    if (isSubmitting) return;
                                    if (optSel != null) {
                                      isSubmitting = true;
                                      context
                                          .read<SetSurveyAnsCubit>()
                                          .setSurveyAns(
                                              optId: optSel!,
                                              queId: widget.surveyId,
                                              languageCode: context
                                                  .read<AppLocalizationCubit>()
                                                  .state
                                                  .languageCode);
                                      await Future.delayed(
                                          Duration(seconds: 2));
                                    } else {
                                      showSnackBar(
                                          UiUtils.getTranslatedLabel(
                                              context, 'optSel'),
                                          context);
                                    }
                                  }),
                            )
                          ],
                        )));
              });
        });
  }
}
