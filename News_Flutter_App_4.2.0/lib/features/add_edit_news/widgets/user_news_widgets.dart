import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/app_theme.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/news/cubits/delete_user_news_cubit.dart';
import 'package:news/features/add_edit_news/blocs/get_user_news_cubit.dart';
import 'package:news/commons/cubits/theme_cubit.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/utils/ui_utils.dart';

class UsernewsWidgets {
  static final labelKeys = {
    "standard_post": 'stdPostLbl',
    videoTypeToString(VideoType.video_youtube): 'videoYoutubeLbl',
    videoTypeToString(VideoType.video_other): 'videoOtherUrlLbl',
    videoTypeToString(VideoType.video_upload): 'videoUploadLbl'
  };

  static buildNewsContainer(
      {required BuildContext context,
      required NewsModel model,
      required int index,
      required int totalCurrentNews,
      required bool hasMoreNewsFetchError,
      required bool hasMore,
      required Function fetchMoreNews}) {
    if (index == totalCurrentNews - 1 && index != 0) {
      if (hasMore) {
        if (hasMoreNewsFetchError) {
          return Center(
              child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: IconButton(
                onPressed: () => fetchMoreNews,
                icon: Icon(Icons.error, color: Theme.of(context).primaryColor)),
          ));
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

    final String contType = contentTypeLabel(context, model);
    final List<Widget> statuses = statusItems(context, model);

    return InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          if (model.status != "0") {
            //allow to goto News Details screen only if news is activated
            Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
              "model": model,
              "isFromBreak": false,
              "fromShowMore": false
            });
          }
        },
        child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: UiUtils.getColorScheme(context).surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                    color: UiUtils.getColorScheme(context)
                        .primaryContainer
                        .withOpacity(0.1))),
            margin: const EdgeInsets.only(top: 16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Person details (avatar, category, date, edit & delete)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        newsImage(
                            imageURL: model.image ?? "", context: context),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                categoryName(
                                    context: context,
                                    categoryName: (model.categoryName != null &&
                                            model.categoryName!
                                                .trim()
                                                .isNotEmpty)
                                        ? model.categoryName!
                                        : ""),
                                const SizedBox(height: 4),
                                setDate(
                                    context: context, dateValue: model.date!)
                              ]),
                        ),
                        const SizedBox(width: 8),
                        deleteAndEditButton(
                            context: context,
                            isEdit: true,
                            onTap: () => Navigator.of(context)
                                    .pushNamed(Routes.addNews, arguments: {
                                  "model": model,
                                  "isEdit": true,
                                  "from": "myNews"
                                })),
                        const SizedBox(width: 8),
                        deleteAndEditButton(
                            context: context,
                            isEdit: false,
                            onTap: () =>
                                deleteNewsDialogue(context, model.id!, index))
                      ],
                    ),
                  ),
                  Divider(
                      height: 1,
                      thickness: 1,
                      color: UiUtils.getColorScheme(context)
                          .primaryContainer
                          .withOpacity(0.2)),
                  // Article info (title, content type, status)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextLabel(
                              text: model.title!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      fontSize: 14,
                                      height: 20 / 14,
                                      letterSpacing: 0.1,
                                      fontWeight: FontWeight.w500,
                                      color: UiUtils.getColorScheme(context)
                                          .primaryContainer)),
                          if (contType.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            contentTypeView(
                                context: context, contentType: contType),
                          ],
                          if (statuses.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Divider(
                                height: 1,
                                thickness: 1,
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.1)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < statuses.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(child: statuses[i]),
                                ]
                              ],
                            ),
                          ],
                        ]),
                  ),
                ])));
  }

  static Widget statusInfo(BuildContext context,
      {required String assetName, required String labelKey}) {
    final Color red = context.read<ThemeCubit>().state.appTheme == AppTheme.Dark
        ? darkIconColor
        : iconColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPictureWidget(
            assetName: assetName,
            height: 16,
            width: 16,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(red, BlendMode.srcIn)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            UiUtils.getTranslatedLabel(context, labelKey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
                color: red),
          ),
        ),
      ],
    );
  }

  /// Only the badges that actually apply to [model], in Figma order. The caller
  /// lays them out from the start edge, so a lone "Deactivated" takes the slot
  /// "Expired News" would have occupied instead of leaving a hole behind it.
  static List<Widget> statusItems(BuildContext context, NewsModel model) {
    return [
      if (model.isExpired == 1) expiredInfo(context),
      if (model.status == "0") deactivatedInfo(context),
    ];
  }

  static Widget expiredInfo(BuildContext context) {
    return statusInfo(context,
        assetName: 'expiredNews', labelKey: 'expiredKey');
  }

  static Widget deactivatedInfo(BuildContext context) {
    return Tooltip(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: UiUtils.getColorScheme(context).primaryContainer,
          borderRadius: BorderRadius.circular(10)),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: UiUtils.getColorScheme(context).secondary, fontSize: 10),
      message: UiUtils.getTranslatedLabel(context, 'newsCreatedSuccessfully'),
      child: statusInfo(context,
          assetName: 'deactivatedNews', labelKey: 'deactivatedKey'),
    );
  }

  static Widget newsImage(
      {required BuildContext context, required String imageURL}) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: CustomNetworkImage(
            networkImageUrl: imageURL,
            fit: BoxFit.cover,
            height: 40,
            isVideo: false,
            width: 40));
  }

  static Widget categoryName(
      {required BuildContext context, required String categoryName}) {
    return (categoryName.trim().isNotEmpty)
        ? CustomTextLabel(
            text: categoryName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: true,
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: UiUtils.getColorScheme(context).primaryContainer,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w500))
        : const SizedBox.shrink();
  }

  static Widget deleteAndEditButton(
      {required BuildContext context,
      required bool isEdit,
      required void Function()? onTap}) {
    final Color tint = (isEdit)
        ? UiUtils.getColorScheme(context).primaryContainer
        : primaryColor;
    // Figma: edit = secondry-10 fill, delete = primary red @10% fill; both with
    // a same-colour 1px border and a 4px radius.
    final Color fill = tint.withOpacity(0.1);
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: fill)),
            child: SvgPictureWidget(
                assetName: (isEdit) ? 'editNewsIcon' : 'deleteNewsIcon',
                height: 30,
                width: 30,
                assetColor: ColorFilter.mode(
                    (isEdit) ? tint.withOpacity(0.8) : tint, BlendMode.srcIn),
                fit: BoxFit.contain)));
  }

  static Widget setDate(
      {required BuildContext context, required String dateValue}) {
    DateTime time = DateTime.parse(dateValue);
    var newFormat = DateFormat(
        "dd-MMM-yyyy", Hive.box(settingsBoxKey).get(currentLanguageCodeKey));
    final newNewsDate = newFormat.format(time);

    return CustomTextLabel(
        text: newNewsDate,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        textStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w400,
            color: UiUtils.getColorScheme(context)
                .primaryContainer
                .withOpacity(0.5)));
  }

  static deleteNewsDialogue(
      BuildContext mainContext, String id, int index) async {
    await showDialog(
        context: mainContext,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              backgroundColor: UiUtils.getColorScheme(context).surface,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              content: CustomTextLabel(
                  text: 'doYouReallyNewsLbl',
                  textStyle: Theme.of(context).textTheme.titleMedium),
              title: const CustomTextLabel(text: 'delNewsLbl'),
              titleTextStyle: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              actions: <Widget>[
                CustomTextButton(
                    textWidget: CustomTextLabel(
                        text: 'noLbl',
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer,
                                fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.of(context).pop(false);
                    }),
                BlocConsumer<DeleteUserNewsCubit, DeleteUserNewsState>(
                    bloc: context.read<DeleteUserNewsCubit>(),
                    listener: (context, state) {
                      if (state is DeleteUserNewsSuccess) {
                        context.read<GetUserNewsCubit>().deleteNews(index);
                        showSnackBar(state.message, context);
                        Navigator.pop(context);
                      }
                    },
                    builder: (context, state) {
                      return CustomTextButton(
                          textWidget: CustomTextLabel(
                              text: 'yesLbl',
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      color: UiUtils.getColorScheme(context)
                                          .primaryContainer,
                                      fontWeight: FontWeight.bold)),
                          onTap: () async {
                            context
                                .read<DeleteUserNewsCubit>()
                                .setDeleteUserNews(newsId: id);
                          });
                    })
              ],
            );
          });
        });
  }

  /// Translated content-type name, or "" when the news has no usable type.
  static String contentTypeLabel(BuildContext context, NewsModel model) {
    if (model.contentType == "") return "";
    final key = labelKeys[model.contentType];
    if (key == null) return "";
    return UiUtils.getTranslatedLabel(context, key);
  }

  static Widget contentTypeView(
      {required BuildContext context, required String contentType}) {
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w500,
        color:
            UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.5));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CustomTextLabel(
          text: 'contentTypeLbl',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textStyle: style),
      CustomTextLabel(text: ": ", textStyle: style),
      Flexible(
        child: CustomTextLabel(
            text: contentType,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textStyle: style),
      )
    ]);
  }
}
