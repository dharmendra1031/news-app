import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news/commons/widgets/custom_text_btn.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/add_edit_news/blocs/add_news_cubit.dart';
import 'package:news/features/add_edit_news/blocs/tag_cubit.dart';
import 'package:news/features/add_edit_news/screens/news_description.dart';
import 'package:news/features/add_edit_news/widgets/app_text_file.dart';
import 'package:news/features/add_edit_news/widgets/bottom_sheet_option.dart';
import 'package:news/features/add_edit_news/widgets/custom_bottomsheet.dart';
import 'package:news/features/add_edit_news/widgets/gemini_service.dart';
import 'package:news/features/add_edit_news/widgets/next_button.dart';
import 'package:news/features/add_edit_news/widgets/selction_chip.dart';
import 'package:news/features/add_edit_news/widgets/selection_widget.dart';
import 'package:news/features/authentication/cubits/auth_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/news/cubits/delete_image_id.dart';
import 'package:news/features/add_edit_news/blocs/get_user_drafted_news_cubit.dart';
import 'package:news/features/add_edit_news/blocs/get_user_news_cubit.dart';
import 'package:news/features/language/cubits/language_cubit.dart';
import 'package:news/features/homepage/cubits/location_city_cubit.dart';
import 'package:news/features/add_edit_news/blocs/slug_check_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/add_edit_news/blocs/update_bottomsheet_content_cubit.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/tag_model.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/language/models/app_language_model.dart';
import 'package:news/features/homepage/models/location_city_model.dart';
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/utils/validators.dart';

class AddNews extends StatefulWidget {
  NewsModel? model;
  bool isEdit;
  String from;
  AddNews({super.key, this.model, required this.isEdit, required this.from});

  @override
  _AddNewsState createState() => _AddNewsState();

  static Route route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map<String, dynamic>;
    return CupertinoPageRoute(
        builder: (_) => AddNews(
            model: arguments['model'],
            isEdit: arguments['isEdit'],
            from: arguments['from']));
  }
}

