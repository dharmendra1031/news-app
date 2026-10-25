import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/news_item.dart';
import 'package:news/commons/widgets/shimmer_news_list.dart';
import 'package:news/features/news/cubits/related_news_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/utils/ui_utils.dart';

class ShowMoreNewsList extends StatefulWidget {
  final NewsModel model;

  const ShowMoreNewsList({super.key, required this.model});

  @override
  ShowMoreNewsListState createState() => ShowMoreNewsListState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => ShowMoreNewsList(model: arguments['model']));
  }
}

class ShowMoreNewsListState extends State<ShowMoreNewsList> {
  late final ScrollController controller = ScrollController()
    ..addListener(hasMoreRelatedNewsScrollListener);
  Set<String> get locationValue =>
      SettingsLocalDataRepository().getLocationCityValues();

  void hasMoreRelatedNewsScrollListener() {
    if (controller.position.maxScrollExtent == controller.offset) {
      if (context.read<RelatedNewsCubit>().hasMoreRelatedNews()) {
        context.read<RelatedNewsCubit>().getMoreRelatedNews(
            langCode: context.read<AppLocalizationCubit>().state.languageCode,
            catId: widget.model.subCatId == "0" || widget.model.subCatId == ''
                ? widget.model.categoryId
                : null,
            subCatId:
                widget.model.subCatId != "0" || widget.model.subCatId != ''
                    ? widget.model.subCatId
                    : null,
            latitude: locationValue.first,
            longitude: locationValue.last);
      } else {
        //debugPrint("No more RelatedNews");
      }
    }
  }

  _buildRelatedNewsContainer(
      {required NewsModel model,
      required int index,
      required int totalCurrentRelatedNews,
      required bool hasMoreRelatedNewsFetchError,
      required bool hasMore,
      required List<NewsModel> newsList}) {
    if (index == totalCurrentRelatedNews - 1 && index != 0) {
      if (hasMore) {
        if (hasMoreRelatedNewsFetchError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
              child: IconButton(
                  onPressed: () {
                    context.read<RelatedNewsCubit>().getMoreRelatedNews(
                        langCode: context
                            .read<AppLocalizationCubit>()
                            .state
                            .languageCode,
                        catId: widget.model.subCatId == "0" ||
                                widget.model.subCatId == ''
                            ? widget.model.categoryId
                            : null,
                        subCatId: widget.model.subCatId != "0" ||
                                widget.model.subCatId != ''
                            ? widget.model.subCatId
                            : null,
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

    return NewsItem(
        model: model, index: index, newslist: newsList, fromShowMore: true);
  }

  void refreshNewsList() {
    context.read<RelatedNewsCubit>().getRelatedNews(
        langCode: context.read<AppLocalizationCubit>().state.languageCode,
        catId: widget.model.subCatId != "0" || widget.model.subCatId == ''
            ? widget.model.categoryId
            : null,
        subCatId: widget.model.subCatId != "0" || widget.model.subCatId != ''
            ? widget.model.subCatId
            : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          height: 45,
          isBackBtn: true,
          label: 'relatedNews',
          horizontalPad: 15,
          isConvertText: true),
      body: BlocBuilder<RelatedNewsCubit, RelatedNewsState>(
        builder: (context, state) {
          if (state is RelatedNewsFetchSuccess) {
            return RefreshIndicator(
              onRefresh: () async {
                refreshNewsList();
              },
              child: ListView.builder(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: state.relatedNews.length,
                  itemBuilder: (context, index) {
                    return _buildRelatedNewsContainer(
                        model: state.relatedNews[index],
                        hasMore: state.hasMore,
                        hasMoreRelatedNewsFetchError: state.hasMoreFetchError,
                        index: index,
                        totalCurrentRelatedNews: state.relatedNews.length,
                        newsList: state.relatedNews);
                  }),
            );
          }

          if (state is RelatedNewsFetchFailure) {
            return ErrorContainerWidget(
                errorMsg:
                    (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : state.errorMessage,
                onRetry: refreshNewsList);
          }
          //state is RelatedNewsInitial || state is RelatedNewsFetchInProgress
          return Padding(
              padding:
                  const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
              child: ShimmerNewsList(isNews: true));
        },
      ),
    );
  }
}
