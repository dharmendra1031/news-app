import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/author/cubits/author_news_cubit.dart';
import 'package:news/features/author/models/author_model.dart';
import 'package:news/commons/enums.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart';

class AuthorDetailsScreen extends StatefulWidget {
  final String authorId;
  const AuthorDetailsScreen({super.key, required this.authorId});

  @override
  State<AuthorDetailsScreen> createState() => _AuthorDetailsScreenState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => AuthorDetailsScreen(authorId: arguments['authorId']));
  }
}

class _AuthorDetailsScreenState extends State<AuthorDetailsScreen> {
  AuthorLayoutType layout = AuthorLayoutType.list;

  /// FIGMA (list 1625-7240 / grid 1625-7081): every surface on this screen is
  /// an 8px-radius card outlined with the secondary colour at 10% opacity —
  /// no shadow anywhere.
  static const double _cardRadius = 8;

  /// Screen gutter and the gap between cards, both 16 in the design.
  static const double _gutter = 16;

  /// Fixed card metrics from the design.
  static const double _listCardHeight = 104;
  static const double _listImageWidth = 94;
  static const double _gridImageHeight = 103;
  static const double _gridCardHeight = 229;

  @override
  void initState() {
    getNewsByAuthor();
    super.initState();
  }

  void getNewsByAuthor() {
    context.read<AuthorNewsCubit>().getAuthorNews(authorId: widget.authorId);
  }

  /// The design's `secondry-*` tokens are the secondary colour at an opacity —
  /// [ColorScheme.primaryContainer] is that colour in both themes (#1B2D51 in
  /// light, white in dark), so every tint on this screen derives from it.
  Color _secondary([double opacity = 1]) =>
      UiUtils.getColorScheme(context).primaryContainer.withOpacity(opacity);

  BoxDecoration get _cardDecoration => BoxDecoration(
      color: UiUtils.getColorScheme(context).surface,
      borderRadius: BorderRadius.circular(_cardRadius),
      border: Border.all(color: _secondary(0.1)));

  /// Card title — SemiBold 16 in the list, Medium 14 in the grid.
  TextStyle _titleStyle({required bool isList}) => TextStyle(
      fontSize: isList ? 16 : 14,
      fontWeight: isList ? FontWeight.w600 : FontWeight.w500,
      height: isList ? 1.25 : 1.2,
      letterSpacing: 0.1,
      color: _secondary());

  TextStyle get _descriptionStyle => TextStyle(
      fontSize: 12, height: 1.4, letterSpacing: 0.1, color: _secondary(0.7));

  /// Date and the view/comment counters.
  TextStyle get _metaStyle => TextStyle(
      fontSize: 10, height: 1.2, letterSpacing: 0.1, color: _secondary(0.5));

