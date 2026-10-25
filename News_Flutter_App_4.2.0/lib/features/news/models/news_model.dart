import 'package:news/features/category/models/category_model.dart';
import 'package:news/features/author/models/author_model.dart';
import 'package:news/features/homepage/models/location_city_model.dart';
import 'package:news/core/constants/strings.dart';
import 'package:news/features/news/models/option_model.dart';

class NewsModel {
  String? id,
      userId,
      newsId,
      categoryId,
      title,
      date,
      contentType,
      contentValue,
      image,
      desc,
      categoryName,
      dateSent,
      totalLikes,
      like,
      shortDesc;
  String? bookmark,
      keyName,
      tagId,
      tagName,
      subCatId,
      img,
      subCatName,
      showTill,
      langId,
      langCode,
      totalViews,
      locationId,
      locationName,
      metaKeyword,
      metaTitle,
      metaDescription,
      slug,
      publishDate;
  List<ImageDataModel>? imageDataList;

  bool? history = false;
  String? question, status, type, sourceType;
  List<OptionModel>? optionDataList;
  int? from, isExpired, isCommentEnabled, readTime;

  /// Number of comments on the article. Only get_authors_news sends this (as
  /// the `comments` list); everywhere else it stays null.
  int? commentsCount;
  Author? authorDetails;
  UserAuthorModel? userAthorDetails;
  bool? isShortNews = false;

  NewsModel(
      {this.id,
      this.userId,
      this.newsId,
      this.categoryId,
      this.title,
      this.date,
      this.contentType,
      this.contentValue,
      this.image,
      this.desc,
      this.categoryName,
      this.dateSent,
      this.imageDataList,
      this.totalLikes,
      this.like,
      this.keyName,
      this.tagName,
      this.subCatId,
      this.tagId,
      this.history,
      this.optionDataList,
      this.question,
      this.status,
      this.type,
      this.from,
      this.img,
      this.subCatName,
      this.showTill,
      this.bookmark,
      this.langId,
      this.langCode,
      this.totalViews,
      this.locationId,
      this.locationName,
      this.metaTitle,
      this.metaDescription,
      this.metaKeyword,
      this.slug,
      this.publishDate,
      this.isExpired,
      this.isCommentEnabled,
      this.sourceType,
      this.shortDesc,
      this.authorDetails,
      this.userAthorDetails,
      this.isShortNews,
      this.commentsCount,
      this.readTime});

  factory NewsModel.history(String history) {
    return NewsModel(title: history, history: true);
  }

  factory NewsModel.fromSurvey(Map<String, dynamic> json) {
    List<OptionModel> optionList = (json[OPTION] as List)
        .map((data) => OptionModel.fromJson(data))
        .toList();

    return NewsModel(
        id: json[ID].toString(),
        question: json[QUESTION],
        status: json[STATUS].toString(),
        optionDataList: optionList,
        type: "survey",
        from: 1);
  }

  factory NewsModel.fromVideos(Map<String, dynamic> json) {
    String? tagName;

    tagName = (json[TAG] == null) ? "" : json[TAG];
    return NewsModel(
        id: json[ID].toString(),
        newsId: json[ID].toString(),
        //for bookmark get/set
        desc: json[DESCRIPTION] ?? '',
        date: json[DATE],
        image: json[IMAGE],
        title: json[TITLE],
        contentType: json[CONTENT_TYPE],
        contentValue: json[CONTENT_VALUE],
        tagId: json[TAG_ID],
        tagName: tagName,
        categoryName: json[CATEGORY_NAME] ?? '',
        sourceType: json[SOURCE_TYPE],
        shortDesc: json[SUMM_DESCRIPTION] ?? '',
        slug: json[SLUG] ?? "",
        like: json[LIKE]?.toString(),
        totalLikes: json[TOTAL_LIKE]?.toString(),
        totalViews: (json[TOTAL_VIEWS] ?? json[NEWSVIEW_COUNT])?.toString(),
        publishDate: json[PUBLISHED_DATE],
        // Same `user` object fromJson reads; absent for videos unless the
        // API sends it, in which case the card shows the author name.
        userAthorDetails: (json[USER] is Map<String, dynamic>)
            ? UserAuthorModel.fromJson(json[USER])
            : null);
  }

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    String? tagName;

    tagName = (json[TAG] == null) ? "" : json[TAG];