class _AddNewsState extends State<AddNews> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String catSel = "",
      subCatSel = "",
      conType = "",
      conTypeId = "standard_post",
      langId = "",
      langCode = "",
      langName = "",
      locationSel = "",
      publishDate = "";
  String? title,
      catSelId,
      subSelId,
      showTill,
      url,
      desc,
      summDesc,
      locationSelId,
      metaKeyword,
      metaDescription,
      metaTitle,
      slug;
  int? catIndex, locationIndex, isDraft;
  List<String> tagsName = [], tagsId = [];
  Map<String, String> contentType = {};
  List<File> otherImage = [];
  File? image, videoUpload;
  bool isNext = false,
      isDescLoading = true,
      isMetaKeyword = false,
      isMetaDescription = false,
      isMetaTitle = false,
      isSlug = false,
      isShortNewsSelected = false;
  TextEditingController titleC = TextEditingController(),
      urlC = TextEditingController(),
      metaTitleC = TextEditingController(),
      metaDescriptionC = TextEditingController(),
      metaKeywordC = TextEditingController(),
      slugC = TextEditingController();
  List<CategoryModel> categories = [];
  List<LocationCityModel> locationCities = [];

  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd');
  String currentDate = "";
  DateTime? selectedPublishDate;
  DateTime? selectedShowTillDate;

  clearText() {
    setState(() {
      catSel = "";
      subCatSel = "";
      locationSel = "";
      publishDate = "";
      conType = UiUtils.getTranslatedLabel(context, 'stdPostLbl');
      title = catSelId = subSelId = showTill = url = catIndex =
          locationSelId = locationIndex = image = videoUpload = desc = null;
      conTypeId = 'standard_post';
      tagsName = tagsId = [];
      otherImage = [];
      isNext = false;
      isShortNewsSelected = false;
      titleC.clear();
      urlC.clear();
      metaTitleC.clear();
      metaDescriptionC.clear();
      metaKeywordC.clear();
      slugC.clear();
    });
  }

  setContentType() {
    contentType = {
      "standard_post": UiUtils.getTranslatedLabel(context, 'stdPostLbl'),
      videoTypeToString(VideoType.video_youtube):
          UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl'),
      videoTypeToString(VideoType.video_other):
          UiUtils.getTranslatedLabel(context, 'videoOtherUrlLbl'),
      videoTypeToString(VideoType.video_upload):
          UiUtils.getTranslatedLabel(context, 'videoUploadLbl'),
    };
  }

  addDataFromModel() {
    if (widget.model != null) {
      Future.delayed(Duration.zero, () {
        setState(() {
          setContentType();
          title = titleC.text = widget.model!.title!;
          catSel = widget.model!.categoryName!;
          catSelId = widget.model!.categoryId!;
          subCatSel = widget.model!.subCatName!;
          subSelId = widget.model!.subCatId!;
          langId = widget.model!.langId!;
          langCode = widget.model!.langCode!;
          updateDropdownsForLanguage();
          for (final entry in contentType.entries) {
            if (entry.key == widget.model!.contentType!) {
              conType = entry.value;
              conTypeId = entry.key;
            }
          }
          if (conTypeId == videoTypeToString(VideoType.video_youtube) ||
              conTypeId == videoTypeToString(VideoType.video_other) ||
              conTypeId == videoTypeToString(VideoType.video_upload))
            urlC.text = widget.model!.contentValue!;
          if (widget.model!.tagName! != "")
            tagsName = widget.model!.tagName!.split(',');
          if (widget.model!.tagId! != "")
            tagsId = (widget.model!.tagId!.contains(","))
                ? widget.model!.tagId!.split(",")
                : [widget.model!.tagId!];
          if (widget.model!.showTill != "0000-00-00" &&
              widget.model!.showTill != null)
            showTill = widget.model!.showTill!;
          if (widget.model!.publishDate != "0000-00-00" ||
              widget.model!.publishDate != "")
            publishDate = widget.model!.publishDate ?? "";
          print("val of published date $publishDate");
          desc = widget.model!.desc ?? "";
          summDesc = widget.model!.shortDesc ?? "";
          print("val of meta info ${widget.model!.metaTitle ?? ""}");
          metaTitleC.text = metaTitle = widget.model!.metaTitle ?? "";
          metaDescriptionC.text =
              metaDescription = widget.model!.metaDescription ?? "";
          metaKeywordC.text = metaKeyword = widget.model!.metaKeyword ?? "";
          slugC.text = slug = widget.model!.slug!;
          locationSelId = widget.model!.locationId;
          locationSel = widget.model!.locationName ?? "";
          isShortNewsSelected = widget.model!.isShortNews == true;
        });
      });
    }
  }

  @override
  void initState() {
    getStandardPostLabel();
    getCategory();
    getTag();
    getLanguageData();
    if (context.read<AppConfigurationCubit>().getLocationWiseNewsMode() == "1")
      getLocationCities();
    if (widget.isEdit) addDataFromModel();
    currentDate = formatter.format(now);
    super.initState();
  }

  @override
  void dispose() {
    titleC.dispose();
    urlC.dispose();
    metaTitleC.dispose();
    metaDescriptionC.dispose();
    metaKeywordC.dispose();
    slugC.dispose();

    super.dispose();
  }

  Future<void> getStandardPostLabel() async {
    conType = UiUtils.getTranslatedLabel(context, 'stdPostLbl');
    setState(() {});
  }

  Future getLanguageData() async {
    Future.delayed(Duration.zero, () {
      if (widget.isEdit) {
        context.read<LanguageCubit>().getLanguage().then((value) {
          for (int i = 0; i < value.length; i++) {
            if (widget.model!.langId! == value[i].id) {
              setState(() => langName = value[i].language!);
            }
          }
        });
      } else {
        context.read<LanguageCubit>().getLanguage();
      }
    });
  }

  void getCategory({String? languageCode}) {
    context.read<CategoryCubit>().getCategory(
        langCode: languageCode ??
            (context.read<AppLocalizationCubit>().state.languageCode));
  }

  void getTag({String? languageCode}) {
    Future.delayed(Duration.zero, () {
      context.read<TagCubit>().getTags(
          langCode: languageCode ??
              (context.read<AppLocalizationCubit>().state.languageCode));
    });
  }

  void getLocationCities() {
    Future.delayed(Duration.zero, () {
      context.read<LocationCityCubit>().getLocationCity();
    });
  }

  getAppBar() {
    if (!isNext) {
      return PreferredSize(
          preferredSize: const Size(double.infinity, 45),
          child: UiUtils.applyBoxShadow(
            context: context,
            child: AppBar(
              centerTitle: false,
              backgroundColor: Colors.transparent,
              title: Transform(
                  transform: Matrix4.translationValues(-20.0, 0.0, 0.0),
                  child: CustomTextLabel(
                      text: (widget.isEdit) ? 'editNewsLbl' : 'createNewsLbl',
                      textStyle: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              color: UiUtils.getColorScheme(context)
                                  .primaryContainer,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5))),
              leading: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: InkWell(
                    onTap: () {
                      if (!isNext) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => isNext = false);
                      }
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Icon(Icons.arrow_back,
                        color:
                            UiUtils.getColorScheme(context).primaryContainer)),
              ),
              actions: [
                Container(
                    padding: const EdgeInsetsDirectional.only(end: 20),
                    alignment: Alignment.center,
                    child: CustomTextLabel(
                        text: 'step1Of2Lbl',
                        textStyle: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.6))))
              ],
            ),
          ));
    }
  }

  showLanguageModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return CustomBottomsheet(
              context: context,
              titleTxt: 'chooseLanLbl',
              language_code: langCode,
              listLength: context.read<LanguageCubit>().langList().length,
              listViewChild: (context, index) {
                return langListItem(
                    index, context.read<LanguageCubit>().langList());
              });
        });
  }

  Widget languageSelName() {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        if (state is! LanguageFetchSuccess) {
          return const SizedBox.shrink();
        } else {
          context
              .read<BottomSheetCubit>()
              .updateLanguageContent(state.language);
        }

        return SelectionField(
          value: langName,
          placeholder: UiUtils.getTranslatedLabel(context, 'chooseLanLbl'),
          onTap: () => showLanguageModalBottomSheet(context),
        );
      },
    );
  }

  Widget catSelectionName() {
    if (langCode.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is! CategoryFetchSuccess) {
          return const SizedBox.shrink();
        } else {
          context
              .read<BottomSheetCubit>()
              .updateCategoryContent(state.category);
        }

        return SelectionField(
          value: catSel,
          placeholder: UiUtils.getTranslatedLabel(context, 'catLbl'),
          onTap: _showCategoryBottomSheet,
        );
      },
    );
  }

  void _showSubCategoryBottomSheet() {
    if (!_canShowSubCategory) return;

    final subCategories =
        context.read<CategoryCubit>().getCatList()[catIndex!].subData!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CustomBottomsheet(
          context: context,
          titleTxt: 'selSubCatLbl',
          language_code: langCode,
          listLength: subCategories.length,
          listViewChild: (_, index) {
            final item = subCategories[index];

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectionChip(
                title: item.subCatName!,
                selected: subSelId == item.id,
                onTap: () {
                  setState(() {
                    subCatSel = item.subCatName!;
                    subSelId = item.id;
                  });

                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryBottomSheet() {
    final categories = context.read<CategoryCubit>().getCatList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return CustomBottomsheet(
          context: context,
          titleTxt: 'selCatLbl',
          language_code: langCode,
          listLength: categories.length,
          listViewChild: (_, index) {
            final item = categories[index];

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SelectionChip(
                title: item.categoryName!,
                selected: catSelId == item.id,
                onTap: () {
                  setState(() {
                    catSel = item.categoryName!;
                    catSelId = item.id;
                    catIndex = index;

                    subCatSel = "";
                    subSelId = null;
                  });

                  Navigator.pop(context);
                },
              ),
            );
          },
        );
      },
    );
  }

  bool get _canShowSubCategory {
    if (catIndex == null) return false;

    final categories = context.read<CategoryCubit>().getCatList();

    if (categories.isEmpty) return false;

    if (catIndex! < 0 || catIndex! >= categories.length) return false;

    return categories[catIndex!].subData?.isNotEmpty ?? false;
  }

  Widget subCatSelectionName() {
    return SelectionField(
      value: subCatSel,
      placeholder: UiUtils.getTranslatedLabel(context, 'subcatLbl'),
      visible: _canShowSubCategory,
      onTap: _showSubCategoryBottomSheet,
    );
  }

  Widget contentTypeSelName() {
    return SelectionField(
      value: conType,
      placeholder: UiUtils.getTranslatedLabel(context, 'contentTypeLbl'),
      onTap: contentTypeBottomSheet,
    );
  }

  Widget contentVideoUpload() {
    return conType == UiUtils.getTranslatedLabel(context, 'videoUploadLbl')
        ? SelectionField(
            value:
                (videoUpload != null) ? videoUpload!.path.split('/').last : "",
            placeholder: UiUtils.getTranslatedLabel(context, 'uploadVideoLbl'),
            onTap: () => _getFromGalleryVideo())
        : const SizedBox.shrink();
  }

  Widget contentUrlForVideoUpload() {
    if (conTypeId == videoTypeToString(VideoType.video_upload) &&
        videoUpload == null &&
        urlC.text.isNotEmpty) {
      return Container(
          width: double.maxFinite,
          margin: const EdgeInsetsDirectional.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: UiUtils.getColorScheme(context).surface),
          child: InkWell(
            onTap: () async {
              //open url in newsVideo screen
              Navigator.of(context).pushNamed(Routes.newsVideo, arguments: {
                "from": 1,
                "model": widget.model,
                "otherVideos": <NewsModel>[]
              });
            },
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 25,
              children: [
                const Icon(Icons.play_circle_fill),
                CustomTextLabel(
                    text: 'previewLbl',
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    textStyle: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            color: UiUtils.getColorScheme(context)
                                .primaryContainer))
              ],
            ),
          ));
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget contentUrlSet() {
    if (conType == UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl') ||
        conType == UiUtils.getTranslatedLabel(context, 'videoOtherUrlLbl')) {
      return AppTextField(
        controller: urlC,
        hint: conType == UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl')
            ? UiUtils.getTranslatedLabel(context, 'youtubeUrlLbl')
            : UiUtils.getTranslatedLabel(context, 'otherUrlLbl'),
        maxLines: 1,
        validator: (val) =>
            conType == UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl')
                ? Validators.youtubeUrlValidation(val!, context)
                : Validators.urlValidation(val!, context),
        onChanged: (String value) => setState(() => url = value),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  contentTypeBottomSheet() {
    showModalBottomSheet<dynamic>(
        context: context,
        elevation: 3.0,
        isScrollControlled: true,
        //it will be closed only when user click On Save button & not by clicking anywhere else in screen
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        enableDrag: false,
        builder: (BuildContext context) => Container(
            padding: const EdgeInsetsDirectional.only(
                bottom: 15.0, top: 15.0, start: 20.0, end: 20.0),
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
                color: UiUtils.getColorScheme(context).surface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextLabel(
                    text: 'selContentTypeLbl',
                    textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            UiUtils.getColorScheme(context).primaryContainer)),
                Padding(
                    padding: const EdgeInsetsDirectional.only(
                        top: 10.0, bottom: 15.0),
                    child: Column(
                        children: contentType.entries.map((entry) {
                      return BottomSheetOption(
                          title: entry.value,
                          selected: false,
                          onTap: () {
                            if (conType != entry.value ||
                                conTypeId != entry.key) {
                              urlC.clear();
                              conType = entry.value;
                              conTypeId = entry.key;
                            }
                            if (widget.isEdit &&
                                conTypeId == widget.model!.contentType) {
                              urlC.text = widget.model!.contentValue!;
                            }
                            setState(() {});
                            Navigator.pop(context);
                          });
                    }).toList()))
              ],
            )));
  }

  void showSelectionBottomSheet({
    required String title,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomBottomsheet(
        context: context,
        titleTxt: title,
        language_code: langCode,
        listLength: itemCount,
        listViewChild: itemBuilder,
      ),
    );
  }

  Widget newsTitleName() {
    return AppTextField(
        controller: titleC,
        hint: UiUtils.getTranslatedLabel(context, 'titleLbl'),
        maxLines: 2,
        validator: (val) => Validators.titleValidation(val!, context),
        onChanged: (String value) {
          setState(() => title = value);
        },
        onComplete: (_) async {
          if (langId.isEmpty || (title?.isEmpty ?? true)) return;

          final meta = await GeminiService.generateMetaInfo(
            context: context,
            title: title!,
            language: langName,
            languageCode: langId,
            slugOnly: true,
          );

          slugC.text = meta["slug"];
          slug = slugC.text;
          // Setting controller.text programmatically does NOT fire onChanged,
          // so trigger the availability check manually. Without this the
          // SlugCheckCubit stays in its initial state and the Next-button
          // guard wrongly reports "slug already in use".
          if (slugC.text.trim().isNotEmpty) {
            context.read<SlugCheckCubit>().checkSlugAvailability(
                  slug: slugC.text,
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode,
                );
          }
          FocusManager.instance.primaryFocus?.unfocus();
        });
  }

  Widget tagSelectionName() {
    return (langCode.isNotEmpty)
        ? BlocConsumer<TagCubit, TagState>(listener: (context, state) {
            if (state is TagFetchSuccess) {
              context.read<BottomSheetCubit>().updateTagsContent(state.tag);
            }
          }, builder: (context, state) {
            if ((state is TagFetchSuccess && state.total > 0) ||
                (widget.isEdit && tagsName.isNotEmpty)) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: InkWell(
                  onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext context) {
                        return CustomBottomsheet(
                            context: context,
                            titleTxt: 'selTagLbl',
                            language_code: langCode,
                            listLength: (state as TagFetchSuccess).tag.length,
                            onExistingTagSelected: (tag) {
                              if (!tagsId.contains(tag.id!)) {
                                setState(() {
                                  tagsName.add(tag.tagName!);
                                  tagsId.add(tag.id!);
                                });
                              }
                            },
                            listViewChild: (context, index) {
                              final tags = context
                                  .read<BottomSheetCubit>()
                                  .state
                                  .tagsData;
                              if (index >= tags.length)
                                return const SizedBox.shrink();
                              return tagListItem(index, tags);
                            });
                      }),
                  child: Container(
                    width: double.maxFinite,
                    constraints: const BoxConstraints(minHeight: 56),
                    alignment: Alignment.centerLeft,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        color: UiUtils.getColorScheme(context).surface,
                        border: Theme.of(context).brightness ==
                                Brightness.dark
                            ? Border.all(color: darkBorderDefaultColor)
                            : null),
                    child: tagsId.isEmpty
                        ? CustomTextLabel(
                            text: 'addTagLbl',
                            textStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    color: UiUtils.getColorScheme(context)
                                        .primaryContainer
                                        .withOpacity(0.7)))
                        : SizedBox(
                            height: MediaQuery.of(context).size.height * 0.06,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: tagsName.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsetsDirectional.only(
                                      start: index != 0 ? 10.0 : 0),
                                  child: Stack(
                                    children: [
                                      Container(
                                        margin:
                                            const EdgeInsetsDirectional.only(
                                                end: 7.5, top: 7.5),
                                        padding:
                                            const EdgeInsetsDirectional.all(
                                                7.0),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            color:
                                                UiUtils.getColorScheme(context)
                                                    .primaryContainer),
                                        alignment: Alignment.center,
                                        child: CustomTextLabel(
                                            text: tagsName[index],
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color:
                                                        UiUtils.getColorScheme(
                                                                context)
                                                            .surface)),
                                      ),
                                      Positioned.directional(
                                          textDirection:
                                              Directionality.of(context),
                                          end: 0,
                                          child: Container(
                                              height: 15,
                                              width: 15,
                                              alignment: Alignment.center,
                                              margin: const EdgeInsets.all(3.0),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          25.0),
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                              child: InkWell(
                                                child: Icon(Icons.close,
                                                    size: 11,
                                                    color:
                                                        UiUtils.getColorScheme(
                                                                context)
                                                            .surface),
                                                onTap: () {
                                                  setState(() {
                                                    tagsName.remove(
                                                        tagsName[index]);
                                                    tagsId
                                                        .remove(tagsId[index]);
                                                  });
                                                },
                                              )))
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          })
        : SizedBox.shrink();
  }

  Widget locationCitySelectionName() {
    return BlocConsumer<LocationCityCubit, LocationCityState>(
      listener: (context, state) {
        if (locationSel != "" ||
            (widget.isEdit && widget.model!.locationId != null))
          locationIndex = context
              .read<LocationCityCubit>()
              .getLocationIndex(locationName: locationSel);
        if (state is LocationCityFetchSuccess) {
          context
              .read<BottomSheetCubit>()
              .updateLocationContent(state.locationCity);
        }
      },
      builder: (context, state) {
        if (state is LocationCityFetchSuccess) {
          if (state.locationCity.isNotEmpty && state.locationCity.length == 1) {
            locationSelId = state.locationCity.first.id;
            locationIndex = 0;
          }
          return SelectionField(
            value: (state.locationCity.length == 1)
                ? locationSel = state.locationCity.first.locationName
                : (locationSel == "")
                    ? UiUtils.getTranslatedLabel(context, 'selLocationLbl')
                    : locationSel,
            placeholder: UiUtils.getTranslatedLabel(context, 'selLocationLbl'),
            onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) {
                  return CustomBottomsheet(
                      context: context,
                      titleTxt: 'selLocationLbl',
                      language_code: langCode,
                      listLength: state.locationCity.length,
                      listViewChild: (context, index) {
                        return locationCityListItem(index, state.locationCity);
                      });
                }),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget showTillSelDate() {
    return SelectionField(
        isDate: true,
        value: showTill ?? "",
        placeholder: UiUtils.getTranslatedLabel(context, 'showTilledDate'),
        onTap: () async {
          DateTime? showTillDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now().subtract(const Duration(days: -1)),
            lastDate: DateTime(DateTime.now().year + 1),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  dialogTheme: const DialogThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  colorScheme: ColorScheme.fromSeed(
                      seedColor: UiUtils.getColorScheme(context).primary,
                      brightness: Theme.of(context).brightness,
                      primary:
                          UiUtils.getColorScheme(context).secondaryContainer),
                ),
                child: child!,
              );
            },
          );

          if (showTillDate != null) {
            //pickedDate output format => 2021-03-10 00:00:00.000
            String formattedDate =
                DateFormat('yyyy-MM-dd').format(showTillDate);
            setState(() => showTill = formattedDate);

            selectedShowTillDate = showTillDate;
            if (selectedPublishDate != null &&
                selectedShowTillDate!.isBefore(selectedPublishDate!)) {
              showSnackBar(
                  UiUtils.getTranslatedLabel(context, 'dateConfirmation'),
                  context);
              return;
            }
          }
        });
  }

  void _showPicker() {
    UiUtils().showUploadImageBottomsheet(
        context: context, onCamera: _getFromCamera, onGallery: _getFromGallery);
  }

  _getFromCamera() async {
    try {
      XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (!mounted || pickedFile == null) return;
      setState(() {
        image = File(pickedFile.path);
      });
      Navigator.of(context).pop(); //pop dialog
    } catch (e) {
      //debugPrint("camera-error-${e.toString()}");
    }
  }

  _getFromGallery() async {
    try {
      XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (!mounted || pickedFile == null) return;
      setState(() {
        image = File(pickedFile.path);
      });
      Navigator.of(context).pop();
    } catch (e) {
      //debugPrint("gallery-error-${e.toString()}");
    }
  }

  List<XFile> pickedFileList = [];
  _getFromGalleryOther(ImageSource source) async {
    final picker = ImagePicker();

    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images =
            await picker.pickMultiImage(maxWidth: 1800, maxHeight: 1800);

        if (!mounted || images.isEmpty) return;

        setState(() {
          pickedFileList.addAll(images);
          otherImage.addAll(images.map((x) => File(x.path)));
        });
      } else if (source == ImageSource.camera) {
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1800,
          maxHeight: 1800,
        );

        if (!mounted || image == null) return;

        setState(() {
          pickedFileList.add(image);
          otherImage.add(File(image.path));
        });
      }
      Navigator.of(context).pop(); //pop dialog
    } catch (e) {
      //debugPrint("gallery-other-error-${e.toString()}");
    }
  }

  void _showOtherImagePicker() {
    UiUtils().showUploadImageBottomsheet(
      context: context,
      onCamera: () => _getFromGalleryOther(ImageSource.camera),
      onGallery: () => _getFromGalleryOther(ImageSource.gallery),
    );
  }

  _getFromGalleryVideo() async {
    try {
      final XFile? file = await ImagePicker().pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 10));
      if (!mounted || file == null) return;
      setState(() => videoUpload = File(file.path));
    } catch (e) {
      //debugPrint("video-error-${e.toString()}");
    }
  }

  //dashed upload box content: 20px icon + 8px gap + body-medium label
  Widget uploadBoxContent(String label) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.image,
          size: 20,
          color: UiUtils.getColorScheme(context)
              .primaryContainer
              .withOpacity(0.7)),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: CustomTextLabel(
            text: label,
            textStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: UiUtils.getColorScheme(context)
                    .primaryContainer
                    .withOpacity(0.7))),
      )
    ]);
  }

  Widget uploadMainImage() {
    return InkWell(
      onTap: () => _showPicker(),
      child: (widget.isEdit || image != null)
          ? Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: (image == null)
                      ? CustomNetworkImage(
                          networkImageUrl: widget.model!.image ?? "",
                          width: double.maxFinite,
                          height: 125,
                          fit: BoxFit.cover,
                          isVideo: false)
                      : Image.file(image!,
                          height: 125,
                          width: double.maxFinite,
                          fit: BoxFit.fill)),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 93,
                width: double.maxFinite,
                child: UiUtils.dottedRRectBorder(
                    context: context,
                    childWidget: uploadBoxContent('uploadMainImageLbl')),
              ),
            ),
    );
  }

  Widget uploadOtherImage() {
    return otherImage.isEmpty
        ? InkWell(
            onTap: () => _showOtherImagePicker(),
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                  height: 93,
                  width: double.maxFinite,
                  child: UiUtils.dottedRRectBorder(
                      context: context,
                      childWidget: uploadBoxContent('uploadOtherImageLbl'))),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _showOtherImagePicker(),
                  child: SizedBox(
                    height: 125,
                    width: 95,
                    child: UiUtils.dottedRRectBorder(
                        context: context,
                        childWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image,
                                  size: 15,
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer
                                      .withOpacity(0.7)),
                              CustomTextLabel(
                                text: 'uploadOtherImageLbl',
                                textAlign: TextAlign.center,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: UiUtils.getColorScheme(context)
                                            .primaryContainer
                                            .withOpacity(0.5)),
                              )
                            ])),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                      height: 125,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: otherImage.length,
                        itemBuilder: (context, index) {
                          return Stack(clipBehavior: Clip.none, children: [
                            Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(start: 10),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(otherImage[index],
                                        height: 125,
                                        width: 95,
                                        fit: BoxFit.fill))),
                            Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: 0,
                                top: 0,
                                child: Container(
                                    height: 18,
                                    width: 18,
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.all(3.0),
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                        color: Theme.of(context).primaryColor),
                                    child: InkWell(
                                      child: Icon(Icons.close,
                                          size: 13,
                                          color: UiUtils.getColorScheme(context)
                                              .surface),
                                      onTap: () {
                                        otherImage.removeAt(
                                            index); //remove currently uploaded image
                                        setState(() {});
                                      },
                                    )))
                          ]);
                        },
                      )),
                )
              ],
            ),
          );
  }

  Widget modelOtherImage() {
    return widget.model!.imageDataList!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
                height: 125,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.model!.imageDataList!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 10, end: 8),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: CustomNetworkImage(
                                    networkImageUrl: widget.model!
                                        .imageDataList![index].otherImage!,
                                    isVideo: false,
                                    fit: BoxFit.cover,
                                    height: 125,
                                    width: 95)),
                          ),
                          BlocConsumer<DeleteImageCubit, DeleteImageState>(
                              bloc: context.read<DeleteImageCubit>(),
                              listener: (context, state) {
                                if (state is DeleteImageSuccess) {
                                  context
                                      .read<GetUserNewsCubit>()
                                      .deleteImageId(index);
                                  showSnackBar(state.message, context);
                                  setState(() {});
                                }
                              },
                              builder: (context, state) {
                                return Positioned.directional(
                                    textDirection: Directionality.of(context),
                                    end: 0,
                                    child: Container(
                                        height: 18,
                                        width: 18,
                                        alignment: Alignment.center,
                                        margin: const EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(25.0),
                                            color:
                                                Theme.of(context).primaryColor),
                                        child: InkWell(
                                          child: Icon(Icons.close,
                                              size: 13,
                                              color: UiUtils.getColorScheme(
                                                      context)
                                                  .surface),
                                          onTap: () {
                                            context
                                                .read<DeleteImageCubit>()
                                                .setDeleteImage(
                                                    imageId: widget
                                                        .model!
                                                        .imageDataList![index]
                                                        .id!);
                                            setState(() {});
                                          },
                                        )));
                              })
                        ],
                      ),
                    );
                  },
                )))
        : const SizedBox.shrink();
  }

  Widget publishDateSelection() {
    return SelectionField(
      isDate: true,
      value: publishDate,
      placeholder: UiUtils.getTranslatedLabel(context, 'publishDate'),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(DateTime.now().year + 1),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                dialogTheme: const DialogThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                colorScheme: ColorScheme.fromSeed(
                    seedColor: UiUtils.getColorScheme(context).primary,
                    brightness: Theme.of(context).brightness,
                    primary:
                        UiUtils.getColorScheme(context).secondaryContainer),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(
              () => publishDate = DateFormat('yyyy-MM-dd').format(pickedDate));
        }
        selectedPublishDate = pickedDate;
      },
    );
  }

  void onSubmitButton() async {
    FocusScope.of(context).unfocus();
    final form = _formkey.currentState;
    form!.save();

    //check for the ones, which are not validated in form above
    if (langName.isEmpty) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'chooseLanLbl'), context);
      return;
    }
    if (catSelId == null) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzSelCatLbl'), context);
      return;
    }
    if (conType == UiUtils.getTranslatedLabel(context, 'videoUploadLbl')) {
      if (!widget.isEdit && videoUpload == null) {
        showSnackBar(
            UiUtils.getTranslatedLabel(context, 'plzUploadVideoLbl'), context);
        return;
      }
    }
    if ((conType == UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl') ||
            conType ==
                UiUtils.getTranslatedLabel(context, 'videoOtherUrlLbl')) &&
        urlC.text.contains("/shorts")) {
      //do not allow to add link of Youtube shorts as of now
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'plzValidUrlLbl'), context);
      urlC.clear();
      return;
    }
    //validate other or Youtube URL & set type accordingly
    if (conType == UiUtils.getTranslatedLabel(context, 'videoOtherUrlLbl') &&
        (urlC.text.contains("youtube") || urlC.text.contains("youtu.be"))) {
      conType = UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl');
      conTypeId = videoTypeToString(VideoType.video_youtube);
    } else if (conType ==
            UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl') &&
        (!urlC.text.contains("youtube") && !urlC.text.contains("youtu.be"))) {
      conType = UiUtils.getTranslatedLabel(context, 'videoOtherUrlLbl');
      conTypeId = videoTypeToString(VideoType.video_other);
    }
    if (selectedPublishDate != null &&
        selectedShowTillDate != null &&
        selectedShowTillDate!.isBefore(selectedPublishDate!)) {
      showSnackBar(
          UiUtils.getTranslatedLabel(context, 'dateConfirmation'), context);
    }

    if (form.validate()) {
      if (!widget.isEdit && image == null) {
        showSnackBar(
            UiUtils.getTranslatedLabel(context, 'plzAddMainImageLbl'), context);
        return;
      }

      //validate slug here
      if (!widget.isEdit &&
          context.read<SlugCheckCubit>().state is! SlugCheckFetchSuccess) {
        showSnackBar(
            UiUtils.getTranslatedLabel(context, 'slugUsedAlready'), context);
        return;
      }
      setState(() => isNext = true);
    }
  }

  validateFunc(String description, String summDescription) {
    desc = description;
    summDesc = summDescription;
    validateForm();
  }

  isDraftNews(int isDrafted) {
    //set isDraft here
    isDraft = isDrafted;
  }

  Widget tagListItem(int index, List<TagModel> tags) {
    final tag = tags[index];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SelectionChip(
        title: tag.tagName!,
        selected: tagsId.contains(tag.id),
        onTap: () {
          setState(() {
            if (tagsId.contains(tag.id)) {
              tagsId.remove(tag.id);
              tagsName.remove(tag.tagName);
            } else {
              tagsId.add(tag.id!);
              tagsName.add(tag.tagName!);
            }
          });

          Navigator.pop(context);
        },
      ),
    );
  }

  Widget subCatListItem(int index, List<CategoryModel> catList) {
    return BottomSheetOption(
        title: catList[catIndex!].subData![index].subCatName!,
        selected: (catList[catIndex!].subData![index].id != null &&
            catList[catIndex!].subData![index].id!.isNotEmpty &&
            catList[catIndex!].subData![index].id == subSelId),
        onTap: () {
          setState(() {
            subCatSel = catList[catIndex!].subData![index].subCatName!;
            subSelId = catList[catIndex!].subData![index].id!;
          });
          Navigator.pop(context);
        });
  }

  void updateDropdownsForLanguage() {
    getCategory(languageCode: langCode);
    getTag(languageCode: langCode);
  }

  Widget langListItem(int index, List<LanguageModel> langList) {
    return BottomSheetOption(
        title: langList[index].language!,
        selected: langList[index].id == langId,
        onTap: () {
          langId = langList[index].id!;
          langCode = langList[index].code!;
          langName = langList[index].language!;
          catSel = "";
          catSelId = null;
          tagsName.clear();
          tagsId.clear();
          //load categories according to language selected
          updateDropdownsForLanguage();
          setState(() {});
          Navigator.pop(context);
        });
  }

  Widget catListItem(
    int index,
    List<CategoryModel> categories,
  ) {
    final category = categories[index];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SelectionChip(
        title: category.categoryName!,
        selected: category.id == catSelId,
        onTap: () {
          setState(() {
            catSel = category.categoryName!;
            catSelId = category.id!;
            catIndex = index;

            subSelId = null;
            subCatSel = '';
          });

          Navigator.pop(context);
        },
      ),
    );
  }

  Widget locationCityListItem(
      int index, List<LocationCityModel> locationCityList) {
    return BottomSheetOption(
      title: locationCityList[index].locationName,
      selected: (locationCityList[index].id != "" &&
          locationCityList[index].id == locationSelId),
      onTap: () {
        setState(() {
          locationSel = locationCityList[index].locationName;
          locationSelId = locationCityList[index].id;
          locationIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    setContentType();
    return Scaffold(
      bottomNavigationBar:
          !isNext ? NextButton(onPressed: onSubmitButton) : null,
      key: _scaffoldKey,
      appBar: getAppBar(),
      body: BlocConsumer<AddNewsCubit, AddNewsState>(
          bloc: context.read<AddNewsCubit>(),
          listener: (context, state) async {
            if (state is AddNewsFetchFailure)
              showSnackBar(state.errorMessage, context);
            if (state is AddNewsFetchSuccess) {
              const snackBarMs = 2500;
              if (!widget.isEdit) {
                // Auto-approve authors get their (non-draft) news published
                // immediately, so show the "published" message instead of the
                // default "pending admin approval" one. Drafts are never live,
                // so they keep the default message regardless of auto-approve.
                final bool autoPublished =
                    context.read<AuthCubit>().isAuthorAutoApprove() &&
                        (isDraft != 1);
                showSnackBar(
                    UiUtils.getTranslatedLabel(
                        context,
                        autoPublished
                            ? 'newsPublishedSuccessfully'
                            : 'newsCreatedSuccessfully'),
                    context,
                    durationInMiliSeconds: snackBarMs);
                if (widget.from == "myNews") {
                  FocusScope.of(context).unfocus();
                  clearText();
                  context.read<GetUserNewsCubit>().getGetUserNews(
                      latitude: SettingsLocalDataRepository()
                          .getLocationCityValues()
                          .first,
                      longitude: SettingsLocalDataRepository()
                          .getLocationCityValues()
                          .last);
                  context.read<GetUserDraftedNewsCubit>().getUserDraftedNews(
                      userId: int.parse(context.read<AuthCubit>().getUserId()));
                  // Go straight back to the News screen. The snackbar lives on
                  // the app-level ScaffoldMessenger, so it stays visible there.
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushReplacementNamed(Routes.manageUserNews)
                      .whenComplete(() {
                    FocusScope.of(context).unfocus();
                    clearText();
                  });
                }
              } else {
                context.read<GetUserNewsCubit>().getGetUserNews(
                    latitude: SettingsLocalDataRepository()
                        .getLocationCityValues()
                        .first,
                    longitude: SettingsLocalDataRepository()
                        .getLocationCityValues()
                        .last);
                context.read<GetUserDraftedNewsCubit>().getUserDraftedNews(
                    userId: int.parse(context.read<AuthCubit>().getUserId()));
                showSnackBar(state.addNews["message"], context,
                    durationInMiliSeconds: snackBarMs);
                Navigator.of(context).pop();
              }
            }
          },
          builder: (context, state) {
            return Form(
                key: _formkey,
                child: Stack(children: [
                  if (state is AddNewsFetchInProgress)
                    Center(
                        child: UiUtils.showCircularProgress(
                            true, Theme.of(context).primaryColor)),
                  !isNext
                      ? PopScope(
                          canPop: (!isNext) ? true : false,
                          onPopInvoked: (bool isTrue) {
                            setState(() => isNext = false);
                          },
                          child: SingleChildScrollView(
                              // Each field carries its own top gap of 16 so the
                              // ones that collapse to SizedBox.shrink() don't
                              // leave a hole. Hence no top padding here.
                              padding: const EdgeInsetsDirectional.only(
                                  start: 16, end: 16, bottom: 16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  newsTitleName(),
                                  languageSelName(),
                                  catSelectionName(),
                                  subCatSelectionName(),
                                  contentTypeSelName(),
                                  if (widget.isEdit) contentUrlForVideoUpload(),
                                  contentVideoUpload(),
                                  contentUrlSet(),
                                  tagSelectionName(),
                                  locationCitySelectionName(),
                                  publishDateSelection(),
                                  showTillSelDate(),
                                  uploadMainImage(),
                                  uploadOtherImage(),
                                  if (widget.isEdit) modelOtherImage(),
                                  showIsShortNews(),
                                  webNewsDetails()
                                ],
                              )),
                        )
                      : NewsDescription(
                          desc ?? "",
                          summDesc ?? "",
                          updateParent,
                          validateFunc,
                          (widget.isEdit) ? 2 : 1,
                          isDraftNews)
                ]));
          }),
    );
  }

  Widget showIsShortNews() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 16),
      child: InkWell(
        onTap: () => setState(() => isShortNewsSelected = !isShortNewsSelected),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UiUtils.showCheckbox(
              context: context,
              isSelected: isShortNewsSelected,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextLabel(
                text: 'addToShortNewsLbl',
                textAlign: TextAlign.start,
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget webNewsDetails() {
    return Column(children: [
      if (!widget.isEdit) autoGenerateMetaInfoButton(),
      AppTextField(
          controller: metaTitleC,
          hint: 'metaTitleLbl',
          floatingLabel: true,
          onChanged: (String value) => setState(() {
                metaTitle = value;
              }),
          maxLines: 1),
      AppTextField(
          controller: metaDescriptionC,
          hint: 'metaDescriptionLbl',
          floatingLabel: true,
          onChanged: (String value) => setState(() {
                metaDescription = value;
              }),
          maxLines: 2),
      AppTextField(
          controller: metaKeywordC,
          hint: 'metaKeywordLbl',
          floatingLabel: true,
          onChanged: (String value) => setState(() {
                metaKeyword = value;
              }),
          maxLines: 1),
      AppTextField(
          controller: slugC,
          hint: 'slugLbl',
          floatingLabel: true,
          validator: (val) => Validators.slugValidation(val!, context),
          onChanged: (String value) => setState(() {
                slugC.text = slugC.text.replaceAll(' ', '-');
                slug = slugC.text;
                //call APi to check Availability of Entered slug
                if (slugC.text.trim().isNotEmpty) {
                  context.read<SlugCheckCubit>().checkSlugAvailability(
                      slug: slugC.text,
                      langCode: context
                          .read<AppLocalizationCubit>()
                          .state
                          .languageCode);
                }
              }),
          maxLines: 1)
    ]);
  }

  bool isProcessing = false;
  Widget autoGenerateMetaInfoButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: (isProcessing)
          ? Container(
              height: MediaQuery.of(context).size.height * 0.04,
              width: MediaQuery.of(context).size.width * 0.48,
              child: UiUtils.showCircularProgress(
                  true, Theme.of(context).primaryColor),
            )
          : CustomTextButton(
              onTap: () async {
                if ((title ?? '').isEmpty)
                  return showSnackBar(
                      UiUtils.getTranslatedLabel(context, "newsTitleReqLbl"),
                      context);

                if (langId.isEmpty)
                  return showSnackBar(
                      UiUtils.getTranslatedLabel(context, "chooseLanLbl"),
                      context);
                setState(() {
                  isProcessing = true;
                });
                try {
                  final meta = await GeminiService.generateMetaInfo(
                      context: context,
                      title: title ?? "",
                      language: langName,
                      languageCode: langId);

                  metaTitle = metaTitleC.text = meta["meta_title"];
                  metaDescription =
                      metaDescriptionC.text = meta["meta_description"];
                  metaKeyword = metaKeywordC.text = meta["meta_keywords"];

                  setState(() {
                    isProcessing = false;
                  });
                  showSnackBar(
                      UiUtils.getTranslatedLabel(
                          context, "metaInformationApplied"),
                      context);
                } catch (e) {
                  setState(() {
                    isProcessing = false;
                  });
                  showSnackBar(
                      UiUtils.getTranslatedLabel(
                          context, "failedToGenerateMetaInfo"),
                      context);
                }
              },
              textWidget: Container(
                height: MediaQuery.of(context).size.height * 0.04,
                width: MediaQuery.of(context).size.width * 0.48,
                decoration: BoxDecoration(
                    color: UiUtils.getColorScheme(context).primaryContainer,
                    borderRadius: BorderRadius.circular(7.0)),
                child: Center(
                  child: CustomTextLabel(
                      text: UiUtils.getTranslatedLabel(
                          context, 'autoGenerateMetaInfo'),
                      textStyle: TextStyle(
                          color: UiUtils.getColorScheme(context).secondary)),
                ),
              ),
              buttonStyle: ButtonStyle(
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  foregroundColor: WidgetStateProperty.all(
                      UiUtils.getColorScheme(context).onPrimary))),
    );
  }

  updateParent(String description, String summDescription, bool next) {
    if (!mounted) return;
    setState(() {
      desc = description;
      summDesc = summDescription;
      isNext = next;
    });
  }

  validateForm() async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      context.read<AddNewsCubit>().addNews(
          context: context,
          newsId: (widget.isEdit) ? widget.model!.id! : null,
          actionType: (widget.isEdit) ? "2" : "1",
          catId: catSelId!,
          title: title!,
          conTypeId: conTypeId,
          conType: conType,
          image: image,
          langId: langId,
          langCode: langCode,
          subCatId: subSelId,
          showTill: showTill,
          desc: desc,
          otherImage: otherImage,
          tagId: tagsId.isNotEmpty ? tagsId.join(',') : null,
          url: urlC.text.isNotEmpty ? urlC.text : null,
          videoUpload: videoUpload,
          locationId: locationSelId,
          metaTitle: metaTitle ?? "",
          metaDescription: metaDescription ?? "",
          metaKeyword: metaKeyword ?? "",
          slug: slug!,
          publishDate: publishDate.isEmpty ? null : publishDate,
          summDescription: summDesc,
          isDraft: isDraft ?? 0,
          isShortNews: isShortNewsSelected ? 1 : 0);
      getCategory(); //get default language categories again for Categories Tab
    } else {
      showSnackBar(UiUtils.getTranslatedLabel(context, 'internetmsg'), context);
    }
  }
}
