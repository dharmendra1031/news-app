import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/video_play_container.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/bookmarks/repositories/bookmark_repository.dart';
import 'package:news/features/news/repositories/like_and_dislike_news/like_and_dislike_news_repository.dart';
import 'package:news/core/constants/strings.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:news/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:html/parser.dart';

class VideoItem extends StatefulWidget {
  final NewsModel model;

  VideoItem({super.key, required this.model});

  @override
  VideoItemState createState() => VideoItemState();
}

class VideoItemState extends State<VideoItem> {
  String formattedDescription = "";
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
  }

  void dispose() async {
    super.dispose();
  }

  void checkAndSetDescription({required String descr}) {
    formattedDescription = "";

    // Parse HTML and extract plain text
    formattedDescription = parse(descr).body?.text ?? '';
  }

  Widget videoData(NewsModel video) {
    checkAndSetDescription(descr: video.desc ?? '');

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isPlaying ? _videoPlayer(video) : _thumbnail(video),
                ),

                // Close button
                if (_isPlaying)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _isPlaying = false),
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 24, color: Colors.white),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _isPlaying = true),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.black45,
                      child:
                          Icon(Icons.play_arrow, size: 40, color: Colors.white),
                    ),
                  ),

                // Title + description
                Positioned(
                  bottom: 25,
                  left: 10,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextLabel(
                        text: video.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: secondaryColor,
                                fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      CustomTextLabel(
                        text: formattedDescription.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(color: secondaryColor),
                      ),
                    ],
                  ),
                ),

                // Actions (like / bookmark / share)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _actions(video),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoPlayer(NewsModel video) {
    return Container(
      key: const ValueKey('player'),
      width: double.infinity,
      color: Colors.black,
      child: VideoPlayContainer(
        contentType: video.contentType!,
        contentValue: video.contentValue!,
        autoPlay: true,
      ),
    );
  }

  Widget _thumbnail(NewsModel video) {
    return SizedBox.expand(
      child: ShaderMask(
        key: const ValueKey('thumbnail'),
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, darkSecondaryColor],
          ).createShader(bounds);
        },
        blendMode: BlendMode.darken,
        child: CustomNetworkImage(
            networkImageUrl: (video.contentType ==
                        videoTypeToString(VideoType.video_youtube) &&
                    video.contentValue!.isNotEmpty)
                ? 'https://img.youtube.com/vi/${YoutubePlayer.convertUrlToId(video.contentValue!)!}/0.jpg'
                : video.image!),
      ),
    );
  }

  Widget _actions(NewsModel video) {
    return Column(
      children: [
        if (video.sourceType == NEWS) ...[
          likeButton(),
          const SizedBox(height: 15),
          BlocProvider(
            create: (_) => UpdateBookmarkStatusCubit(BookmarkRepository()),
            child: BlocBuilder<BookmarkCubit, BookmarkState>(
              bloc: context.read<BookmarkCubit>(),
              builder: (context, bookmarkState) {
                final isBookmark =
                    context.read<BookmarkCubit>().isNewsBookmark(video.id!);

                return BlocConsumer<UpdateBookmarkStatusCubit,
                    UpdateBookmarkStatusState>(
                  bloc: context.read<UpdateBookmarkStatusCubit>(),
                  listener: (context, state) {
                    if (state is UpdateBookmarkStatusSuccess) {
                      state.wasBookmarkNewsProcess
                          ? context
                              .read<BookmarkCubit>()
                              .addBookmarkNews(state.news)
                          : context
                              .read<BookmarkCubit>()
                              .removeBookmarkNews(state.news);
                      setState(() {});
                    }
                  },
                  builder: (context, state) {
                    return InkWell(
                      onTap: () {
                        if (context.read<AuthCubit>().getUserId() == "0") {
                          UiUtils.loginRequired(context);
                          return;
                        }

                        if (state is UpdateBookmarkStatusInProgress) return;

                        context
                            .read<UpdateBookmarkStatusCubit>()
                            .setBookmarkNews(
                              news: video,
                              status: isBookmark ? "0" : "1",
                            );
                      },
                      child: state is UpdateBookmarkStatusInProgress
                          ? SizedBox(
                              height: 15,
                              width: 15,
                              child: UiUtils.showCircularProgress(
                                true,
                                Theme.of(context).primaryColor,
                              ),
                            )
                          : Icon(
                              isBookmark
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_outlined,
                              color: secondaryColor,
                            ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 15),
        ],

        // Share button
        InkWell(
          onTap: () async {
            (await InternetConnectivity.isNetworkAvailable())
                ? UiUtils.shareNews(
                    context: context,
                    slug: video.slug ?? "",
                    title: video.title!,
                    isVideo: true,
                    isReels: false,
                    videoId: video.id!,
                    isBreakingNews: false,
                    isNews: false,
                  )
                : showSnackBar(
                    UiUtils.getTranslatedLabel(context, 'internetmsg'),
                    context,
                  );
          },
          splashColor: Colors.transparent,
          child: const Icon(Icons.share_rounded, color: secondaryColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return (widget.model.contentValue!.isNotEmpty)
        ? videoData(widget.model)
        : ErrorContainerWidget(
            errorMsg: ErrorMessageKeys.noVideoDataMessage, onRetry: () {});
  }

  Widget likeButton() {
    bool isLike = context
        .read<LikeAndDisLikeCubit>()
        .isNewsLikeAndDisLike(widget.model.newsId!);

    return BlocProvider(
        create: (context) =>
            UpdateLikeAndDisLikeStatusCubit(LikeAndDisLikeRepository()),
        child: BlocConsumer<LikeAndDisLikeCubit, LikeAndDisLikeState>(
            bloc: context.read<LikeAndDisLikeCubit>(),
            listener: ((context, state) {
              if (state is LikeAndDisLikeFetchSuccess) {
                isLike = context
                    .read<LikeAndDisLikeCubit>()
                    .isNewsLikeAndDisLike(widget.model.newsId!);
              }
            }),
            builder: (context, likeAndDislikeState) {
              return BlocConsumer<UpdateLikeAndDisLikeStatusCubit,
                      UpdateLikeAndDisLikeStatusState>(
                  bloc: context.read<UpdateLikeAndDisLikeStatusCubit>(),
                  listener: ((context, state) {
                    if (state is UpdateLikeAndDisLikeStatusSuccess) {
                      context.read<LikeAndDisLikeCubit>().getLike(
                          langCode: context
                              .read<AppLocalizationCubit>()
                              .state
                              .languageCode);
                      isLike = context
                          .read<LikeAndDisLikeCubit>()
                          .isNewsLikeAndDisLike(widget.model.newsId!);
                    }
                  }),
                  builder: (context, state) {
                    return InkWell(
                        splashColor: Colors.transparent,
                        onTap: () {
                          if (context.read<AuthCubit>().getUserId() != "0") {
                            if (state is UpdateLikeAndDisLikeStatusInProgress) {
                              return;
                            }
                            context
                                .read<UpdateLikeAndDisLikeStatusCubit>()
                                .setLikeAndDisLikeNews(
                                  news: widget.model,
                                  status: (isLike) ? "0" : "1",
                                );
                          } else {
                            UiUtils.loginRequired(context);
                          }
                        },
                        child: Container(
                            child: (state
                                    is UpdateLikeAndDisLikeStatusInProgress)
                                ? SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: UiUtils.showCircularProgress(
                                        true, Theme.of(context).primaryColor))
                                : ((isLike)
                                    ? const Icon(Icons.thumb_up_alt,
                                        size: 25, color: secondaryColor)
                                    : const Icon(Icons.thumb_up_off_alt,
                                        size: 25, color: secondaryColor))));
                  });
            }));
  }
}
