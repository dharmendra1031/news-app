// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/features/add_edit_news/blocs/tag_cubit.dart';
import 'package:news/features/filter/widgets/custom_date_selector.dart';
import 'package:news/features/filter/widgets/duration_filter_widget.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/news/models/tag_model.dart';
import 'package:news/utils/ui_utils.dart';

class NewsFilterData {
  final List<CategoryModel> selectedCategories;
  final List<TagModel> selectedTags;
  final DateTime? selectedDate;
  final DurationFilter? durationFilter;

  NewsFilterData(
      {required this.selectedCategories,
      required this.selectedTags,
      this.selectedDate,
      this.durationFilter});

  @override
  String toString() {
    return 'NewsFilterData(selectedCategories: $selectedCategories, selectedTags: $selectedTags, selectedDate: $selectedDate, durationFilter: $durationFilter)';
  }
}

class FilterBottomSheet extends StatefulWidget {
  final NewsFilterData initialFilters;
  final bool isCategoryModeON;

  const FilterBottomSheet({
    Key? key,
    required this.isCategoryModeON,
    required this.initialFilters,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late final ValueNotifier<int> selectedFilterTabIndex = ValueNotifier(0);
  late List<CategoryModel> selectedCategories;
  late List<TagModel> selectedTags;
  DateTime? selectedDate;

  List<String> filterTabs = [];

  late DurationFilter? durationFilter = widget.initialFilters.durationFilter;
  @override
  void initState() {
    super.initState();
    filterTabs = [if (widget.isCategoryModeON) "catLbl", "tagLbl", "date"];

    selectedCategories = List.from(widget.initialFilters.selectedCategories);
    selectedTags = List.from(widget.initialFilters.selectedTags);
    selectedDate = widget.initialFilters.selectedDate;
  }

  @override
  void dispose() {
    selectedFilterTabIndex.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Dark filter sheet: Border/Default (#363636) instead of the theme's light greys.
  Color? get _dividerColor => _isDark ? darkBorderDefaultColor : null;

  // Dark: solid white box + dark tick when selected, #363636 outline otherwise.
  // Light keeps the shared checkbox.
  Widget _buildCheckbox(bool isSelected) {
    if (!_isDark) {
      return UiUtils.framedShowCheckbox(
          context: context, isSelected: isSelected);
    }
    return Container(
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: isSelected ? secondaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isSelected ? secondaryColor : darkBorderDefaultColor,
          width: 1.2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: darkTextInverseColor, size: 16)
          : null,
    );
  }

  Widget _buildFilterTabItem({required String title, required int index}) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedFilterTabIndex,
      builder: (context, value, child) {
        final isSelected = value == index;
        return InkWell(
          onTap: () {
            selectedFilterTabIndex.value = index;
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: isSelected
                  ? UiUtils.getColorScheme(context).onPrimary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? (_isDark
                        ? secondaryColor
                        : UiUtils.getColorScheme(context).secondary)
                    : (_isDark
                        ? darkBorderDefaultColor
                        : UiUtils.getColorScheme(context).primaryContainer),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? (_isDark
                        ? darkTextInverseColor
                        : UiUtils.getColorScheme(context).surface)
                    : UiUtils.getColorScheme(context).onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryFetchInProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CategoryFetchFailure) {
          return Center(child: Text(state.errorMessage));
        }
        if (state is CategoryFetchSuccess) {
          return NotificationListener(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels ==
                    notification.metrics.maxScrollExtent) {
                  if (context.read<CategoryCubit>().hasMoreCategory()) {
                    context.read<CategoryCubit>().getMoreCategory(
                        langCode: context
                            .read<AppLocalizationCubit>()
                            .state
                            .languageCode);
                  }
                }
              }
              return true;
            },
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: state.category.length,
              itemBuilder: (context, index) {
                final category = state.category[index];
                final isSelected = selectedCategories.contains(category);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  title: Text(
                    category.categoryName ?? "",
                    style: TextStyle(
                      color: UiUtils.getColorScheme(context).onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: _buildCheckbox(isSelected),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedCategories.remove(category);
                      } else {
                        selectedCategories.add(category);
                      }
                    });
                  },
                );
              },
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildTagList() {
    return BlocBuilder<TagCubit, TagState>(
      builder: (context, state) {
        if (state is TagFetchInProgress) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TagFetchFailure) {
          return Center(child: Text(state.errorMessage));
        }
        if (state is TagFetchSuccess) {
          return NotificationListener(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels ==
                    notification.metrics.maxScrollExtent) {
                  if (context.read<TagCubit>().hasMoreTags()) {
                    context.read<TagCubit>().getMoreTags(
                        langCode: context
                            .read<AppLocalizationCubit>()
                            .state
                            .languageCode);
                  }
                }
              }
              return true;
            },
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: state.tag.length,
              itemBuilder: (context, index) {
                final tag = state.tag[index];
                final isSelected = selectedTags.contains(tag);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  title: Text(
                    tag.tagName ?? "",
                    style: TextStyle(
                      color: UiUtils.getColorScheme(context).onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: _buildCheckbox(isSelected),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedTags.remove(tag);
                      } else {
                        selectedTags.add(tag);
                      }
                    });
                  },
                );
              },
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCalendarView(
              selectedDate: selectedDate,
              onDateSelected: (day) {
                selectedDate = day;
                setState(() {});
              },
            ),
            Divider(thickness: 2, color: _dividerColor),
            DurationFilterWidget(
              selectedFilter: durationFilter,
              // FIGMA(2250-9456): the Date presets match the design exactly -
              // Today, Last 7 / 30 / 90 days (the design has NO "Last 60 days"),
              // followed by the current year + 4 previous years (5 years total,
              // e.g. 2025..2021 in the design).
              filters: [
                LastDays(daysCount: 1),
                LastDays(daysCount: 7),
                LastDays(daysCount: 30),
                LastDays(daysCount: 90),
                ...List.generate(
                  5,
                  (int index) {
                    return Year(year: DateTime.now().year - index);
                  },
                ),
              ],
              onSelected: (DurationFilter? filter) {
                durationFilter = filter;
                setState(() {});
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    return ValueListenableBuilder<int>(
      valueListenable: selectedFilterTabIndex,
      builder: (context, selectedIndex, _) {
        final views = widget.isCategoryModeON
            ? [_buildCategoryList(), _buildTagList(), _buildDatePicker()]
            : [_buildTagList(), _buildDatePicker()];
        return views[selectedIndex];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('>>>durationFilter $durationFilter');
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            UiUtils.getTranslatedLabel(context, "filter"),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: UiUtils.getColorScheme(context).onPrimary,
            ),
          ),
          Divider(thickness: 2, color: _dividerColor),
          // const SizedBox(height: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: filterTabs
                          .asMap()
                          .entries
                          .map((entry) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: _buildFilterTabItem(
                                  title: UiUtils.getTranslatedLabel(
                                      context, entry.value),
                                  index: entry.key,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Container(
                  width: 0.5,
                  color: _isDark ? darkBorderDefaultColor : Colors.grey[300],
                  // height: MediaQuery.of(context).size.height * 0.7,
                ),
                Expanded(
                  flex: 7,
                  child: _buildFilterContent(),
                ),
              ],
            ),
          ),
          // const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategories = <CategoryModel>[];
                        selectedTags = <TagModel>[];
                        selectedDate = null;
                        durationFilter = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                          color: _isDark
                              ? secondaryColor
                              : UiUtils.getColorScheme(context)
                                  .onPrimary
                                  .withAlpha(60)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      UiUtils.getTranslatedLabel(context, 'clear'),
                      style: TextStyle(
                          color: UiUtils.getColorScheme(context).onPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final result = NewsFilterData(
                          selectedCategories: selectedCategories,
                          selectedTags: selectedTags,
                          selectedDate: selectedDate,
                          durationFilter: durationFilter);
                      Navigator.pop(context, result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      UiUtils.getTranslatedLabel(context, 'apply'),
                      style: TextStyle(
                        color: secondaryColor,
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
  }
}

// Function to show the filter bottom sheet
Future<NewsFilterData?> showFilterBottomSheet({
  required BuildContext context,
  required bool isCategoryModeON,
  required NewsFilterData initialFilters,
}) async {
  return await showModalBottomSheet<NewsFilterData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
            isCategoryModeON: isCategoryModeON,
            initialFilters: initialFilters,
          ));
}
