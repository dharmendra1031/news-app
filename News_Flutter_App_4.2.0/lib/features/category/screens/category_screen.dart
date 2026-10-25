import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/custom_appbar.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/error_container_widget.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/features/category/cubits/category_cubit.dart';
import 'package:news/features/language/cubits/app_localization_cubit.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/core/error_handler/error_message_keys.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/routes/routes.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  CategoryScreenState createState() => CategoryScreenState();
}

class CategoryScreenState extends State<CategoryScreen> {
  late final ScrollController _categoryScrollController = ScrollController()
    ..addListener(hasMoreCategoryScrollListener);

  void getCategory() {
    Future.delayed(Duration.zero, () {
      context.read<CategoryCubit>().getCategory(
          langCode: context.read<AppLocalizationCubit>().state.languageCode);
    });
  }

  @override
  void initState() {
    getCategory();
    super.initState();
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  void hasMoreCategoryScrollListener() {
    if (_categoryScrollController.offset >=
            _categoryScrollController.position.maxScrollExtent &&
        !_categoryScrollController.position.outOfRange) {
      if (context.read<CategoryCubit>().hasMoreCategory()) {
        context.read<CategoryCubit>().getMoreCategory(
            langCode: context.read<AppLocalizationCubit>().state.languageCode);
      } else {
        //debugPrint("No more categories");
      }
    }
  }

  Widget _buildCategory() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryFetchSuccess) {
          return RefreshIndicator(
              onRefresh: () async {
                getCategory();
              },
              child: GridView.count(
                physics: const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                // FIGMA(184-6607): 2-column grid with 16px gutters/padding and a
                // 171:179 (~0.95) card aspect ratio to match the design.
                padding: EdgeInsets.only(
                    top: 16,
                    bottom: MediaQuery.of(context).size.height / 10.0,
                    left: 16,
                    right: 16),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                shrinkWrap: true,
                controller: _categoryScrollController,
                children: List.generate(state.category.length, (index) {
                  return _buildCategoryContainer(
                      category: state.category[index],
                      hasMore: state.hasMore,
                      hasMoreCategoryFetchError: state.hasMoreFetchError,
                      index: index,
                      totalCurrentCategory: state.category.length);
                }),
              ));
        }
        if (state is CategoryFetchFailure) {
          return ErrorContainerWidget(
              errorMsg:
                  (state.errorMessage.contains(ErrorMessageKeys.noInternet))
                      ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                      : state.errorMessage,
              onRetry: getCategory);
        }
        return const SizedBox.shrink();
      },
    );
  }

  _buildCategoryContainer(
      {required CategoryModel category,
      required int index,
      required int totalCurrentCategory,
      required bool hasMoreCategoryFetchError,
      required bool hasMore}) {
    if (index == totalCurrentCategory - 1 && index != 0) {
      if (hasMore) {
        if (hasMoreCategoryFetchError) {
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(Routes.subCat, arguments: {
          "catId": category.id,
          "catName": category.categoryName
        });
      },
      // FIGMA(184-6607): white card with a 1px navy@10% border, 8px radius and
      // 8px inner padding. The image fills the card (BoxFit.cover, 4px radius)
      // with the centered category name (Medium 16) below it.
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: (category.image != null)
                      ? CustomNetworkImage(
                          networkImageUrl: category.image!,
                          height: double.infinity,
                          width: double.infinity,
                          isVideo: false,
                          fit: BoxFit.cover)
                      : const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 4),
              CustomTextLabel(
                  text: category.categoryName!,
                  textStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: UiUtils.getColorScheme(context).primaryContainer),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            height: 45,
            isBackBtn: true,
            label: 'categoryLbl',
            isConvertText: true),
        body: _buildCategory());
  }
}
