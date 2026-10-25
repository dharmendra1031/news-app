import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/news_item.dart';
import 'package:news/features/news/cubits/subcat_news_cubit.dart';
import 'package:news/features/news/cubits/survey_question_cubit.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart'; 
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/shimmer_news_list.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/subcategory/widgets/show_survey_question.dart';
import 'package:news/features/subcategory/widgets/show_survey_result.dart';
import 'package:news/utils/ui_utils.dart';

class SubCatNewsList extends StatefulWidget {
  final int from;
  final String catId;
  final String? subCatId;

  const SubCatNewsList(
      {super.key, required this.from, required this.catId, this.subCatId});

  @override
  SubCatNewsListState createState() => SubCatNewsListState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => SubCatNewsList(
            from: arguments['from'],
            catId: arguments['catId'],
            subCatId: arguments['subCatId']));
  }
}

class SubCatNewsListState extends State<SubCatNewsList>
    with AutomaticKeepAliveClientMixin {
  List<NewsModel> combineList = [];
  int totalSurveyQue = 0;
  Set<String> get locationValue =>
      SettingsLocalDataRepository().getLocationCityValues();
  late final ScrollController controller = ScrollController()
    ..addListener(hasMoreNotiScrollListener);

  @override
  void initState() {
    getSubCatNewsData();
    super.initState();
  }

  @override
  void dispose() {
    totalSurveyQue = 0;
    controller.dispose();
    super.dispose();
  }

  Future getSubCatNewsData() async {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      if (context.read<AuthCubit>().getUserId() != "0") {
        context
            .read<SurveyQuestionCubit>()
            .getSurveyQuestion(
                langCode:
                    context.read<AppLocalizationCubit>().state.languageCode)
            .whenComplete(() {
          if (mounted) getSubcategoryNews();
        });
      } else {
        getSubcategoryNews();
      }
    });
  }

  void hasMoreNotiScrollListener() {
    if (controller.position.maxScrollExtent == controller.offset) {
      if (context.read<SubCatNewsCubit>().hasMoreSubCatNews()) {
        context.read<SubCatNewsCubit>().getMoreSubCatNews(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            subCatId: widget.from == 2 ? widget.subCatId : null,
            catId: widget.from == 1 ? widget.catId : null,
            latitude: locationValue.first,
            longitude: locationValue.last);
      } else {
        //debugPrint("No more news for this Category");
      }
    }
  }

  updateCombineList(NewsModel model, int index) {
    setState(() {
      combineList[index] = model;
    });
  }

  Widget getNewsList() {
    return BlocConsumer<SubCatNewsCubit, SubCatNewsState>(
        bloc: context.read<SubCatNewsCubit>(),
        listener: (context, state) {
          if (state is SubCatNewsFetchSuccess) {
            combineList.clear();
            int cur = 0;
            for (int i = 0; i < (state).subCatNews.length; i++) {
              if (i != 0 && i % surveyShow == 0) {
                if (context
                        .read<SurveyQuestionCubit>()
                        .surveyList()
                        .isNotEmpty &&
                    context.read<SurveyQuestionCubit>().surveyList().length >
                        cur) {
                  combineList.add(
                      context.read<SurveyQuestionCubit>().surveyList()[cur]);
                  cur++;
                }
              }
              combineList.add((state).subCatNews[i]);
            }
          }
        },
        builder: (context, stateSubCat) {
          if (stateSubCat is SubCatNewsFetchSuccess) {
            return combineNewsList(stateSubCat, stateSubCat.subCatNews);
          }
          if (stateSubCat is SubCatNewsFetchFailure) {
            return ErrorContainerWidget(
                errorMsg: (stateSubCat.errorMessage
                        .contains(ErrorMessageKeys.noInternet))
                    ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                    : stateSubCat.errorMessage,
                onRetry: getSubCatNewsData);
          }
          //stateSubCat is SubCatNewsFetchInProgress || stateSubCat is SubCatNewsInitial
          return ShimmerNewsList(isNews: true);
        });
  }

  setTotalSurveyQueCount() {
    for (var element in combineList) {
      if (element.type == "survey") totalSurveyQue += 1;
    }
  }

  Widget combineNewsList(
      SubCatNewsFetchSuccess state, List<NewsModel> newsList) {
    setTotalSurveyQueCount();
    return RefreshIndicator(
      onRefresh: () async {
        combineList.clear();
        if (context.read<AuthCubit>().getUserId() != "0") {
          context
              .read<SurveyQuestionCubit>()
              .getSurveyQuestion(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode)
              .whenComplete(() {
            if (mounted) getSubcategoryNews();
          });
        } else {
          getSubcategoryNews();
        }
        setTotalSurveyQueCount();
        setState(() {});
      },
      child: ListView.builder(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 15),
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller,
          itemCount: combineList.length,
          itemBuilder: (context, index) {
            return _buildNewsContainer(
                model: combineList[index],
                hasMore: state.hasMore,
                hasMoreNewsFetchError: state.hasMoreFetchError,
                index: index,
                totalCurrentNews: combineList.length,
                newsList: newsList);
          }),
    );
  }

  void getSubcategoryNews() {
    context.read<SubCatNewsCubit>().getSubCatNews(
        langCode: context.read<AppLocalizationCubit>().state.languageCode,
        subCatId: widget.from == 2 ? widget.subCatId : null,
        catId: widget.from == 1 ? widget.catId : null,
        latitude: locationValue.first,
        longitude: locationValue.last);
  }

  _buildNewsContainer(
      {required NewsModel model,
      required int index,
      required int totalCurrentNews,
      required bool hasMoreNewsFetchError,
      required bool hasMore,
      required List<NewsModel> newsList}) {
    if (index == totalCurrentNews - 1 && index != 0) {
      if (hasMore) {
        if (hasMoreNewsFetchError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
              child: IconButton(
                  onPressed: () {
                    context.read<SubCatNewsCubit>().getMoreSubCatNews(
                        langCode: context
                            .read<AppLocalizationCubit>()
                            .state
                            .languageCode,
                        subCatId: widget.from == 2 ? widget.subCatId : null,
                        catId: widget.from == 1 ? widget.catId : null,
                        latitude: locationValue.first,
                        longitude: locationValue.last);
                  },
                  icon:
                      Icon(Icons.error, color: Theme.of(context).primaryColor)),
            ),
          );
        } else {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 8.0),
                  child: UiUtils.showCircularProgress(
                      true, Theme.of(context).primaryColor)));
        }
      }
    }
    return model.type == "survey"
        ? model.from == 2
            ? showSurveyQueResult(model, context, true)
            : ShowSurveyQue(
                model: model,
                index: index,
                surveyId: model.id!,
                updateList: updateCombineList)
        : NewsItem(
            model: model,
            index: (index <= totalSurveyQue) ? index : (index - totalSurveyQue),
            newslist: newsList,
            fromShowMore: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return getNewsList();
  }

  @override
  bool get wantKeepAlive => true;
}
