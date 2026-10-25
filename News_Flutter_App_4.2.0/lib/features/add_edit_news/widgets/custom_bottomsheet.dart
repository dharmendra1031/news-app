import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/features/add_edit_news/blocs/tag_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/homepage/cubits/location_city_cubit.dart';
import 'package:news/features/add_edit_news/blocs/update_bottomsheet_content_cubit.dart';
import 'package:news/features/add_edit_news/blocs/add_tag_cubit.dart';
import 'package:news/features/news/models/tag_model.dart';
import 'package:news/utils/ui_utils.dart';

class CustomBottomsheet extends StatefulWidget {
  final BuildContext context;
  final String titleTxt;
  final int listLength;
  // final String language_id;
  final String language_code;
  final NullableIndexedWidgetBuilder listViewChild;
  final void Function(TagModel tag)? onExistingTagSelected;

  const CustomBottomsheet(
      {super.key,
      required this.context,
      required this.titleTxt,
      required this.listLength,
      required this.listViewChild,
      // required this.language_id,
      required this.language_code,
      this.onExistingTagSelected});

  @override
  CustomBottomsheetState createState() => CustomBottomsheetState();
}

class CustomBottomsheetState extends State<CustomBottomsheet> {
  late final ScrollController locationScrollController = ScrollController();
  late final ScrollController languageScrollController = ScrollController();
  late final ScrollController categoryScrollController = ScrollController();
  late final ScrollController subcategoryScrollController = ScrollController();
  late final ScrollController tagScrollController = ScrollController();

  final TextEditingController _tagTextController = TextEditingController();

  ScrollController scController = ScrollController();
  @override
  void initState() {
    super.initState();

    initScrollController();
  }

  @override
  void dispose() {
    _tagTextController.dispose();
    disposeScrollController();
    super.dispose();
  }

  void initScrollController() {
    switch (widget.titleTxt) {
      case 'chooseLanLbl':
        scController = languageScrollController;
        break;
      case 'selCatLbl':
        scController = categoryScrollController;
        break;
      case 'selSubCatLbl':
        scController = subcategoryScrollController;
        break;
      case 'selTagLbl':
        scController = tagScrollController;
        break;
      case 'selLocationLbl':
        scController = locationScrollController;
        break;
    }
    scController.addListener(() => hasMoreLocationScrollListener());
  }

  disposeScrollController() {
    switch (widget.titleTxt) {
      case 'chooseLanLbl':
        languageScrollController.dispose();
        break;
      case 'selCatLbl':
        categoryScrollController.dispose();
        break;
      case 'selSubCatLbl':
        subcategoryScrollController.dispose();
        break;
      case 'selTagLbl':
        tagScrollController.dispose();
        break;
      case 'selLocationLbl':
        locationScrollController.dispose();
        break;
    }
  }

  void hasMoreLocationScrollListener() {
    if (scController.offset >= scController.position.maxScrollExtent &&
        !scController.position.outOfRange) {
      switch (widget.titleTxt) {
        case 'selCatLbl':
          if (context.read<CategoryCubit>().hasMoreCategory()) {
            context
                .read<CategoryCubit>()
                .getMoreCategory(langCode: widget.language_code);
          }
          break;
        case 'selTagLbl':
          if (context.read<TagCubit>().hasMoreTags()) {
            context
                .read<TagCubit>()
                .getMoreTags(langCode: widget.language_code);
          }
          break;
        case 'selLocationLbl':
          if (context.read<LocationCityCubit>().hasMoreLocation()) {
            context.read<LocationCityCubit>().getMoreLocationCity();
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
        builder: (BuildContext context) =>
            BlocListener<AddTagCubit, AddTagState>(
              listener: (context, addTagState) {
                if (addTagState is AddTagSuccess) {
                  // Add the newly created tag at the beginning of the list (descending order - newest first)
                  final currentState = context.read<BottomSheetCubit>().state;
                  final updatedTags = [
                    addTagState.tag,
                    ...currentState.tagsData
                  ];
                  context
                      .read<BottomSheetCubit>()
                      .updateTagsContent(updatedTags);
                  _tagTextController.clear();

                  // Automatically select the newly created tag
                  if (widget.onExistingTagSelected != null) {
                    widget.onExistingTagSelected!(addTagState.tag);
                    Navigator.of(context).pop();
                  }
                }
              },
              child: BlocBuilder<BottomSheetCubit, BottomSheetState>(
                builder: (context, state) {
                  int listLength = widget.listLength;
                  switch (widget.titleTxt) {
                    case 'selLocationLbl':
                      listLength = state.locationData.length;
                      break;
                    case 'selTagLbl':
                      listLength = state.tagsData.length;
                      break;
                    case 'chooseLanLbl':
                      listLength = state.languageData.length;
                      break;
                    case 'selCatLbl':
                      listLength = state.categoryData.length;
                  }
                  return DraggableScrollableSheet(
                      snap: true,
                      snapSizes: const [0.5, 0.9],
                      expand: false,
                      builder: (_, controller) {
                        controller = scController;
                        return Container(
                            padding: const EdgeInsetsDirectional.only(
                                bottom: 15.0,
                                top: 15.0,
                                start: 20.0,
                                end: 20.0),
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
                                    text: widget.titleTxt,
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                UiUtils.getColorScheme(context)
                                                    .primaryContainer)),
                                const SizedBox(height: 10),
                                if (widget.titleTxt == 'selTagLbl')
                                  TextField(
                                    controller: _tagTextController,
                                    textInputAction: TextInputAction.send,
                                    keyboardType: TextInputType.text,
                                    maxLines: 1,
                                    onSubmitted: (value) {
                                      final name = value.trim();
                                      if (name.isEmpty) return;

                                      // Check if tag already exists (case-insensitive)
                                      final existingIndex = state.tagsData
                                          .indexWhere((t) =>
                                              (t.tagName ?? '').toLowerCase() ==
                                              name.toLowerCase());
                                      if (existingIndex != -1) {
                                        final tag =
                                            state.tagsData[existingIndex];
                                        if (widget.onExistingTagSelected !=
                                            null) {
                                          widget.onExistingTagSelected!(tag);
                                        }
                                        _tagTextController.clear();
                                        Navigator.of(context).pop();
                                        return;
                                      }

                                      context.read<AddTagCubit>().addTag(
                                          langCode: widget.language_code,
                                          tagName: name);
                                    },
                                    decoration: InputDecoration(
                                      hintText: UiUtils.getTranslatedLabel(
                                          context, 'addTagHintLbl'),
                                      filled: true,
                                      fillColor: UiUtils.getColorScheme(context)
                                          .surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          borderSide: BorderSide.none),
                                    ),
                                  ),
                                if (widget.titleTxt == 'selTagLbl')
                                  const SizedBox(height: 10),
                                Expanded(
                                    child: ListView.builder(
                                        controller: controller,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                                top: 10.0, bottom: 25.0),
                                        itemCount: listLength,
                                        itemBuilder: widget.listViewChild)),
                              ],
                            ));
                      });
                },
              ),
            ));
  }
}
