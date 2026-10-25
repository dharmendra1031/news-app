import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/features/add_edit_news/blocs/tag_cubit.dart';
import 'package:news/features/filter/screens/filter_bottomsheet.dart';
import 'package:news/features/filter/widgets/duration_filter_widget.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/commons/cubits/app_system_setting_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart'; 
import 'package:news/commons/repositories/settings/settings_local_data_repository.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/news/models/tag_model.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart'; 
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/commons/widgets/custom_back_btn.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'dart:async';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  SearchState createState() => SearchState();
}

bool buildResult =
    false; //used in 2 classes here _SearchState & _SuggestionList

class SearchState extends State<Search> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int pos = 0;
  List<NewsModel> searchList = [];
  final List<TextEditingController> _controllerList = [];
  bool isNetworkAvail = true;

  String query = "";
  int notificationoffset = 0;
  ScrollController? notificationcontroller;
  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;

  // Filter related variables
  bool isFilterApplied = false;
  List<CategoryModel> filterSelectedCategories = [];
  List<TagModel> filterSelectedTags = [];
  DateTime? filterSelectedDate;
  DurationFilter? filterDurationFilter;

  Timer? _debounce;
  List<NewsModel> history = [];

  List<String> hisList = [];

  // Apply filters to search results
  void applyFilters() {
    notificationoffset = 0;

    getSearchNews(isFilter: true);
  }

  @override
  void initState() {
    super.initState();
    searchList.clear();

    // Load categories and tags if not already loaded
    context.read<CategoryCubit>().loadIfFailed(
        langCode: context.read<AppLocalizationCubit>().state.languageCode);
    context.read<TagCubit>().loadIfFailed(
        langCode: context.read<AppLocalizationCubit>().state.languageCode);

    notificationoffset = 0;

    notificationcontroller = ScrollController(keepScrollOffset: true);
    notificationcontroller!.addListener(_searchScrollListener);

    _controller.addListener(() {
      if (_controller.text.isEmpty) {
        if (mounted) {
          setState(() {
            query = "";
          });
        }
      } else {
        query = _controller.text.trim();
        notificationoffset = 0;
        notificationisnodata = false;
        buildResult = false;
        if (query.isNotEmpty) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            notificationisloadmore = true;
            notificationoffset = 0;
            getSearchNews();
          });
        }
      }
    });
  }

  _searchScrollListener() {
    if (notificationcontroller!.offset >=
            notificationcontroller!.position.maxScrollExtent &&
        !notificationcontroller!.position.outOfRange) {
      if (mounted) {
        setState(() {
          getSearchNews();
        });
      }
    }
  }

  Future<List<String>> getHistory() async {
    hisList = UiUtils.getDynamicListValue(historyListKey);
    return hisList;
  }

  @override
  void dispose() {
    notificationcontroller!.dispose();
    _controller.dispose();
    for (int i = 0; i < _controllerList.length; i++) {
      _controllerList[i].dispose();
    }

    super.dispose();
  }

  PreferredSizeWidget appbar() {
    return AppBar(
      leading: const CustomBackButton(horizontalPadding: 15),
      backgroundColor: Theme.of(context).canvasColor,
      title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            hintText: UiUtils.getTranslatedLabel(context, 'search'),
            hintStyle: TextStyle(
                color: UiUtils.getColorScheme(context)
                    .primaryContainer
                    .withOpacity(0.7)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            // enabledBorder: UnderlineInputBorder(
            //     borderSide: BorderSide(
            //         color: UiUtils.getColorScheme(context).primaryContainer)),
            // focusedBorder: UnderlineInputBorder(
            //     borderSide: BorderSide(
            //         color: UiUtils.getColorScheme(context).primaryContainer)),
            // fillColor: secondaryColor
          )),
      titleSpacing: 0,
      shape: Border(
          bottom: BorderSide(
        color: UiUtils.getColorScheme(context).primaryContainer,
        width: 1,
      )),
      actions: [
        IconButton(
            onPressed: () {
              _controller.text = '';
            },
            icon: Icon(Icons.close,
                color: UiUtils.getColorScheme(context).primaryContainer)),
        IconButton(
            padding: EdgeInsetsDirectional.only(end: 7),
            onPressed: () async {
              FocusManager.instance.rootScope.unfocus();
              final NewsFilterData? result = await showFilterBottomSheet(
                context: context,
                isCategoryModeON:
                    (context.read<AppConfigurationCubit>().getCategoryMode() ==
                        "1"),
                initialFilters: NewsFilterData(
                  selectedCategories: filterSelectedCategories,
                  selectedTags: filterSelectedTags,
                  selectedDate: filterSelectedDate,
                  durationFilter: filterDurationFilter,
                ),
              );

              if (result != null) {
                setState(() {
                  buildResult = true;
                  isFilterApplied = true;
                  filterSelectedCategories = result.selectedCategories;
                  filterSelectedTags = result.selectedTags;
                  filterSelectedDate = result.selectedDate;
                  filterDurationFilter = result.durationFilter;
                  applyFilters();
                });
              } else if (result == null) {
                setState(() {
                  buildResult = false;
                  isFilterApplied = false;
                  filterSelectedCategories = [];
                  filterSelectedTags = [];
                  filterSelectedDate = null;
                  filterDurationFilter = null;
                });
              }
            },
            icon: Icon(
              Icons.filter_list,
              color: UiUtils.getColorScheme(context).primaryContainer,
            ))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: appbar(),
      body: _showContent(),
    );
  }

  Widget listItem(int index) {
    if (_controllerList.length < index + 1) {
      _controllerList.add(TextEditingController());
    }
    return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 7.0),
        child: ListTile(
            title: CustomTextLabel(
              text: searchList[index].title!,
              textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: UiUtils.getColorScheme(context).primaryContainer,
                  fontWeight: FontWeight.bold),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: (searchList[index].date != null &&
                    searchList[index].date!.isNotEmpty)
                ? CustomTextLabel(
                    text: UiUtils.convertToAgo(context,
                        DateTime.parse(searchList[index].date ?? ""), 3)!,
                    textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: UiUtils.getColorScheme(context).outline,
                        fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
            leading: ClipRRect(
                borderRadius: BorderRadius.circular(7.0),
                child: CustomNetworkImage(
                    networkImageUrl: searchList[index].image ?? "",
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    isVideo: false)),
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              List<NewsModel> addNewsList = [];
              addNewsList.addAll(searchList);
              addNewsList.removeAt(index);
              UiUtils.showInterstitialAds(context: context);
              Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                "model": searchList[index],
                "newsList": addNewsList,
                "isFromBreak": false,
                "fromShowMore": false
              });
            }));
  }

  Future getSearchNews({bool? isFilter}) async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      try {
        String latitude =
            SettingsLocalDataRepository().getLocationCityValues().first;
        String longitude =
            SettingsLocalDataRepository().getLocationCityValues().last;

        if (notificationisloadmore || (isFilter ?? false)) {
          if (mounted) {
            setState(() {
              notificationisloadmore = false;
              notificationisgettingdata = true;
              if (notificationoffset == 0) {
                searchList = [];
              }
            });
          }

          var parameter = {
            if (query.isNotEmpty) SEARCH: query.trim(),
            LIMIT: "20",
            OFFSET: notificationoffset.toString(),
            LANGUAGE_CODE:
                context.read<AppLocalizationCubit>().state.languageCode,
          };
          if (latitude != "null" && longitude != "null") {
            parameter[LATITUDE] = latitude;
            parameter[LONGITUDE] = longitude;
          }

          // Apply filters if present
          if (filterSelectedCategories.isNotEmpty) {
            parameter[CATEGORY_ID] =
                filterSelectedCategories.map((cat) => cat.id).join(',');
          }
          if (filterSelectedTags.isNotEmpty) {
            parameter[TAG_ID] =
                filterSelectedTags.map((tag) => tag.id).join(',');
          }
          if (filterSelectedDate != null) {
            parameter[DATE] =
                "${filterSelectedDate!.year}-${filterSelectedDate!.month.toString().padLeft(2, '0')}-${filterSelectedDate!.day.toString().padLeft(2, '0')}";
          }
          if (filterDurationFilter != null) {
            ///To map will be called so automatic it will add the parm of selected type
            parameter.addAll(filterDurationFilter!.toMap());
          }

          final result =
              await Api.sendApiRequest(body: parameter, url: Api.getNewsApi);

          //print('>>>res are  $result');
          bool error = result["error"];
          int totalResult = result[DATA][TOTAL];
          notificationisgettingdata = false;
          if (notificationoffset == 0) {
            if (error == false && totalResult > 0) {
              notificationisnodata = false;
            } else {
              notificationisnodata = true;
            }
          }
          if (error == false && totalResult > 0) {
            if (mounted) {
              Future.delayed(
                  Duration.zero,
                  () => setState(() {
                        List mainlist = result[DATA][DATA];
                        if (mainlist.isNotEmpty) {
                          List<NewsModel> items = [];
                          List<NewsModel> allItems = [];
                          items.addAll(mainlist
                              .map((data) => NewsModel.fromJson(data))
                              .toList());
                          allItems.addAll(items);

                          if (query.isNotEmpty &&
                              notificationoffset == 0 &&
                              (isFilter ?? !buildResult)) {
                            NewsModel element = NewsModel(
                                title:
                                    '${UiUtils.getTranslatedLabel(context, 'searchForLbl')} "$query"',
                                image: "",
                                history: false);
                            searchList.insert(0, element);
                            for (int i = 0; i < history.length; i++) {
                              if (history[i].title == query) {
                                searchList.insert(0, history[i]);
                              }
                            }
                          }

                          for (NewsModel item in items) {
                            searchList.where((i) => i.id == item.id).map((obj) {
                              allItems.remove(item);
                              return obj;
                            }).toList();
                          }
                          searchList.addAll(allItems);
                          notificationisloadmore = false;
                          notificationoffset =
                              notificationoffset + limitOfAPIData;
                        } else {
                          notificationisloadmore = false;
                        }
                      }));
            }
          } else {
            notificationisloadmore = false;
            setState(() {});
          }
        }
      } on TimeoutException catch (_) {
        showSnackBar(
            UiUtils.getTranslatedLabel(context, 'somethingMSg'), context);
        setState(() {
          notificationisloadmore = false;
        });
      } catch (e) {
        setState(() {
          notificationisnodata = true;
          notificationisloadmore = false;
        });
      }
    } else {
      setState(() {
        isNetworkAvail = false;
      });
    }
  }

  clearAll() {
    setState(() {
      query = _controller.text;
      notificationoffset = 0;
      notificationisloadmore = true;
      searchList.clear();
    });
  }

  _showContent() {
    if (!isFilterApplied && _controller.text == "") {
      return FutureBuilder<List<String>>(
          future: getHistory(),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final List<String> entities = snapshot.data!;
              final List<NewsModel> itemList = [];
              for (int i = 0; i < entities.length; i++) {
                NewsModel item = NewsModel.history(entities[i]);
                itemList.add(item);
              }
              history.clear();
              history.addAll(itemList);

              return SingleChildScrollView(
                padding: const EdgeInsetsDirectional.only(top: 15.0),
                child: Column(
                  children: [
                    _SuggestionList(
                      textController: _controller,
                      suggestions: itemList,
                      notificationController: notificationcontroller,
                      getProduct: getSearchNews,
                      clearAll: clearAll,
                    ),
                  ],
                ),
              );
            } else {
              return const Column();
            }
          });
    } else if (buildResult) {
      return notificationisnodata
          ? const Center(child: CustomTextLabel(text: 'noNews'))
          : Padding(
              padding: const EdgeInsetsDirectional.only(top: 15.0),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsetsDirectional.only(
                            bottom: 5, start: 10, end: 10, top: 12),
                        controller: notificationcontroller,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: searchList.length,
                        itemBuilder: (context, index) {
                          NewsModel? item;
                          try {
                            item =
                                searchList.isEmpty ? null : searchList[index];
                            if (notificationisloadmore &&
                                index == (searchList.length - 1) &&
                                notificationcontroller!.position.pixels <= 0) {
                              getSearchNews();
                            }
                          } on Exception catch (_) {}
                          return item == null
                              ? const SizedBox.shrink()
                              : listItem(index);
                        }),
                  ),
                  notificationisgettingdata
                      ? const Padding(
                          padding:
                              EdgeInsetsDirectional.only(top: 5, bottom: 5),
                          child: CircularProgressIndicator())
                      : const SizedBox.shrink()
                ],
              ));
    }
    return notificationisnodata
        ? const Center(child: CustomTextLabel(text: 'noNews'))
        : Padding(
            padding: const EdgeInsetsDirectional.only(top: 15.0),
            child: Column(
              children: <Widget>[
                Expanded(
                    child: _SuggestionList(
                        textController: _controller,
                        suggestions: searchList,
                        notificationController: notificationcontroller,
                        getProduct: getSearchNews,
                        clearAll: clearAll)),
                notificationisgettingdata
                    ? const Padding(
                        padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
                        child: CircularProgressIndicator())
                    : const SizedBox.shrink()
              ],
            ));
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList(
      {this.suggestions,
      this.textController,
      this.notificationController,
      this.getProduct,
      this.clearAll});

  final List<NewsModel>? suggestions;
  final TextEditingController? textController;

  final notificationController;
  final Function? getProduct, clearAll;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: suggestions!.length,
      shrinkWrap: true,
      controller: notificationController,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemBuilder: (BuildContext context, int i) {
        final NewsModel suggestion = suggestions![i];

        return ListTile(
            title: CustomTextLabel(
                text: suggestion.title!,
                textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: UiUtils.getColorScheme(context).primaryContainer,
                    fontWeight: FontWeight.bold),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            subtitle: (suggestion.date != null && suggestion.date!.isNotEmpty)
                ? CustomTextLabel(
                    text: UiUtils.convertToAgo(
                        context, DateTime.parse(suggestion.date ?? ""), 3)!,
                    textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: UiUtils.getColorScheme(context).outline,
                        fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
            leading: textController!.text.toString().trim().isEmpty ||
                    suggestion.history!
                ? const Icon(Icons.history)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(7.0),
                    child: suggestion.image == ''
                        ? Image.asset(UiUtils.getPlaceholderPngPath(),
                            height: 50, width: 80)
                        : CustomNetworkImage(
                            networkImageUrl: suggestion.image ?? "",
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            isVideo: false)),
            trailing: SvgPictureWidget(
                assetName: "searchbar_arrow",
                height: 11,
                width: 11,
                fit: BoxFit.contain,
                assetColor: ColorFilter.mode(
                    UiUtils.getColorScheme(context)
                        .primaryContainer
                        .withOpacity(0.7),
                    BlendMode.srcIn)),
            onTap: () async {
              if (suggestion.title!.startsWith(
                  '${UiUtils.getTranslatedLabel(context, 'searchForLbl')} ')) {
                UiUtils.setDynamicListValue(
                    historyListKey, textController!.text.toString().trim());
                buildResult = true;
                clearAll!();
                getProduct!();
              } else if (suggestion.history!) {
                clearAll!();
                buildResult = true;
                textController!.text = suggestion.title!;
                textController!.selection = TextSelection.fromPosition(
                    TextPosition(offset: textController!.text.length));
              } else {
                UiUtils.setDynamicListValue(
                    historyListKey, textController!.text.trim());
                buildResult = false;
                UiUtils.showInterstitialAds(context: context);
                Navigator.of(context).pushNamed(Routes.newsDetails, arguments: {
                  "model": suggestion,
                  "isFromBreak": false,
                  "fromShowMore": false
                });
              }
            });
      },
    );
  }
}
