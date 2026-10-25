import 'package:news/core/constants/strings.dart';

class BreakingNewsModel {
  String? id,
      image,
      title,
      desc,
      contentType,
      contentValue,
      totalViews,
      slug,
      date,
      categoryName;
  int? readTime;

  BreakingNewsModel(
      {this.id,
      this.image,
      this.title,
      this.desc,
      this.contentValue,
      this.contentType,
      this.totalViews,
      this.slug,
      this.date,
      this.categoryName,
      this.readTime});

  factory BreakingNewsModel.fromJson(Map<String, dynamic> json) {
    // The category comes either flat (`category_name`) or as a nested
    // `category` object, like on NewsModel; absent for plain breaking news.
    final dynamic category = json[CATEGORY];
    final String? categoryName = json[CATEGORY_NAME]?.toString() ??
        (category is Map ? category[CATEGORY_NAME]?.toString() : null);
    return BreakingNewsModel(
        id: json[ID].toString(),
        image: json[IMAGE],
        title: json[TITLE],
        desc: json[DESCRIPTION] ?? '',
        contentValue: json[CONTENT_VALUE],
        contentType: json[CONTENT_TYPE],
        totalViews: json[TOTAL_VIEWS].toString(),
        slug: json[SLUG],
        // Breaking news has no `date` key; the API sends `created_at`.
        date: json[CREATED_AT]?.toString(),
        categoryName: categoryName,
        readTime: json[READ_TIME] ?? 0);
  }
}
