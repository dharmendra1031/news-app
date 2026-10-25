import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/core/configs/app_config.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/category/repositories/category_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryFetchInProgress extends CategoryState {}

class CategoryFetchSuccess extends CategoryState {
  final List<CategoryModel> category;
  final int totalCategoryCount;
  final bool hasMoreFetchError;
  final bool hasMore;

  CategoryFetchSuccess(
      {required this.category,
      required this.totalCategoryCount,
      required this.hasMoreFetchError,
      required this.hasMore});
}

class CategoryFetchFailure extends CategoryState {
  final String errorMessage;

  CategoryFetchFailure(this.errorMessage);
}

class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository _categoryRepository;

  CategoryCubit(this._categoryRepository) : super(CategoryInitial());

  void getCategory({required String langCode}) async {
    try {
      emit(CategoryFetchInProgress());
      int catLimit = 20;
      final result = await _categoryRepository.getCategory(
          limit: catLimit.toString(), offset: "0", langCode: langCode);
      (!result[ERROR])
          ? emit(CategoryFetchSuccess(
              category: result['Category'],
              totalCategoryCount: result[TOTAL],
              hasMoreFetchError: false,
              hasMore: (result['Category'] as List<CategoryModel>).length <
                  result[TOTAL]))
          : emit(CategoryFetchFailure(result[MESSAGE]));
    } catch (e) {
      emit(CategoryFetchFailure(e.toString()));
    }
  }

  // Load categories if not already loaded or failed
  void loadIfFailed({required String langCode}) {
    if (state is CategoryInitial || state is CategoryFetchFailure) {
      getCategory(langCode: langCode);
    }
  }

  bool hasMoreCategory() {
    return (state is CategoryFetchSuccess)
        ? (state as CategoryFetchSuccess).hasMore
        : false;
  }

  void getMoreCategory({required String langCode}) async {
    if (state is CategoryFetchSuccess) {
      try {
        final result = await _categoryRepository.getCategory(
            limit: limitOfAPIData.toString(),
            langCode: langCode,
            offset: (state as CategoryFetchSuccess).category.length.toString());
        if (!result[ERROR]) {
          List<CategoryModel> updatedResults =
              (state as CategoryFetchSuccess).category;
          updatedResults.addAll(result['Category'] as List<CategoryModel>);
          emit(CategoryFetchSuccess(
              category: updatedResults,
              totalCategoryCount: result[TOTAL],
              hasMoreFetchError: false,
              hasMore: updatedResults.length < result[TOTAL]));
        } else {
          emit(CategoryFetchFailure(result[MESSAGE]));
        }
      } catch (e) {
        emit(CategoryFetchSuccess(
            category: (state as CategoryFetchSuccess).category,
            hasMoreFetchError: true,
            totalCategoryCount:
                (state as CategoryFetchSuccess).totalCategoryCount,
            hasMore: (state as CategoryFetchSuccess).hasMore));
      }
    }
  }

  List<CategoryModel> getCatList() {
    return (state is CategoryFetchSuccess)
        ? (state as CategoryFetchSuccess).category
        : [];
  }

  int getCategoryIndex({required String categoryName}) {
    return (state is CategoryFetchSuccess)
        ? (state as CategoryFetchSuccess)
            .category
            .indexWhere((element) => element.categoryName == categoryName)
        : 0;
  }
}