    List<ImageDataModel> imageData = [];
    var imageList = (json.containsKey(IMAGES))
        ? json[IMAGES] as List<dynamic>
        : (json.containsKey(IMAGE_DATA))
            ? json[IMAGE_DATA] as List
            : [];
    imageList = (imageList.isEmpty)
        ? []
        : imageList.map((data) => ImageDataModel.fromJson(data)).toList();
    if (imageList.isNotEmpty) imageData = imageList as List<ImageDataModel>;
    var categoryName = '';
    try {
      categoryName = (json.containsKey(CATEGORY_NAME))
          ? json[CATEGORY_NAME]
          : (json.containsKey(CATEGORY))
              ? CategoryModel.fromJson(json[CATEGORY]).categoryName
              : '';
    } catch (e) {}

    var subcategoryName = (json.containsKey(SUBCAT_NAME))
        ? json[SUBCAT_NAME]
        : ((json.containsKey(SUBCATEGORY) && json[SUBCATEGORY] != null)
            ? SubCategoryModel.fromJson(json[SUBCATEGORY]).subCatName
            : '');

    var locationId = json[LOCATION_ID].toString();
    var locationName = json[LOCATION_NAME];
    try {
      if (json.containsKey(LOCATION) && json[LOCATION] != null) {
        final locationModel = LocationCityModel.fromJson(json[LOCATION]);
        locationId = locationModel.id.toString();
        locationName = locationModel.locationName;
      }
    } catch (e) {}

    return NewsModel(
        id: json[ID].toString(),
        userId: json[USER_ID].toString(),
        newsId: (json[NEWS_ID] != null &&
                json[NEWS_ID].toString().trim().isNotEmpty)
            ? json[NEWS_ID].toString()
            : json[ID].toString(),
        //incase of null newsId in Response
        categoryId: json[CATEGORY_ID].toString(),
        title: json[TITLE],
        date: json[DATE],
        contentType: json[CONTENT_TYPE],
        contentValue: json[CONTENT_VALUE],
        image: json[IMAGE],
        desc: json[DESCRIPTION] ?? '',
        categoryName: categoryName,
        dateSent: json[DATE_SENT],
        imageDataList: imageData,
        totalLikes: json[TOTAL_LIKE].toString(),
        like: json[LIKE].toString(),
        bookmark: json[BOOKMARK].toString(),
        tagId: json[TAG_ID],
        tagName: tagName,
        subCatId: json[SUBCAT_ID].toString(),
        history: false,
        type: "news",
        img: "",
        subCatName: subcategoryName,
        showTill: json[SHOW_TILL],
        langId: json[LANGUAGE_ID].toString(),
        langCode: json[LANGUAGE_CODE].toString(),
        // get_authors_news names the view count `newsview_count` instead of
        // `total_views`, so fall back to it before giving up.
        totalViews: (json[TOTAL_VIEWS] ?? json[NEWSVIEW_COUNT])?.toString(),
        locationId: locationId,
        locationName: locationName,
        metaKeyword: json[META_KEYWORD],
        metaTitle: json[META_TITLE],
        metaDescription: json[META_DESC],
        slug: json[SLUG],
        publishDate: json[PUBLISHED_DATE],
        isExpired: json[IS_EXPIRED] ?? 0,
        status: json[STATUS].toString(),
        isCommentEnabled: json[IS_COMMENT_ENABLED] ?? 1,
        shortDesc: json[SUMM_DESCRIPTION] ?? '',
        isShortNews: json[IS_SHORT_NEWS] == 1,
        userAthorDetails:
            (json[USER] == null) ? null : UserAuthorModel.fromJson(json[USER]),
        // `author` (bio/links) and `user` (name/profile) are independent in the
        // response: the backend can send one without the other, so parse the
        // author record whenever it is there instead of gating it on
        // user.is_author, which silently dropped it.
        authorDetails: (json[AUTHOR] is Map<String, dynamic>)
            ? Author.fromJson(json[AUTHOR])
            : null,
        commentsCount: (json[COMMENTS] is List) ? json[COMMENTS].length : null,
        readTime: json[READ_TIME] ?? 0);
  }
}

class ImageDataModel {
  String? id;
  String? otherImage;

  ImageDataModel({this.otherImage, this.id});

  factory ImageDataModel.fromJson(Map<String, dynamic> json) {
    return ImageDataModel(
        otherImage: json[OTHER_IMAGE], id: json[ID].toString());
  }
}

class UserAuthorModel {
  String? id;
  String? name;
  String? profile;
  int? isAuthor;
  Author? authorData;

  UserAuthorModel(
      {this.id, this.name, this.profile, this.isAuthor, this.authorData});

  factory UserAuthorModel.fromJson(Map<String, dynamic> json) {
    return UserAuthorModel(
        id: json[ID].toString(),
        name: json[NAME],
        profile: json[PROFILE]?.toString(),
        isAuthor: json[IS_AUTHOR] ?? 0,
        authorData: (json.containsKey(AUTHOR) && json[AUTHOR] != null)
            ? Author.fromJson(json[AUTHOR])
            : null);
  }
}
