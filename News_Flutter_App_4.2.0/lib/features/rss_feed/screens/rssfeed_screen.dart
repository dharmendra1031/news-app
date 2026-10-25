import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/rss_feed/cubits/get_rss_feeds_cubit.dart';
import 'package:news/features/rss_feed/cubits/rss_feed_cubit.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/commons/widgets/network_image.dart';

import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/features/dashboard/widgets/app_bottom_nav_bar.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/core/constants/hive_box_keys.dart';
import 'package:news/core/error_handler/internet_connectivity.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class RSSFeedScreen extends StatefulWidget {
  @override
  RSSFeedScreenState createState() => RSSFeedScreenState();
}

class RSSFeedScreenState extends State<RSSFeedScreen> {
  late final ScrollController _controller = ScrollController()
    ..addListener(hasMoreRssFeedScrollListener);
  // Selected filters
  final List<String> _selectedCategoryIds = [];
  final List<String> _selectedSubcategoryIds = [];
  final List<String> _selectedSourceIds = [];

  bool isFilter = true;
  GetRssFeedsState? _previousState;
  // Track if API call is internal (with filters) vs external (without filters)
  bool _isInternalApiCall = false;

  @override
  void initState() {
    super.initState();
    _previousState = context.read<GetRssFeedsCubit>().state;
    // Only fetch if state is initial or empty, otherwise use existing data
    final currentState = context.read<GetRssFeedsCubit>().state;
    if (currentState is GetRssFeedsInitial ||
        (currentState is GetRssFeedsFetchSuccess &&
            currentState.rssFeeds.isEmpty)) {
      getRSSFeed();
    }
  }

