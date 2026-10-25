import 'package:news/core/constants/strings.dart';

class CategoryModel {
  String? id, image, categoryName;
  List<SubCategoryModel>? subData;

  CategoryModel({this.id, this.image, this.categoryName, this.subData});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    var subList =
        (json.containsKey(SUBCATEGORIES)) ? (json[SUBCATEGORIES] as List) : [];
    List<SubCategoryModel> subCatData = [];
    subCatData = (subList.isEmpty)
        ? []
        : subList.map((data) => SubCategoryModel.fromJson(data)).toList();

    return CategoryModel(
        id: json[ID].toString(),
        image: json[IMAGE] ?? "",
        categoryName: json[CATEGORY_NAME],
        subData: subCatData);
  }
}

class SubCategoryModel {
  String? id, categoryId, subCatName;

  SubCategoryModel({this.id, this.categoryId, this.subCatName});

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
        id: json[ID].toString(),
        categoryId: json[CATEGORY_ID].toString(),
        subCatName: json[SUBCAT_NAME] ?? json[SUBCATEGORY]);
  }
}
