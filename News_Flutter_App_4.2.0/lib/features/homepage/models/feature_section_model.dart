import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/commons/models/ad_space_model.dart';
import 'package:news/core/constants/strings.dart';

enum NewsType {
  news,
  userChoice,
  rssFeedsNews,
  breakingNews,
  videos,
  authorNews,
  unknown
}

NewsType newsTypeFromString(String? value) {
  switch (value) {
    case 'news':
      return NewsType.news;
    case 'user_choice':
      return NewsType.userChoice;
    case 'rss_feeds_news':
      return NewsType.rssFeedsNews;
    case 'breaking_news':
      return NewsType.breakingNews;
    case 'videos':
      return NewsType.videos;
    case 'author_news':
      return NewsType.authorNews;
    default:
      return NewsType.unknown;
  }
}

String newsTypeToString(NewsType type) {
  switch (type) {
    case NewsType.news:
      return 'news';
    case NewsType.userChoice:
      return 'user_choice';
    case NewsType.rssFeedsNews:
      return 'rss_feeds_news';
    case NewsType.breakingNews:
      return 'breaking_news';
    case NewsType.videos:
      return 'videos';
    case NewsType.authorNews:
      return 'author_news';
    case NewsType.unknown:
      return 'unknown';
  }
}

enum VideoType {
  video_youtube,
  video_upload,
  video_other,
  url_youtube,
  url_other,
  unknown
}

VideoType videoTypeFromString(String? value) {
  switch (value) {
    case 'video_youtube':
      return VideoType.video_youtube;
    case 'video_upload':
      return VideoType.video_upload;
    case 'video_other':
      return VideoType.video_other;
    case 'url_youtube':
      return VideoType.url_youtube;
    case 'url_other':
      return VideoType.url_other;
    default:
      return VideoType.unknown;
  }
}

String videoTypeToString(VideoType type) {
  switch (type) {
    case VideoType.video_youtube:
      return 'video_youtube';
    case VideoType.video_upload:
      return 'video_upload';
    case VideoType.video_other:
      return 'video_other';
    case VideoType.url_youtube:
      return 'url_youtube';
    case VideoType.url_other:
      return 'url_other';
    case VideoType.unknown:
      return 'unknown';
  }
}

class FeatureSectionModel {
  String? id,
      languageId,
      title,
      shortDescription,
      newsType,
      videosType,
      categoryIds,
      subcategoryIds,
      newsIds,
      styleApp,
      createdAt,
      status,
      summarizedDesc;
  int? newsTotal, breakNewsTotal, videosTotal, rssFeedTotal, authorNewsTotal;
  List<NewsModel>? news;
  List<RSSFeedModel>? rssFeedNews;
  List<BreakingNewsModel>? breakNews, breakVideos;
  List<NewsModel>? videos;
  List<NewsModel>? authorNews;
  AdSpaceModel? adSpaceDetails;

  NewsType get newsTypeEnum => newsTypeFromString(newsType);
  NewsType get videosTypeEnum => newsTypeFromString(videosType);

  FeatureSectionModel(
      {this.id,
      this.languageId,
      this.title,
      this.shortDescription,
      this.newsType,
      this.videosType,
      this.categoryIds,
      this.subcategoryIds,
      this.newsIds,
      this.styleApp,
      this.createdAt,
      this.newsTotal,
      this.breakNewsTotal,
      this.videosTotal,
      this.rssFeedTotal,
      this.authorNewsTotal,
      this.news,
      this.breakNews,
      this.videos,
      this.breakVideos,
      this.rssFeedNews,
      this.adSpaceDetails,
      this.summarizedDesc,
      this.authorNews});

  factory FeatureSectionModel.fromJson(Map<String, dynamic> json) {
    List<NewsModel> newsData = [];
    List<RSSFeedModel> rssFeedNewsData = [];
    List<NewsModel> authorNewsData = [];
    if (json.containsKey(NEWS)) {
      var newsList = (json[NEWS] as List);
      if (newsList.isEmpty) {
        newsList = [];
      } else {
        newsData = newsList.map((data) => NewsModel.fromJson(data)).toList();
      }
    } else if (json.containsKey(RSS_FEED_NEWS)) {
      var rssFeedNewsList = (json[RSS_FEED_NEWS] as List);
      if (rssFeedNewsList.isEmpty) {
        rssFeedNewsList = [];
      } else {
        rssFeedNewsData =
            rssFeedNewsList.map((data) => RSSFeedModel.fromJson(data)).toList();
      }
    }
    if (json.containsKey(AUTHOR_NEWS)) {
      var authorNewsList = (json[AUTHOR_NEWS] as List);
      if (authorNewsList.isEmpty) {
        authorNewsList = [];
      } else {
        authorNewsData =
            authorNewsList.map((data) => NewsModel.fromJson(data)).toList();
      }
    }
    List<BreakingNewsModel> breakNewsData = [];
    if (json.containsKey(BREAKING_NEWS)) {
      var breakNewsList = (json[BREAKING_NEWS] as List);
      if (breakNewsList.isEmpty) {
        breakNewsList = [];
      } else {
        breakNewsData = breakNewsList
            .map((data) => BreakingNewsModel.fromJson(data))
            .toList();
      }
    }

    List<NewsModel> videosData = [];
    List<BreakingNewsModel> breakVideosData = [];
    if (json.containsKey(VIDEOS)) {
      var videosList = (json[VIDEOS] as List);
      if (videosList.isEmpty) {
        videosList = [];
      } else {
        if (json[VIDEOS_TYPE] == 'news') {
          videosData =
              videosList.map((data) => NewsModel.fromVideos(data)).toList();
        } else {
          breakVideosData = videosList
              .map((data) => BreakingNewsModel.fromJson(data))
              .toList();
        }
      }
    }
    AdSpaceModel? adSpaceData;
    if (json.containsKey(AD_SPACES)) {
      adSpaceData = AdSpaceModel.fromJson(json[AD_SPACES]);
    }

    return FeatureSectionModel(
        id: json[ID].toString(),
        languageId: json[LANGUAGE_ID].toString(),
        title: json[TITLE],
        shortDescription: json[SHORT_DESC],
        newsType: json[NEWS_TYPE],
        videosType: json[VIDEOS_TYPE],
        categoryIds: json[CAT_IDS],
        subcategoryIds: json[SUBCAT_IDS],
        newsIds: json[NEWS_IDS],
        styleApp: json[STYLE_APP],
        newsTotal: json[NEWS_TOTAL],
        breakNewsTotal: json[BREAK_NEWS_TOTAL],
        videosTotal: json[VIDEOS_TOTAL],
        rssFeedTotal: json[NEWS_TYPE] == 'rss_feeds_news'
            ? (json[RSS_FEED_TOTAL] ?? rssFeedNewsData.length)
            : 0,
        authorNewsTotal: json[AUTHOR_NEWS_TOTAL],
        summarizedDesc: json[SUMM_DESCRIPTION],
        news: newsData,
        breakNews: breakNewsData,
        videos: videosData,
        breakVideos: breakVideosData,
        rssFeedNews:
            json[NEWS_TYPE] == 'rss_feeds_news' ? rssFeedNewsData : null,
        adSpaceDetails: adSpaceData,
        authorNews: authorNewsData);
  }
}
