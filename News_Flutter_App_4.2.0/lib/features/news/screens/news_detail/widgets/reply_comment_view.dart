import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/news/models/comment_model.dart';

import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/news/screens/news_detail/widgets/del_and_report_reply_comm.dart';

import 'package:news/utils/ui_utils.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/news/cubits/news_comment/like_and_dislike_comm_cubit.dart';
import 'package:news/features/news/cubits/news_comment/set_comment_cubit.dart';
import 'package:news/features/news/cubits/comment_news_cubit.dart';
import 'package:news/features/news/repositories/news_comment/like_and_dislike_comment/like_and_dislike_comm_repository.dart';

class ReplyCommentView extends StatefulWidget {
  final int replyComIndex;
  final Function replyComFun;
  final String newsId;

  const ReplyCommentView(
      {super.key,
      required this.replyComIndex,
      required this.replyComFun,
      required this.newsId});

  @override
  ReplyCommentViewState createState() => ReplyCommentViewState();
}

class ReplyCommentViewState extends State<ReplyCommentView> {
  bool isReply = false, replyComEnabled = false, isSending = false;
  final TextEditingController _replyComC = TextEditingController();
  TextEditingController reportC = TextEditingController();

  // Common dark/light surface tones derived from the theme so the design
  // matches the Figma "News Comment Reply" screen in both modes.
  Color get _onColor => UiUtils.getColorScheme(context).primaryContainer;

  Widget _profilePic(String? url, double size) {
    return SizedBox(
        height: size,
        width: size,
        child: (url != null && url != "")
            ? CircleAvatar(backgroundImage: NetworkImage(url), radius: size / 2)
            : Icon(Icons.account_circle, size: size, color: _onColor));
  }

