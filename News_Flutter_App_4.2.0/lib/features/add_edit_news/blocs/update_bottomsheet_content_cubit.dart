import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/news/models/tag_model.dart';
import 'package:news/features/language/models/app_language_model.dart';
import 'package:news/features/homepage/models/location_city_model.dart';

abstract class BottomSheetEvent {}

class UpdateBottomSheetContent extends BottomSheetEvent {
  final List<LocationCityModel> newData;
  final List<TagModel> newTagsData;
  final List<TagModel> newLanguagesData;

  UpdateBottomSheetContent(
      this.newData, this.newTagsData, this.newLanguagesData);
}

// Define the state for your bottom sheet Cubit
class BottomSheetState {
  final List<LocationCityModel> locationData;
  final List<TagModel> tagsData;
  final List<LanguageModel> languageData;
  final List<CategoryModel> categoryData;

  BottomSheetState(
      this.locationData, this.tagsData, this.languageData, this.categoryData);
}

// Define the Cubit itself
class BottomSheetCubit extends Cubit<BottomSheetState> {
  BottomSheetCubit() : super(BottomSheetState([], [], [], []));
  // Access the data field within the cubit

  List<LocationCityModel> currentLocationData = [];
  List<TagModel> currentTagData = [];
  List<LanguageModel> currentLanguageData = [];
  List<CategoryModel> currentCategoryData = [];

  getAllLatestContent(
      {required bool isTag,
      required bool isLocation,
      required bool isLanguage,
      required bool isCategory}) {
    if (!isLocation) currentLocationData = state.locationData;
    if (!isTag) currentTagData = state.tagsData;
    if (!isLanguage) currentLanguageData = state.languageData;
    if (!isCategory) currentCategoryData = state.categoryData;
  }

  void updateLocationContent(List<LocationCityModel> newData) {
    getAllLatestContent(
        isTag: false, isLocation: true, isLanguage: false, isCategory: false);
    emit(BottomSheetState(
        newData, currentTagData, currentLanguageData, currentCategoryData));
  }

  void updateTagsContent(List<TagModel> newTagsData) {
    getAllLatestContent(
        isTag: true, isLocation: false, isLanguage: false, isCategory: false);
    emit(BottomSheetState(currentLocationData, newTagsData, currentLanguageData,
        currentCategoryData));
  }

  void updateLanguageContent(List<LanguageModel> newLanguagesData) {
    getAllLatestContent(
        isTag: false, isLocation: false, isLanguage: true, isCategory: false);
    emit(BottomSheetState(currentLocationData, currentTagData, newLanguagesData,
        currentCategoryData));
  }

  void updateCategoryContent(List<CategoryModel> newCategoryData) {
    getAllLatestContent(
        isTag: false, isLocation: false, isLanguage: false, isCategory: true);
    emit(BottomSheetState(currentLocationData, currentTagData,
        currentLanguageData, newCategoryData));
  }
}