  Widget get _cardDivider => Container(height: 1, color: _secondary(0.1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIGMA header (1459:12958): 54px bar carrying the back arrow, the title
      // and the layout toggle, with the drop shadow every other screen has.
      appBar: CustomAppBar(
          height: 54,
          isBackBtn: true,
          isConvertText: true,
          label: 'authorLbl',
          actionWidget: [layoutToggleButton()]),
      body: BlocBuilder<AuthorNewsCubit, AuthorNewsState>(
        builder: (context, state) {
          if (state is AuthorNewsFetchSuccess) {
            return Column(
              children: [
                authorHeader(state: state),
                const SizedBox(height: _gutter),
                Expanded(
                    child: layout == AuthorLayoutType.list
                        ? authorNewsListView(state: state)
                        : authorNewsGridView(state: state)),
              ],
            );
          } else if (state is AuthorNewsFetchFailed) {
            return ErrorContainerWidget(
                errorMsg: state.errorMessage, onRetry: getNewsByAuthor);
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  /// FIGMA: 30x30 outlined square (secondary at 40%, 8px radius) holding a
  /// 20px icon that flips between the grid and list glyphs.
  Widget layoutToggleButton() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: _gutter),
      child: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              layout = layout == AuthorLayoutType.list
                  ? AuthorLayoutType.grid
                  : AuthorLayoutType.list;
            });
          },
          child: Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border.all(color: _secondary(0.4)),
                borderRadius: BorderRadius.circular(_cardRadius)),
            child: Icon(
                layout == AuthorLayoutType.list
                    ? Icons.grid_view_outlined
                    : Icons.view_list_outlined,
                size: 20,
                color: _secondary()),
          ),
        ),
      ),
    );
  }

  /// ---------------- HEADER ----------------
  /// FIGMA "Agent Info": 107x102 avatar, name + bio beside it, then the
  /// "Follow Me:" row of 24px social chips.
  Widget authorHeader({required AuthorNewsFetchSuccess state}) {
    final Author? authorDetails = _authorDetailsOf(state.authorData);
    final String bio = authorDetails?.bio ?? "";

    return Container(
      margin: const EdgeInsets.fromLTRB(_gutter, _gutter, _gutter, 0),
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CustomNetworkImage(
                      networkImageUrl: state.authorData.profile ?? "",
                      width: 107,
                      height: 102,
                      fit: BoxFit.cover)),
              const SizedBox(width: 8),
              Expanded(
                // Name and bio start at the top of the avatar. The Figma frame
                // centres them, but that only reads as "top" because the mock
                // bio fills three lines — most authors come back with an empty
                // bio, which would leave the name floating mid-avatar.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextLabel(
                        text: state.authorData.name ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textStyle: _titleStyle(isList: true)),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      CustomTextLabel(
                          text: bio,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          textStyle: TextStyle(
                              fontSize: 12,
                              height: 17 / 12,
                              letterSpacing: 0.1,
                              color: _secondary(0.7))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (authorDetails != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                CustomTextLabel(
                    text: 'followLbl',
                    textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        letterSpacing: 0.1,
                        color: _secondary())),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(spacing: 8, children: [
                    showSocialMediaLinks(
                        socialMediaLink: authorDetails.telegramLink ?? "",
                        socialMediaIconName: "telegram"),
                    showSocialMediaLinks(
                        socialMediaLink: authorDetails.facebookLink ?? "",
                        socialMediaIconName: "facebook"),
                    showSocialMediaLinks(
                        socialMediaLink: authorDetails.whatsappLink ?? "",
                        socialMediaIconName: "whatsapp"),
                    showSocialMediaLinks(
                        socialMediaLink: authorDetails.linkedinLink ?? "",
                        socialMediaIconName: "linkedin"),
                  ]),
                )
              ],
            ),
          ]
        ],
      ),
    );
  }

  /// The cubit hands back whichever user model the response shape matched, so
  /// read the author record from either of them.
  Author? _authorDetailsOf(dynamic authorData) => (authorData is UserAuthorModel)
      ? authorData.authorData
      : authorData?.authorDetails;

  Widget showSocialMediaLinks(
      {required String socialMediaLink, required String socialMediaIconName}) {
    return GestureDetector(
      onTap: () async {
        if (socialMediaLink.isEmpty) return;
        if (await canLaunchUrl(Uri.parse(socialMediaLink))) {
          await launchUrl(Uri.parse(socialMediaLink),
              mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        height: 24,
        width: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: UiUtils.getColorScheme(context).outline.withOpacity(0.2)),
        child: SvgPictureWidget(
            assetName: socialMediaIconName,
            height: 12,
            width: 12,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(_secondary(0.7), BlendMode.srcIn)),
      ),
    );
  }

  /// ---------------- LIST VIEW ----------------
  Widget authorNewsListView({required AuthorNewsFetchSuccess state}) {
    return ListView.separated(
        padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, _gutter),
        itemCount: state.AuthorNewsList.length,
        separatorBuilder: (_, __) => const SizedBox(height: _gutter),
        itemBuilder: (_, index) =>
            newsListTile(newsItem: state.AuthorNewsList[index]));
  }

  /// FIGMA card 1625-7548: 94px image flush to the left edge, then a 6px-padded
  /// column of title / description / divider / date + counters.
  Widget newsListTile({required NewsModel newsItem}) {
    return GestureDetector(
      onTap: () => redirectToNewsDetailsScreen(newsItem: newsItem),
      child: Container(
        decoration: _cardDecoration,
        child: Row(
          children: [
            ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(_cardRadius - 2)),
                child: CustomNetworkImage(
                    networkImageUrl: newsItem.image ?? "",
                    width: _listImageWidth,
                    height: _listCardHeight,
                    fit: BoxFit.cover)),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextLabel(
                        text: newsItem.title ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textStyle: _titleStyle(isList: true)),
                    const SizedBox(height: 4),
                    CustomTextLabel(
                        text: parse(newsItem.desc).body?.text ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textStyle: _descriptionStyle),
                    const SizedBox(height: 4),
                    _cardDivider,
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextLabel(
                              text: publishedDate(newsItem: newsItem),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textStyle: _metaStyle),
                        ),
                        const SizedBox(width: 4),
                        newsStats(newsItem: newsItem),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ---------------- GRID VIEW ----------------
  Widget authorNewsGridView({required AuthorNewsFetchSuccess state}) {
    return GridView.builder(
        padding: const EdgeInsets.fromLTRB(_gutter, 0, _gutter, _gutter),
        itemCount: state.AuthorNewsList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: _gutter,
            crossAxisSpacing: _gutter,
            mainAxisExtent: _gridCardHeight),
        itemBuilder: (_, index) =>
            newsGridTile(newsItem: state.AuthorNewsList[index]));
  }

  /// FIGMA card 1625-7696: 6px-padded column — image, date, title,
  /// description, divider, counters.
  Widget newsGridTile({required NewsModel newsItem}) {
    return GestureDetector(
      onTap: () => redirectToNewsDetailsScreen(newsItem: newsItem),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CustomNetworkImage(
                    networkImageUrl: newsItem.image ?? "",
                    height: _gridImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover)),
            const SizedBox(height: 8),
            CustomTextLabel(
                text: publishedDate(newsItem: newsItem),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textStyle: _metaStyle),
            const SizedBox(height: 8),
            CustomTextLabel(
                text: newsItem.title ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textStyle: _titleStyle(isList: false)),
            const SizedBox(height: 6),
            Flexible(
              child: CustomTextLabel(
                  text: parse(newsItem.desc).body?.text ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textStyle: _descriptionStyle),
            ),
            const SizedBox(height: 8),
            _cardDivider,
            const SizedBox(height: 8),
            newsStats(newsItem: newsItem),
          ],
        ),
      ),
    );
  }

  /// FIGMA "Stats Container": comment count then view count, 14px icons with a
  /// 4px gap to their value. Both counts come straight from get_authors_news.
  Widget newsStats({required NewsModel newsItem}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        newsStat(
            iconName: "comment", value: (newsItem.commentsCount ?? 0).toString()),
        const SizedBox(width: 10),
        newsStat(iconName: "eye", value: countLabel(newsItem.totalViews)),
      ],
    );
  }

  Widget newsStat({required String iconName, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPictureWidget(
            assetName: iconName,
            height: 14,
            width: 14,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(_secondary(0.5), BlendMode.srcIn)),
        const SizedBox(width: 4),
        CustomTextLabel(text: value, textStyle: _metaStyle),
      ],
    );
  }

  /// Counts arrive as strings and can be missing, empty or the literal "null".
  String countLabel(String? count) =>
      (count != null && count != "null" && count.isNotEmpty) ? count : "0";

  String publishedDate({required NewsModel newsItem}) => UiUtils.formatMyDateTime(
      DateTime.parse(newsItem.publishDate ?? newsItem.date!));

  void redirectToNewsDetailsScreen({required NewsModel newsItem}) {
    Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
      "model": newsItem,
      "isFromBreak": false,
      "fromShowMore": false
    });
  }
}
