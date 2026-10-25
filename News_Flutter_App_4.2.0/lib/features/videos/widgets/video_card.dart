import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/video_play_container.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:news/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/live_streaming/models/live_streaming_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/features/news/screens/news_detail/widgets/desc_view.dart';
import 'package:news/features/news/screens/news_detail/widgets/like_action.dart';
import 'package:news/features/news/screens/news_detail/widgets/tag_view.dart';
import 'package:news/features/videos/widgets/video_list_card.dart';
import 'package:news/utils/ui_utils.dart';

/// FIGMA(3371-4337): the video details body — player, tag pills, title and the
/// "• date  • views" row with the like tab. Blocks are 12px apart; the caller
/// owns the 16px screen padding. Bookmark and share live in the app bar.
class VideoCard extends StatefulWidget {
  final NewsModel? model;
  final BreakingNewsModel? brModel;
  final LiveStreamingModel? liveModel;
  VideoCard({super.key, this.model, this.liveModel, this.brModel});

  @override
  State<StatefulWidget> createState() => VideoCardState();
}

class VideoCardState extends State<VideoCard> {
  late NewsModel? model;
  late BreakingNewsModel? brModel;
  late LiveStreamingModel? liveModel;
  bool isLiveVideo = false, isBreakingVideo = false;
  List<String> tagList = [];
  List<String> tagId = [];
  String formattedDate = "",
      contentType = "",
      contentValue = "",
      titleTxt = "",
      descTxt = "";
  final GlobalKey<VideoPlayContainerState> _videoKey =
      GlobalKey<VideoPlayContainerState>();

  @override
  void initState() {
    super.initState();
    model = widget.model;
    brModel = widget.brModel;
    liveModel = widget.liveModel;
    isLiveVideo = (liveModel != null);
    isBreakingVideo = (brModel != null);
    setFormattedDate();
    setTitle();
    setDescription();
    setContentValueAndContentType();
    setTags();
  }

  void setTitle() {
    titleTxt = (isLiveVideo)
        ? liveModel?.title ?? ""
        : (isBreakingVideo)
            ? brModel?.title ?? ""
            : model?.title ?? "";
  }

  /// The API sends the description as CMS HTML and some videos have none (live
  /// streams never do), or only `<p>&nbsp;</p>`. It is cleaned here so the
  /// block is left out when nothing readable is left.
  void setDescription() {
    final String raw = (isBreakingVideo ? brModel?.desc : model?.desc) ?? "";
    descTxt = cleanNewsHtml(raw);
  }

  void setTags() {
    if (model != null &&
        model?.tagName != null &&
        (model!.sourceType != null && model!.sourceType != BREAKING_NEWS)) {
      if (model?.tagId != null && model!.tagId!.isNotEmpty) {
        tagId = model!.tagId!.split(",");
      }

      if (model!.tagName!.isNotEmpty) {
        tagList = model!.tagName!.split(',');
      }
    }
  }

  void setFormattedDate() {
    String dateVal = (isLiveVideo)
        ? liveModel!.updatedDate ?? ""
        : (model?.publishDate ?? model?.date ?? "");
    if (dateVal.isNotEmpty) {
      try {
        DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(dateVal);
        formattedDate = DateFormat("dd MMM yyyy").format(parsedDate);
      } catch (_) {
        formattedDate = "";
      }
    }
  }

  void setContentValueAndContentType() {
    contentType = (isLiveVideo)
        ? liveModel?.type ?? ""
        : ((model != null)
            ? model?.contentType ?? ""
            : brModel!.contentType ?? "");
    contentValue = (isLiveVideo)
        ? liveModel?.url ?? ""
        : (model != null)
            ? model?.contentValue ?? ""
            : brModel!.contentValue ?? "";
  }

