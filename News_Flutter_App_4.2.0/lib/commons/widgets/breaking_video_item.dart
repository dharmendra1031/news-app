import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/news/models/breaking_news_model.dart';

class BreakVideoItem extends StatefulWidget {
  final BreakingNewsModel model;

  const BreakVideoItem({super.key, required this.model});

  @override
  BreakVideoItemState createState() => BreakVideoItemState();
}

class BreakVideoItemState extends State<BreakVideoItem> {
  Widget videoData(BreakingNewsModel video) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(Routes.newsVideo,
                    arguments: {"from": 3, "breakModel": video});
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  (video.contentType ==
                          videoTypeToString(VideoType.video_youtube))
                      ? CustomNetworkImage(
                          networkImageUrl:
                              'https://img.youtube.com/vi/${YoutubePlayer.convertUrlToId(video.contentValue!)!}/0.jpg',
                          fit: BoxFit.cover,
                          width: double.maxFinite,
                          height: 220,
                          isVideo: true)
                      : CustomNetworkImage(
                          networkImageUrl: video.image!,
                          fit: BoxFit.cover,
                          width: double.maxFinite,
                          height: 220,
                          isVideo: true),
                  const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.black45,
                      child: Icon(Icons.play_arrow,
                          size: 40, color: backgroundColor))
                ],
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(left: 5, right: 5),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomTextLabel(
                      text: video.title!,
                      textStyle: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return videoData(widget.model);
  }
}
