import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/features/add_edit_news/blocs/get_user_drafted_news_cubit.dart'; 
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/add_edit_news/widgets/user_news_widgets.dart';
import 'package:news/utils/ui_utils.dart';

class UserDraftedNewsTab extends StatelessWidget {
  final ScrollController controller;
  final Widget contentShimmer;
  final Function fetchDraftedNews;
  final Function fetchMoreDraftedNews;

  UserDraftedNewsTab(
      {super.key,
      required this.controller,
      required this.contentShimmer,
      required this.fetchDraftedNews,
      required this.fetchMoreDraftedNews});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetUserDraftedNewsCubit, GetUserDraftedNewsState>(
        builder: (context, state) {
      if (state is GetUserDraftedNewsFetchSuccess) {
        if (state.GetUserDraftedNews.isEmpty)
          return ErrorContainerWidget(
              errorMsg: ErrorMessageKeys.noDataMessage,
              onRetry: () => fetchDraftedNews());
        return Padding(
          padding:
              const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
          child: RefreshIndicator(
            onRefresh: () async => fetchDraftedNews(),
            child: ListView.builder(
                controller: controller,
                physics: const AlwaysScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: state.GetUserDraftedNews.length,
                itemBuilder: (context, index) {
                  return UsernewsWidgets.buildNewsContainer(
                      context: context,
                      model: state.GetUserDraftedNews[index],
                      hasMore: state.hasMore,
                      hasMoreNewsFetchError: state.hasMoreFetchError,
                      index: index,
                      totalCurrentNews: state.GetUserDraftedNews.length,
                      fetchMoreNews: fetchMoreDraftedNews);
                }),
          ),
        );
      }
      if (state is GetUserDraftedNewsFetchFailure) {
        return ErrorContainerWidget(
            errorMsg: (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                : state.errorMessage,
            onRetry: fetchDraftedNews);
      }
      return contentShimmer;
    });
  }
}