  void openLandscapeVideo() {
    if (contentValue.isEmpty) return;

    final startTime =
        _videoKey.currentState?.getCurrentPosition() ?? Duration.zero;
    _videoKey.currentState?.pausePlayback();

    Navigator.of(context).pushNamed(
      Routes.videoLandscape,
      arguments: {
        "contentType": contentType,
        "contentValue": contentValue,
        "startTime": startTime,
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  /// Indexes of the tags that have a name. The tag ids are matched by position,
  /// so blank entries are skipped when drawing instead of being removed.
  List<int> get _visibleTagIndexes => [
        for (int i = 0; i < tagList.length; i++)
          if (tagList[i].trim().isNotEmpty) i
      ];

  /// 1200 -> "1.2K", 1_000_000 -> "1M". Matches the Figma "1.2K View" chip.
  String _compactCount(int n) {
    if (n >= 1000000) {
      return "${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M";
    }
    if (n >= 1000) {
      return "${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K";
    }
    return "$n";
  }

  /// Null when the video has no views yet, so the chip is left out instead of
  /// reading "0 Views".
  String? get _viewsText {
    final String? raw = isLiveVideo
        ? liveModel?.totalViews
        : (isBreakingVideo ? brModel?.totalViews : model?.totalViews);
    final int? views = parseVideoViews(raw);
    if (views == null) return null;
    return "${_compactCount(views)} ${UiUtils.getTranslatedLabel(context, 'viewsLbl')}";
  }

  /// FIGMA(3371-4337): outlined stadium pills, 8px apart. Only built when the
  /// video has tags; without them the title takes this row's place.
  Widget _tagsRow(List<int> indexes) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int n = 0; n < indexes.length; n++)
            Padding(
              padding: EdgeInsetsDirectional.only(start: n == 0 ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(1000),
                onTap: () {
                  final int index = indexes[n];
                  if (index >= tagId.length || tagId[index].isEmpty) return;
                  Navigator.of(context).pushNamed(Routes.tagScreen,
                      arguments: {
                        "tagId": tagId[index],
                        "tagName": tagList[index]
                      });
                },
                child: tagsContainer(
                    context: context, tagList: tagList, index: indexes[n]),
              ),
            ),
        ],
      ),
    );
  }

  /// "• label" chip of the info row: a 5px dot, 6px gap, 12px Text/Primary.
  Widget _infoChip(String text) {
    final Color onColor = UiUtils.getColorScheme(context).primaryContainer;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: onColor, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Flexible(
        child: CustomTextLabel(
            text: text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: onColor,
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0)),
      ),
    ]);
  }

  /// FIGMA(3371-4337): "5 Like" tab — 22px like icon, 8px gap, 14/20 label, 8px
  /// padding all round. Same like handling as the news details screen.
  Widget _likeTab(NewsModel model) {
    final Color onColor = UiUtils.getColorScheme(context).primaryContainer;
    return BlocBuilder<LikeAndDisLikeCubit, LikeAndDisLikeState>(
      bloc: context.read<LikeAndDisLikeCubit>(),
      builder: (context, likeState) {
        return BlocConsumer<UpdateLikeAndDisLikeStatusCubit,
            UpdateLikeAndDisLikeStatusState>(
          bloc: context.read<UpdateLikeAndDisLikeStatusCubit>(),
          listener: (context, state) =>
              onLikeStatusChanged(context, state, model),
          builder: (context, state) {
            final bool isLike = isNewsLiked(context, model);
            final int likes = int.tryParse(model.totalLikes ?? '') ?? 0;
            final Color tint = isLike ? Theme.of(context).primaryColor : onColor;
            return InkWell(
              onTap: () => onLikeTap(context, model),
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SvgPictureWidget(
                      assetName: isLike ? 'nd_like_filled' : 'nd_like',
                      height: 22,
                      width: 22,
                      assetColor: ColorFilter.mode(tint, BlendMode.srcIn)),
                  // With no likes only the icon shows, no count and no label.
                  if (likes > 0) ...[
                    const SizedBox(width: 8),
                    CustomTextLabel(
                        text:
                            "$likes ${UiUtils.getTranslatedLabel(context, 'likeLbl')}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: onColor,
                            fontSize: 14,
                            height: 20 / 14,
                            letterSpacing: 0)),
                  ],
                ]),
              ),
            );
          },
        );
      },
    );
  }

  /// FIGMA(3371-4337): the 1px Border/Default strip above and below the
  /// "• date  • views" chips (6px apart) and the like tab.
  Widget _infoContainer() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderTone = isDark ? darkBorderDefaultColor : borderDefaultColor;
    final String? viewsText = _viewsText;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          border: Border.symmetric(
              horizontal: BorderSide(color: borderTone, width: 1))),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            if (formattedDate.isNotEmpty) ...[
              Flexible(child: _infoChip(formattedDate)),
              if (viewsText != null) const SizedBox(width: 6),
            ],
            if (viewsText != null) Flexible(child: _infoChip(viewsText)),
          ]),
        ),
        const SizedBox(width: 12),
        if (model != null) _likeTab(model!),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    final List<int> tagIndexes = (model != null &&
            model!.sourceType != BREAKING_NEWS)
        ? _visibleTagIndexes
        : const <int>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayContainer(
                  key: _videoKey,
                  contentType: contentType,
                  contentValue: contentValue,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: openLandscapeVideo,
                    child: Container(
                      height: 32,
                      width: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (tagIndexes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _tagsRow(tagIndexes),
        ],
        const SizedBox(height: 12),
        CustomTextLabel(
            text: titleTxt,
            textStyle: TextStyle(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w500,
                color: UiUtils.getColorScheme(context).onPrimary)),
        const SizedBox(height: 12),
        _infoContainer(),
        // Same body style as the news details description (14/20, Text/Secondary).
        if (descTxt.isNotEmpty)
          descView(desc: descTxt, fontValue: 14, context: context),
      ],
    );
  }
}