  // "Replies ( N )" header with a circular close button + divider line.
  Widget repliesHeaderView(CommentModel model) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child:
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          CustomTextLabel(
              text: 'repliesLbl',
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _onColor, fontSize: 16, fontWeight: FontWeight.w500)),
          CustomTextLabel(
              text: " ( ${model.replyComList!.length} )",
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: _onColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ])),
        InkWell(
            child: SvgPictureWidget(
                assetName: 'close_comment',
                height: 24,
                width: 24,
                assetColor: ColorFilter.mode(_onColor, BlendMode.srcIn)),
            onTap: () {
              setState(() => isReply = false);
              widget.replyComFun(false, widget.replyComIndex);
            })
      ]),
      Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Divider(height: 1, color: _onColor.withOpacity(0.1)))
    ]);
  }

  // Highlighted card showing the parent comment that is being replied to.
  Widget parentCommentCard(CommentModel modelCom) {
    DateTime replyTime = DateTime.parse(modelCom.date!);
    return Container(
        decoration: BoxDecoration(
            color: _onColor.withOpacity(0.1),
            border: Border.all(color: _onColor.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.all(8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom:
                              BorderSide(color: _onColor.withOpacity(0.1)))),
                  child: Row(children: [
                    _profilePic(modelCom.profile, 42),
                    const SizedBox(width: 12),
                    Expanded(
                        child: CustomTextLabel(
                            text: modelCom.name!,
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: _onColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)))
                  ])),
              const SizedBox(height: 16),
              CustomTextLabel(
                  text: modelCom.message!,
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _onColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: CustomTextLabel(
                      text: UiUtils.convertToAgo(context, replyTime, 1)!,
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: _onColor.withOpacity(0.7), fontSize: 12)))
            ]));
  }

  Widget _reactionButton(
      {required String assetName,
      required double size,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SvgPictureWidget(
                  assetName: assetName,
                  height: size,
                  width: size,
                  assetColor: ColorFilter.mode(_onColor, BlendMode.srcIn)),
              const SizedBox(width: 8),
              CustomTextLabel(
                  text: label,
                  textStyle: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: _onColor, fontSize: 12))
            ])));
  }

  Widget replyItem(CommentModel model, int index) {
    final reply = model.replyComList![index];
    DateTime time1 = DateTime.parse(reply.date!);
    return Container(
        padding: const EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0),
        decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: _onColor.withOpacity(0.1)))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                _profilePic(reply.profile, 32),
                const SizedBox(width: 6),
                Expanded(
                    child: CustomTextLabel(
                        text: reply.name!,
                        textStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: _onColor.withOpacity(0.5),
                                fontSize: 12))),
                CustomTextLabel(
                    text: UiUtils.convertToAgo(context, time1, 1)!,
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _onColor.withOpacity(0.5), fontSize: 12))
              ]),
              Padding(
                  padding: const EdgeInsetsDirectional.only(start: 38, top: 4),
                  child: CustomTextLabel(
                      text: reply.message!,
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: _onColor, fontSize: 14))),
              BlocBuilder<LikeAndDislikeCommCubit, LikeAndDislikeCommState>(
                  builder: (context, state) {
                return Padding(
                    padding:
                        const EdgeInsetsDirectional.only(start: 36, top: 4),
                    child: Row(children: [
                      _reactionButton(
                          assetName:
                              (reply.like == "1") ? 'like_filled' : 'like',
                          size: 20,
                          label:
                              "${reply.totalLikes ?? "0"} ${UiUtils.getTranslatedLabel(context, 'likeTxt')}",
                          onTap: () {
                            (context.read<AuthCubit>().getUserId() != "0")
                                ? context
                                    .read<LikeAndDislikeCommCubit>()
                                    .setLikeAndDislikeComm(
                                        langCode: context
                                            .read<AppLocalizationCubit>()
                                            .state
                                            .languageCode,
                                        commId: reply.id!,
                                        status: (reply.like == "1") ? "0" : "1",
                                        fromLike: true)
                                : UiUtils.loginRequired(context);
                          }),
                      const SizedBox(width: 8),
                      _reactionButton(
                          // The unfilled `dislike.svg` (17 viewBox) fills more of
                          // its canvas than `like.svg` (24 viewBox), so render it
                          // a bit smaller to visually match the like icon.
                          assetName: (reply.dislike == "1")
                              ? 'dislike_filled'
                              : 'dislike',
                          size: (reply.dislike == "1") ? 20 : 17,
                          label:
                              "${reply.totalDislikes ?? "0"} ${UiUtils.getTranslatedLabel(context, 'dislikeTxt')}",
                          onTap: () {
                            (context.read<AuthCubit>().getUserId() != "0")
                                ? context
                                    .read<LikeAndDislikeCommCubit>()
                                    .setLikeAndDislikeComm(
                                        langCode: context
                                            .read<AppLocalizationCubit>()
                                            .state
                                            .languageCode,
                                        commId: reply.id!,
                                        status:
                                            (reply.dislike == "1") ? "0" : "2",
                                        fromLike: false)
                                : UiUtils.loginRequired(context);
                          }),
                      const Spacer(),
                      if (context.read<AuthCubit>().getUserId() != "0")
                        InkWell(
                            child: SvgPictureWidget(
                                assetName:
                                    (context.read<AuthCubit>().getUserId() ==
                                            reply.userId!)
                                        ? 'delete_icon'
                                        : 'flag_icon',
                                height: 32,
                                width: 32),
                            onTap: () => delAndReportReplyComm(
                                model: model,
                                context: context,
                                reportC: reportC,
                                newsId: widget.newsId,
                                setState: setState,
                                replyIndex: index))
                    ]));
              })
            ]));
  }

  Widget replyComSendReplyView(CommentModel model) {
    return context.read<AuthCubit>().getUserId() != "0"
        ? BlocListener<SetCommentCubit, SetCommentState>(
            bloc: context.read<SetCommentCubit>(),
            listener: (context, state) {
              if (state is SetCommentFetchSuccess) {
                context
                    .read<CommentNewsCubit>()
                    .commentUpdateList(state.setComment, state.total);
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
                _replyComC.clear();
                isSending = false;
                replyComEnabled = false;
                setState(() {});
              }
              if (state is SetCommentFetchInProgress) {
                setState(() => isSending = true);
              }
            },
            child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 12.0),
                child: Row(children: [
                  Expanded(
                      child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              border:
                                  Border.all(color: _onColor.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: _replyComC,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: _onColor),
                            onChanged: (String val) {
                              setState(() => replyComEnabled =
                                  _replyComC.text.trim().isNotEmpty);
                            },
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                border: InputBorder.none,
                                hintText: UiUtils.getTranslatedLabel(
                                    context, 'publicReply'),
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: _onColor.withOpacity(0.4))),
                          ))),
                  const SizedBox(width: 10),
                  InkWell(
                      onTap: () async {
                        if (!replyComEnabled || isSending) return;
                        if (context.read<AuthCubit>().getUserId() != "0") {
                          context.read<SetCommentCubit>().setComment(
                              parentId: model.id!,
                              newsId: widget.newsId,
                              message: _replyComC.text,
                              langCode: context
                                  .read<AppLocalizationCubit>()
                                  .state
                                  .languageCode);
                        } else {
                          UiUtils.loginRequired(context);
                        }
                      },
                      child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              border:
                                  Border.all(color: _onColor.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.all(8),
                          child: (!isSending)
                              ? SvgPictureWidget(
                                  assetName: 'send_comment',
                                  height: 24,
                                  width: 24,
                                  assetColor: ColorFilter.mode(
                                      replyComEnabled
                                          ? _onColor
                                          : _onColor.withOpacity(0.4),
                                      BlendMode.srcIn))
                              : SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Center(
                                      child: SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: UiUtils.showCircularProgress(
                                              true,
                                              Theme.of(context)
                                                  .primaryColor))))))
                ])))
        : const SizedBox.shrink();
  }

  Widget replyAllComListView(CommentModel model) {
    return ListView.separated(
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        shrinkWrap: true,
        reverse: true,
        padding: const EdgeInsets.only(top: 8.0),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: model.replyComList!.length,
        itemBuilder: (context, index) => replyItem(model, index));
  }

  Widget replyCommentView() {
    return BlocBuilder<CommentNewsCubit, CommentNewsState>(
        builder: (context, state) {
      if (state is CommentNewsFetchSuccess && state.commentNews.isNotEmpty) {
        final model = state.commentNews[widget.replyComIndex];
        return BlocListener<LikeAndDislikeCommCubit, LikeAndDislikeCommState>(
          listener: (context, likeDislikeState) {
            if (likeDislikeState is LikeAndDislikeCommSuccess) {
              final defaultIndex = state.commentNews.indexWhere(
                  (element) => element.id == likeDislikeState.comment.id);
              if (defaultIndex != -1) {
                state.commentNews[defaultIndex].replyComList =
                    likeDislikeState.comment.replyComList;
                context
                    .read<CommentNewsCubit>()
                    .emitSuccessState(state.commentNews);
              }
            }
          },
          child: Padding(
              padding:
                  const EdgeInsetsDirectional.only(top: 10.0, bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  repliesHeaderView(model),
                  const SizedBox(height: 12),
                  parentCommentCard(model),
                  replyAllComListView(model),
                  replyComSendReplyView(model),
                ],
              )),
        );
      }
      if (state is CommentNewsFetchFailure) {
        return Center(
            child: CustomTextLabel(
                text: state.errorMessage, textAlign: TextAlign.center));
      }
      //state is CommentNewsFetchInProgress || state is CommentNewsInitial
      return const Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
          child: SizedBox.shrink());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) =>
            LikeAndDislikeCommCubit(LikeAndDislikeCommRepository()),
        child: replyCommentView());
  }
}