  setAppBar() {
    return PreferredSize(
        preferredSize: const Size(double.infinity, 52),
        child: UiUtils.applyBoxShadow(
            context: context,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                  top: MediaQuery.of(context).padding.top + 10.0,
                  start: 25,
                  end: 25,
                  bottom: 15),
              child: Row(children: [
                CustomTextLabel(
                  text: 'rssFeed',
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
                Spacer(),
                GestureDetector(
                    child: Icon(Icons.filter_list_rounded),
                    onTap: () => setCategorySubcategoryFilter(context))
              ]),
            )));
  }

  setCategorySubcategoryFilter(BuildContext context) {
    showModalBottomSheet<dynamic>(
        context: context,
        elevation: 5.0,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (BuildContext context) {
          int selectedTabIndex = 0;
          // Initialize from current applied filters so checkmarks persist when sheet is reopened
          final tempSelectedCategoryIds =
              _selectedCategoryIds.map((e) => e.toString()).toList();
          final tempSelectedSubcategoryIds =
              _selectedSubcategoryIds.map((e) => e.toString()).toList();
          final tempSelectedSourceIds =
              _selectedSourceIds.map((e) => e.toString()).toList();

          // Ensure RSS sources are loaded for Feeds list
          final rssState = context.read<RSSFeedCubit>().state;
          if (rssState is RSSFeedInitial) {
            context.read<RSSFeedCubit>().getRSSFeed(
                  langCode:
                      context.read<AppLocalizationCubit>().state.languageCode,
                );
          }

          return StatefulBuilder(builder: (BuildContext context,
              void Function(void Function()) setBSState) {
            Widget buildCategoryTab() {
              return BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryFetchInProgress) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CategoryFetchFailure) {
                    return Center(child: Text(state.errorMessage));
                  }
                  if (state is CategoryFetchSuccess) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          if (notification.metrics.pixels ==
                              notification.metrics.maxScrollExtent) {
                            if (context
                                .read<CategoryCubit>()
                                .hasMoreCategory()) {
                              context.read<CategoryCubit>().getMoreCategory(
                                  langCode: context
                                      .read<AppLocalizationCubit>()
                                      .state
                                      .languageCode);
                            }
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.category.length,
                        itemBuilder: (context, index) {
                          final category = state.category[index];
                          final id = (category.id ?? "").toString();
                          final isSelected =
                              tempSelectedCategoryIds.contains(id);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            title: Text(category.categoryName ?? ""),
                            trailing: UiUtils.framedShowCheckbox(
                              context: context,
                              isSelected: isSelected,
                            ),
                            onTap: () {
                              setBSState(() {
                                if (isSelected) {
                                  tempSelectedCategoryIds.remove(id);
                                } else {
                                  tempSelectedCategoryIds.add(id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            }

            Widget buildSubcategoryTab() {
              return BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  if (state is! CategoryFetchSuccess) {
                    return const SizedBox.shrink();
                  }

                  final List<CategoryModel> categories = state.category;
                  final List<_SubcategoryItem> allSubcats = [];

                  for (final cat in categories) {
                    final catId = cat.id ?? "";
                    if (cat.subData != null) {
                      for (final sub in cat.subData!) {
                        // If no category is selected, include all.
                        // If categories are selected, include subcategories only for those categories.
                        final catIdStr = catId.toString();
                        if (tempSelectedCategoryIds.isEmpty ||
                            tempSelectedCategoryIds.contains(catIdStr)) {
                          allSubcats
                              .add(_SubcategoryItem(catId: catId, sub: sub));
                        }
                      }
                    }
                  }

                  if (allSubcats.isEmpty) {
                    return Center(
                        child: CustomTextLabel(
                            text: ErrorMessageKeys.noDataMessage,
                            textStyle: Theme.of(context).textTheme.bodyMedium));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: allSubcats.length,
                    itemBuilder: (context, index) {
                      final item = allSubcats[index];
                      final id = (item.sub.id ?? "").toString();
                      final isSelected =
                          tempSelectedSubcategoryIds.contains(id);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        title: Text(item.sub.subCatName ?? ""),
                        trailing: UiUtils.framedShowCheckbox(
                          context: context,
                          isSelected: isSelected,
                        ),
                        onTap: () {
                          setBSState(() {
                            if (isSelected) {
                              tempSelectedSubcategoryIds.remove(id);
                            } else {
                              tempSelectedSubcategoryIds.add(id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              );
            }

            Widget buildFeedsTab() {
              return BlocBuilder<RSSFeedCubit, RSSFeedState>(
                builder: (context, state) {
                  if (state is RSSFeedFetchInProgress ||
                      state is RSSFeedInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is RSSFeedFetchFailure) {
                    return Center(child: Text(state.errorMessage));
                  }
                  if (state is RSSFeedFetchSuccess) {
                    // Filter feeds based on currently selected categories and subcategories
                    final filteredFeeds = state.RSSFeed.where((feed) {
                      final feedCatId = (feed.categoryId ?? "").toString();
                      final feedSubId = (feed.subCatId ?? "").toString();
                      final catMatch = tempSelectedCategoryIds.isEmpty ||
                          (feed.categoryId != null &&
                              tempSelectedCategoryIds.contains(feedCatId));
                      final subMatch = tempSelectedSubcategoryIds.isEmpty ||
                          (feed.subCatId != null &&
                              tempSelectedSubcategoryIds.contains(feedSubId));
                      return catMatch && subMatch;
                    }).toList();

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          if (notification.metrics.pixels ==
                              notification.metrics.maxScrollExtent) {
                            if (context.read<RSSFeedCubit>().hasMoreRSSFeed()) {
                              context.read<RSSFeedCubit>().getMoreRSSFeed(
                                    langCode: context
                                        .read<AppLocalizationCubit>()
                                        .state
                                        .languageCode,
                                  );
                            }
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredFeeds.length,
                        itemBuilder: (context, index) {
                          final feed = filteredFeeds[index];
                          final id = (feed.id ?? "").toString();
                          final isSelected = tempSelectedSourceIds.contains(id);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            title: Text(feed.feedName ?? ""),
                            trailing: UiUtils.framedShowCheckbox(
                              context: context,
                              isSelected: isSelected,
                            ),
                            onTap: () {
                              setBSState(() {
                                if (isSelected) {
                                  tempSelectedSourceIds.remove(id);
                                } else {
                                  tempSelectedSourceIds.add(id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            }

            Widget buildFilterTabs() {
              final tabs = ["catLbl", "subcatLbl", "feedsLbl"];
              return Column(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () {
                        setBSState(() {
                          selectedTabIndex = index;
                          // When switching tabs, we don't change selection;
                          // sub/feeds lists rebuild based on current temp selections.
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? UiUtils.getColorScheme(context).onPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? UiUtils.getColorScheme(context).secondary
                                : UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.20),
                          ),
                        ),
                        child: Text(
                          UiUtils.getTranslatedLabel(context, tabs[index]),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? UiUtils.getColorScheme(context).surface
                                : UiUtils.getColorScheme(context).onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            }

            Widget buildFilterContent() {
              switch (selectedTabIndex) {
                case 0:
                  return buildCategoryTab();
                case 1:
                  return buildSubcategoryTab();
                case 2:
                  return buildFeedsTab();
              }
              return const SizedBox.shrink();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: UiUtils.getColorScheme(context).surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    UiUtils.getTranslatedLabel(context, "filter"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: UiUtils.getColorScheme(context).onSurface,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildFilterTabs(),
                          ),
                        ),
                        Container(
                          width: 1,
                          color: backgroundColor,
                          height: MediaQuery.of(context).size.height * 0.5,
                        ),
                        Expanded(
                          flex: 7,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: buildFilterContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setBSState(() {
                                tempSelectedCategoryIds.clear();
                                tempSelectedSubcategoryIds.clear();
                                tempSelectedSourceIds.clear();
                                clearFilters();
                                //call API here again without filters
                                getRSSFeed();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Theme.of(context).primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(
                              UiUtils.getTranslatedLabel(context, 'clear'),
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategoryIds
                                  ..clear()
                                  ..addAll(tempSelectedCategoryIds
                                      .map((e) => e.toString()));
                                _selectedSubcategoryIds
                                  ..clear()
                                  ..addAll(tempSelectedSubcategoryIds
                                      .map((e) => e.toString()));
                                _selectedSourceIds
                                  ..clear()
                                  ..addAll(tempSelectedSourceIds
                                      .map((e) => e.toString()));
                              });
                              getRSSFeed();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              UiUtils.getTranslatedLabel(context, 'apply'),
                              style: TextStyle(
                                color:
                                    UiUtils.getColorScheme(context).onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  void clearFilters() {
    setState(() {
      _selectedCategoryIds.clear();
      _selectedSubcategoryIds.clear();
      _selectedSourceIds.clear();
      isFilter = true;
    });
  }

  void getRSSFeed() async {
    if (await InternetConnectivity.isNetworkAvailable()) {
      // Mark as internal call if filters are set
      _isInternalApiCall = _selectedCategoryIds.isNotEmpty ||
          _selectedSubcategoryIds.isNotEmpty ||
          _selectedSourceIds.isNotEmpty;
      Future.delayed(Duration.zero, () {
        context.read<GetRssFeedsCubit>().getRssFeeds(
              languageCode:
                  context.read<AppLocalizationCubit>().state.languageCode,
              sourceIds: _selectedSourceIds,
              categoryIds: _selectedCategoryIds,
              subcategoryIds: _selectedSubcategoryIds,
            );
      });
    }
  }

  void hasMoreRssFeedScrollListener() {
    print("rss-hasMoreRssFeedScrollListener");
    if (_controller.position.maxScrollExtent == _controller.offset) {
      print("rss-scroll position");
      if (context.read<GetRssFeedsCubit>().hasMoreRssFeeds()) {
        print("rss-hasMore feed true & API call");
        context.read<GetRssFeedsCubit>().getMoreRssFeeds(
              languageCode:
                  context.read<AppLocalizationCubit>().state.languageCode,
              sourceIds: _selectedSourceIds,
              categoryIds: _selectedCategoryIds,
              subcategoryIds: _selectedSubcategoryIds,
            );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: setAppBar(),
      body: Padding(
        // FIGMA(790-8812): the card list sits at x=16 in a 390-wide screen,
        // so the horizontal screen padding is 16 (cards are 358 wide).
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: BlocConsumer<GetRssFeedsCubit, GetRssFeedsState>(
          listener: (context, state) {
            // Clear filters if API was called without filters (from CommonSectionTitle)
            // Detect this by checking if state transitioned from initial/in-progress to success
            // and filters are still set locally, but it wasn't an internal call
            if (state is GetRssFeedsFetchSuccess &&
                _previousState != null &&
                (_previousState is GetRssFeedsInitial ||
                    _previousState is GetRssFeedsFetchInProgress) &&
                (_selectedCategoryIds.isNotEmpty ||
                    _selectedSubcategoryIds.isNotEmpty ||
                    _selectedSourceIds.isNotEmpty) &&
                !_isInternalApiCall) {
              // Clear filters since API was called externally without filters
              // clearFilters();
            }
            // Reset the flag after processing
            _isInternalApiCall = false;
            _previousState = state;
          },
          builder: (context, state) {
            print("rss-cubit state- $state");
            if (state is GetRssFeedsFetchSuccess) {
              return RefreshIndicator(
                onRefresh: () async {
                  getRSSFeed();
                },
                child: (state.rssFeeds.isNotEmpty)
                    ? ListView.builder(
                        padding: EdgeInsets.only(
                            // FIGMA: 16px gap below the app bar (8 here + the
                            // card's own 8 vertical margin).
                            top: 8,
                            bottom: AppBottomNavBar.contentClearance(context)),
                        itemCount: state.rssFeeds.length,
                        controller: _controller,
                        itemBuilder: (context, index) {
                          return buildRSSFeedItem(
                              state.rssFeeds[index],
                              index,
                              state.rssFeeds.length,
                              state.hasMoreFetchError,
                              state.hasMore);
                        })
                    : Center(
                        child: ErrorContainerWidget(
                            errorMsg: ErrorMessageKeys.noDataMessage,
                            onRetry: getRSSFeed)),
              );
            } else if (state is GetRssFeedsFetchFailure) {
              return ErrorContainerWidget(
                  errorMsg:
                      (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                          ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                          : state.errorMessage,
                  onRetry: getRSSFeed);
            } else if (state is GetRssFeedsFetchInProgress ||
                state is GetRssFeedsInitial) {
              return Center(
                  child: UiUtils.showCircularProgress(
                      true, Theme.of(context).primaryColor));
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget buildRSSFeedItem(RSSFeedModel feed, int index, int totalCurrentFeeds,
      bool hasMoreFeedsFetchError, bool hasMore) {
    if (index == totalCurrentFeeds - 1 && index != 0) {
      if (hasMore) {
        if (hasMoreFeedsFetchError) {
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
    final humanDate = (feed.pubDateHuman != null &&
            feed.pubDateHuman!.isNotEmpty &&
            feed.pubDateHuman!.contains('hours ago'))
        ? publishedAtHumanBeforeParen(feed.pubDateHuman ?? "")
        : null;
    final displayDate = (feed.pubDate != null && feed.pubDate!.isNotEmpty)
        ? feed.pubDate!
        : (feed.date != null && feed.date!.isNotEmpty ? feed.date! : null);
    // final showAuthor = feed.author != null && feed.author!.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        if (feed.feedUrl != null && feed.feedUrl!.isNotEmpty) {
          final uri = Uri.tryParse(feed.feedUrl!);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          }
          return;
          //  Navigator.of(context).pushNamed(Routes.rssFeedDetails, arguments: {"feedUrl": feed.feedUrl});
        }
      },
      // FIGMA(790-8812 / card 2189-7848): RSS card - white surface, 1px
      // navy@10% border, 8px radius and a 6px outer padding (the right content
      // has its own 6px padding). No heavy shadow - the border defines the
      // card. Cards are 358 wide with a 16px gap (8px vertical margin) between.
      child: Card(
        elevation: 0,
        color: UiUtils.getColorScheme(context).surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: UiUtils.getColorScheme(context)
                  .primaryContainer
                  .withOpacity(0.1)),
        ),
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ((feed.image != null && feed.image!.isNotEmpty))
                      // FIGMA: 118x94 image, 6px radius, cover.
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CustomNetworkImage(
                              networkImageUrl: feed.image!,
                              height: 94,
                              width: 118,
                              fit: BoxFit.fill))
                      : SizedBox.shrink(),
                  Expanded(
                    flex: 1,
                    // FIGMA: content has 6px padding and 4px gaps between the
                    // pill tag, single-line title and 2-line description.
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (feed.categoryName != null &&
                              feed.categoryName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onPrimary,
                                // FIGMA: pill-shaped tag.
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(50)),
                              ),
                              child: CustomTextLabel(
                                text: feed.categoryName!,
                                textStyle: TextStyle(
                                    fontSize: 12,
                                    color: UiUtils.getColorScheme(context)
                                        .secondary,
                                    fontWeight: FontWeight.w400),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 4),
                          // FIGMA: title is a single line, SemiBold, ellipsis.
                          CustomTextLabel(
                            text: feed.feedName ?? 'No Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textStyle: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer),
                          ),
                          const SizedBox(height: 4),
                          if (feed.description != null &&
                              feed.description!.isNotEmpty)
                            CustomTextLabel(
                              text: feed.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textStyle: TextStyle(
                                  color: UiUtils.getColorScheme(context)
                                      .primaryContainer
                                      .withOpacity(0.7),
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (feed.author != null && feed.author!.isNotEmpty ||
                  humanDate != null && humanDate.isNotEmpty ||
                  displayDate != null && displayDate.isNotEmpty) ...[
                // FIGMA: divider then a footer with the source (left) and a
                // clock + relative time (right), all 10px navy@50%.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Divider(
                      height: 1,
                      color: UiUtils.getColorScheme(context)
                          .primaryContainer
                          .withOpacity(0.1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (feed.author != null && feed.author!.isNotEmpty)
                        Expanded(
                          child: CustomTextLabel(
                            text: feed.author ?? "",
                            maxLines: 1,
                            textStyle: TextStyle(
                                fontSize: 10,
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.5),
                                fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        SizedBox.shrink(),
                      if (humanDate != null && humanDate.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.5)),
                            SizedBox(width: 4),
                            Flexible(
                              child: CustomTextLabel(
                                text: humanDate,
                                textStyle: TextStyle(
                                    fontSize: 10,
                                    color: UiUtils.getColorScheme(context)
                                        .primaryContainer
                                        .withOpacity(0.5)),
                              ),
                            ),
                          ],
                        )
                      else if (displayDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPictureWidget(
                                assetName: 'calendar',
                                height: 20,
                                width: 20,
                                assetColor: ColorFilter.mode(
                                    UiUtils.getColorScheme(context)
                                        .primaryContainer,
                                    BlendMode.srcIn)),
                            SizedBox(width: 4),
                            Flexible(
                              child: CustomTextLabel(
                                text: DateFormat(
                                        "dd / MM / yyyy",
                                        Hive.box(settingsBoxKey)
                                            .get(currentLanguageCodeKey))
                                    .format(DateTime.parse(displayDate)),
                                textStyle: TextStyle(
                                    fontSize: 10,
                                    color: UiUtils.getColorScheme(context)
                                        .primaryContainer
                                        .withOpacity(0.5)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String publishedAtHumanBeforeParen(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    final i = s.indexOf('(');
    return (i == -1 ? s : s.substring(0, i)).trim();
  }
}

class _SubcategoryItem {
  final String catId;
  final SubCategoryModel sub;

  _SubcategoryItem({required this.catId, required this.sub});
}
