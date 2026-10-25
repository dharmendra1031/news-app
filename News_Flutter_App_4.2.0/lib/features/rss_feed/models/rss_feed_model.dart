import 'package:news/features/category/models/category_model.dart';
import 'package:news/core/constants/strings.dart';

class RSSFeedModel {
  String? id,
      feedName,
      feedUrl,
      categoryId,
      subCatId,
      categoryName,
      subCatName,
      tagName,
      image,
      description,
      date,
      pubDate,
      pubDateHuman,
      author;

  RSSFeedModel(
      {this.id,
      this.feedName,
      this.feedUrl,
      this.categoryId,
      this.subCatId,
      this.tagName,
      this.categoryName,
      this.subCatName,
      this.image,
      this.description,
      this.date,
      this.pubDate,
      this.pubDateHuman,
      this.author});

  factory RSSFeedModel.fromJson(Map<String, dynamic> json) {
    String? tagName;
    Map<String, dynamic> sourceJson =
        (json.containsKey('source')) ? json['source'] : json;
    //SourceJson for rss_feed_item response, json for get_rss_feed response

    tagName = (!sourceJson.containsKey(TAG) || sourceJson[TAG] == null)
        ? ""
        : sourceJson[TAG];
    CategoryModel? sourceCategoryModel;
    SubCategoryModel? sourceSubcategoryModel;

    var categoryName = (sourceJson.containsKey(CATEGORY_NAME))
        ? sourceJson[CATEGORY_NAME]
        : (sourceJson.containsKey(CATEGORY) && (sourceJson[CATEGORY] != null))
            ? (sourceCategoryModel =
                    CategoryModel.fromJson(sourceJson[CATEGORY]))
                .categoryName
            : '';
    var subcategoryName = (sourceJson.containsKey(SUBCAT_NAME))
        ? sourceJson[SUBCAT_NAME]
        : ((sourceJson.containsKey(SUBCATEGORY) &&
                sourceJson[SUBCATEGORY] != null)
            ? (sourceSubcategoryModel =
                    SubCategoryModel.fromJson(sourceJson[SUBCATEGORY]))
                .subCatName
            : '');

    return RSSFeedModel(
      id: json[ID].toString(),
      feedName: (json.containsKey(TITLE))
          ? json[TITLE]?.toString()
          : sourceJson[FEED_NAME]?.toString() ?? '',
      feedUrl: (json.containsKey(URL))
          ? json[URL]
          : sourceJson[FEED_URL] ?? json[LINK] ?? '',
      categoryId: sourceCategoryModel?.id ??
          (sourceSubcategoryModel?.categoryId?.toString()),
      subCatId: sourceSubcategoryModel?.id,
      tagName: tagName,
      categoryName: categoryName,
      subCatName: subcategoryName,
      image: json['image_url'] ??
          json[IMAGE] ??
          json['image'] ??
          json['url'] ??
          '',
      description: json[DESCRIPTION] ?? json['description'] ?? '',
      date: json[DATE] ?? json['date'] ?? '',
      pubDate:
          json['pubDate'] ?? json[PUBLISHED_AT] ?? json[PUBLISHED_DATE] ?? '',
      pubDateHuman: json[PUBLISHED_AT_HUMAN] ?? '',
      author: json[AUTHOR] ?? '',
    );
  }
}
