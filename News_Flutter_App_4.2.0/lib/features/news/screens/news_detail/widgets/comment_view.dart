import 'package:news/features/news/repositories/news_comment/like_and_dislike_comment/like_and_dislike_comm_repository.dart';
import 'package:news/features/news/cubits/news_comment/like_and_dislike_comm_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/models/comment_model.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/news/cubits/comment_news_cubit.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/features/news/screens/news_detail/widgets/del_and_report_com.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class CommentView extends StatefulWidget {
  final String newsId;
  final Function updateComFun;
  final Function updateIsReplyFun;

  const CommentView(
      {super.key,
      required this.newsId,
      required this.updateComFun,
      required this.updateIsReplyFun});

  @override
  CommentViewState createState() => CommentViewState();
}

class CommentViewState extends State<CommentView> {
  TextEditingController reportC = TextEditingController();
  bool isReply = false;
  int? replyComIndex;

  Widget commentsLengthView(int length) {
    return Row(children: [
      if (length > 0)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              CustomTextLabel(
                  text: "$length ",
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UiUtils.getColorScheme(context)
                          .primaryContainer
                          .withOpacity(0.6),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600)),
              CustomTextLabel(
                  text: 'comsLbl',
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UiUtils.getColorScheme(context)
                          .primaryContainer
                          .withOpacity(0.6),
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600)),
            ])),
      const Spacer(),
      Align(
          alignment: Alignment.topRight,
          child: InkWell(
            child: SvgPictureWidget(
                assetName: 'close_comment',
                height: 24,
                width: 24,
                assetColor: ColorFilter.mode(
                    UiUtils.getColorScheme(context).primaryContainer,
                    BlendMode.srcIn)),
            onTap: () {
              widget.updateComFun(false);
            },
          ))
    ]);
  }

  _buildCommContainer(
      {required CommentModel model,
      required int index,
      required int totalCurrentComm,
      required bool hasMoreCommFetchError,
      required bool hasMore}) {
    model = model;
    if (index == totalCurrentComm - 1 && index <= 0) {
      //check if hasMore
      if (hasMore) {
        if (hasMoreCommFetchError) {
          return const SizedBox.shrink();
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
    return Builder(builder: (context) {
      return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            (model.profile != null && model.profile != "")
                ? UiUtils.setFixedSizeboxForProfilePicture(
                    childWidget: CircleAvatar(
                        backgroundImage: (model.profile != null)
                            ? NetworkImage(model.profile!)
                            : NetworkImage(
                                const Icon(Icons.account_circle, size: 35)
                                    as String),
                        radius: 32))
                : UiUtils.setFixedSizeboxForProfilePicture(
                    childWidget: const Icon(Icons.account_circle, size: 35)),
            Expanded(
                child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 15.0),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            CustomTextLabel(
                                text: model.name!,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: UiUtils.getColorScheme(context)
                                            .primaryContainer
                                            .withOpacity(0.7),
                                        fontSize: 13)),
                            Spacer(),
                            Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 10.0),
                                child: CustomTextLabel(
                                  text: UiUtils.convertToAgo(
                                      context, DateTime.parse(model.date!), 1)!,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer
                                              .withOpacity(0.7),
                                          fontSize: 10),
                                ))
                          ]),
                          Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: CustomTextLabel(
                                  text: model.message!,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer,
                                          fontWeight: FontWeight.w500))),
                          Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(top: 10),
                              child: InkWell(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SvgPictureWidget(
                                      assetName: 'reply',
                                      height: 8,
                                      width: 10,
                                      assetColor: ColorFilter.mode(
                                          UiUtils.getColorScheme(context)
                                              .primaryContainer
                                              .withOpacity(0.7),
                                          BlendMode.srcIn),
                                    ),
                                    SizedBox(width: 3),
                                    CustomTextLabel(
                                        text: 'replyLbl',
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: UiUtils.getColorScheme(
                                                        context)
                                                    .primaryContainer
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w400)),
                                    // FIGMA(1500-4501): reply count is shown
                                    // inline as "Reply (N)" right under the
                                    // comment - replaces the separate replies
                                    // row that used to sit below the reactions.
                                    if (model.replyComList!.isNotEmpty)
                                      CustomTextLabel(
                                          text:
                                              " (${model.replyComList!.length})",
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: UiUtils.getColorScheme(
                                                          context)
                                                      .primaryContainer
                                                      .withOpacity(0.7),
                                                  fontWeight: FontWeight.w400)),
                                  ],
                                ),
                                onTap: () {
                                  widget.updateIsReplyFun(true, index);
                                  setState(() {
                                    isReply = true;
                                    replyComIndex = index;
                                  });
                                },
                              )),
                          BlocBuilder<LikeAndDislikeCommCubit,
                                  LikeAndDislikeCommState>(
                              builder: (context, state) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 15.0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                      child: SvgPictureWidget(
                                          assetName: (model.like == "1")
                                              ? 'like_filled'
                                              : 'like',
                                          height: 24,
                                          width: 24,
                                          assetColor: ColorFilter.mode(
                                              UiUtils.getColorScheme(context)
                                                  .primaryContainer,
                                              BlendMode.srcIn)),
                                      onTap: () {
                                        if (context
                                                .read<AuthCubit>()
                                                .getUserId() !=
                                            "0") {
                                          context
                                              .read<LikeAndDislikeCommCubit>()
                                              .setLikeAndDislikeComm(
                                                  langCode: context
                                                      .read<
                                                          AppLocalizationCubit>()
                                                      .state
                                                      .languageCode,
                                                  commId: model.id!,
                                                  status: (model.like == "1")
                                                      ? "0"
                                                      : "1",
                                                  fromLike: true);
                                        } else {
                                          UiUtils.loginRequired(context);
                                        }
                                      }),
                                  // FIGMA(1500-4501): reaction count is shown
                                  // with its label ("5 like" / "5 Dislike"),
                                  // matching the design and the reply view.
                                  Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 4.0),
                                      child: CustomTextLabel(
                                          text:
                                              "${model.totalLikes ?? "0"} ${UiUtils.getTranslatedLabel(context, 'likeTxt')}",
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                  color: UiUtils.getColorScheme(
                                                          context)
                                                      .primaryContainer))),
                                  Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(start: 35),
                                            child: InkWell(
                                              child: SvgPictureWidget(
                                                  assetName:
                                                      (model.dislike == "1")
                                                          ? 'dislike_filled'
                                                          : 'dislike',
                                                  height: 22,
                                                  width: 22,
                                                  assetColor: ColorFilter.mode(
                                                      UiUtils.getColorScheme(
                                                              context)
                                                          .primaryContainer,
                                                      BlendMode.srcIn)),
                                              onTap: () {
                                                if (context
                                                        .read<AuthCubit>()
                                                        .getUserId() !=
                                                    "0") {
                                                  context
                                                      .read<
                                                          LikeAndDislikeCommCubit>()
                                                      .setLikeAndDislikeComm(
                                                          langCode: context
                                                              .read<
                                                                  AppLocalizationCubit>()
                                                              .state
                                                              .languageCode,
                                                          commId: model.id!,
                                                          status:
                                                              (model.dislike ==
                                                                      "1")
                                                                  ? "0"
                                                                  : "2",
                                                          fromLike: false);
                                                } else {
                                                  UiUtils.loginRequired(
                                                      context);
                                                }
                                              },
                                            )),
                                        Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(start: 4.0),
                                            child: CustomTextLabel(
                                                text:
                                                    "${model.totalDislikes ?? "0"} ${UiUtils.getTranslatedLabel(context, 'dislikeTxt')}",
                                                textStyle: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        color: UiUtils
                                                                .getColorScheme(
                                                                    context)
                                                            .primaryContainer)))
                                      ]),
                                  const Spacer(),
                                  if (context.read<AuthCubit>().getUserId() !=
                                      "0")
                                    InkWell(
                                        child: SvgPictureWidget(
                                          assetName: (context
                                                      .read<AuthCubit>()
                                                      .getUserId() ==
                                                  model.userId!)
                                              ? 'delete_icon'
                                              : 'flag_icon',
                                          height: 32,
                                          width: 32,
                                       
                                        ),
                                        onTap: () => delAndReportCom(
                                            index: index,
                                            newsId: widget.newsId,
                                            context: context,
                                            model: model,
                                            reportC: reportC,
                                            setState: setState))
                                ],
                              ),
                            );
                          }),
                        ]))),
          ]);
    });
  }

  Widget allComListView(CommentNewsFetchSuccess state) {
    return BlocListener<LikeAndDislikeCommCubit, LikeAndDislikeCommState>(
      listener: (context, likeDislikeState) {
        if (likeDislikeState is LikeAndDislikeCommSuccess) {
          final defaultIndex = state.commentNews.indexWhere(
              (element) => element.id == likeDislikeState.comment.id);
          if (defaultIndex != -1) {
            state.commentNews[defaultIndex] = likeDislikeState.comment;
            context
                .read<CommentNewsCubit>()
                .emitSuccessState(state.commentNews);
          }
        }
      },
      child: ListView.separated(
          separatorBuilder: (BuildContext context, int index) => Divider(
              color: UiUtils.getColorScheme(context)
                  .primaryContainer
                  .withOpacity(0.5)),
          shrinkWrap: true,
          primary: false,
          padding: const EdgeInsets.only(top: 20.0),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.commentNews.length,
          itemBuilder: (context, index) {
            return _buildCommContainer(
              model: state.commentNews[index],
              hasMore: state.hasMore,
              hasMoreCommFetchError: (state).hasMoreFetchError,
              index: index,
              totalCurrentComm: (state.commentNews[index].replyComList!.length +
                  state.commentNews.length),
            );
          }),
    );
  }

  Widget commentView() {
    return BlocBuilder<CommentNewsCubit, CommentNewsState>(
        builder: (context, state) {
      if (state is CommentNewsFetchInProgress || state is CommentNewsInitial) {
        return Center(
            child: UiUtils.showCircularProgress(
                true, UiUtils.getColorScheme(context).primaryContainer));
      }
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 10.0, bottom: 10.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (state is CommentNewsFetchSuccess)
            commentsLengthView((state).commentNews.length),
          // The comment input was moved out of the scrollable list into a
          // bottom-docked bar (CommentInputBar) in NewsSubDetails, matching the
          // Figma "chat type bar" that sits at the bottom of the screen.
          if (state is! CommentNewsFetchSuccess)
            Row(children: [
              const Spacer(),
              Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                      child: SvgPictureWidget(
                          assetName: 'close_comment',
                          height: 24,
                          width: 24,
                          assetColor: ColorFilter.mode(
                              UiUtils.getColorScheme(context).primaryContainer,
                              BlendMode.srcIn)),
                      onTap: () => widget.updateComFun(false)))
            ]),
          if (state is CommentNewsFetchFailure)
            SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: Center(
                    child: CustomTextLabel(
                        text: (state.errorMessage
                                .contains(ErrorMessageKeys.noInternet))
                            ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                            : (state.errorMessage == "No Data Found")
                                ? UiUtils.getTranslatedLabel(
                                    context, 'noComments')
                                : state.errorMessage,
                        textAlign: TextAlign.center))),
          if (state is CommentNewsFetchSuccess) allComListView(state)
        ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) =>
            LikeAndDislikeCommCubit(LikeAndDislikeCommRepository()),
        child: commentView());
  }
}
