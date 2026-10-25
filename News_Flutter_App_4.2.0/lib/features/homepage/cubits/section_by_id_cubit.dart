import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/features/news/models/breaking_news_model.dart';
import 'package:news/features/homepage/models/feature_section_model.dart';
import 'package:news/features/news/models/news_model.dart';
import 'package:news/features/rss_feed/models/rss_feed_model.dart';
import 'package:news/features/homepage/repositories/section_by_id/section_by_id_repository.dart';
import 'package:news/core/constants/strings.dart';

abstract class SectionByIdState {}

class SectionByIdInitial extends SectionByIdState {}

class SectionByIdFetchInProgress extends SectionByIdState {}

class SectionByIdFetchSuccess extends SectionByIdState {
  final List<NewsModel> newsModel;
  final List<BreakingNewsModel> breakNewsModel;
  final List<RSSFeedModel> rssFeedModel;
  final int totalCount;
  final String type;
  final bool hasMoreFetchError;
  final bool hasMore;
  final FeatureSectionModel featuredSectionModel;

  SectionByIdFetchSuccess(
      {required this.newsModel,
      required this.breakNewsModel,
      this.rssFeedModel = const [],
      required this.totalCount,
      required this.type,
      required this.hasMore,
      required this.hasMoreFetchError,
      required this.featuredSectionModel});
}

class SectionByIdFetchFailure extends SectionByIdState {
  final String errorMessage;

  SectionByIdFetchFailure(this.errorMessage);
}

class SectionByIdCubit extends Cubit<SectionByIdState> {
  final SectionByIdRepository _sectionByIdRepository;
  final int limitOfFeaturedSectionData = 10;

  SectionByIdCubit(this._sectionByIdRepository) : super(SectionByIdInitial());

  void getSectionById(
      {required String langCode,
      required String sectionId,
      String? latitude,
      String? longitude,
      String? limit,
      String? offset}) async {
    try {
      emit(SectionByIdFetchInProgress());
      final result = await _sectionByIdRepository.getSectionById(
          offset: offset ?? "0",
          limit: limit ?? limitOfFeaturedSectionData.toString(),
          langCode: langCode,
          sectionId: sectionId,
          latitude: latitude,
          longitude: longitude);
      if (!result[ERROR]) {
        final sectionRow = result[DATA][0];
        List<RSSFeedModel> rssSection = sectionRow.newsType == RSS_FEED_NEWS
            ? (sectionRow.rssFeedNews ?? [])
            : [];
        List<NewsModel> newsSection = (sectionRow.newsType == "news" ||
                sectionRow.newsType == "user_choice")
            ? (sectionRow.news ?? [])
            : sectionRow.newsType == "author_news"
                ? (sectionRow.authorNews ?? [])
                : sectionRow.videosType == "news"
                    ? (sectionRow.videos ?? [])
                    : [];
        int totalSections;
        if (sectionRow.newsType == "news" ||
            sectionRow.newsType == "user_choice") {
          totalSections = sectionRow.newsTotal!;
        } else if (sectionRow.newsType == "author_news") {
          totalSections = sectionRow.authorNewsTotal ??
              sectionRow.newsTotal ??
              newsSection.length;
        } else if (sectionRow.newsType == RSS_FEED_NEWS) {
          totalSections = sectionRow.rssFeedTotal ?? rssSection.length;
        } else if (sectionRow.newsType == "breaking_news") {
          totalSections = sectionRow.breakNewsTotal!;
        } else {
          totalSections = sectionRow.videosTotal!;
        }
        List<BreakingNewsModel> brNewsSection =
            sectionRow.newsType == "breaking_news"
                ? (sectionRow.breakNews ?? [])
                : sectionRow.videosType == "breaking_news"
                    ? (sectionRow.breakVideos ?? [])
                    : [];

        bool hasMoreResult;
        if (sectionRow.newsType == RSS_FEED_NEWS) {
          hasMoreResult = rssSection.length < totalSections;
        } else if (sectionRow.newsType! == NEWS ||
            sectionRow.newsType! == AUTHOR_NEWS ||
            sectionRow.videosType == NEWS) {
          hasMoreResult = newsSection.length < totalSections;
        } else {
          hasMoreResult = brNewsSection.length < totalSections;
        }

        emit(SectionByIdFetchSuccess(
          featuredSectionModel: sectionRow,
          newsModel: newsSection,
          breakNewsModel: brNewsSection,
          rssFeedModel: rssSection,
          totalCount: totalSections,
          type: sectionRow.newsType!,
          hasMore: hasMoreResult,
          hasMoreFetchError: false,
        ));
      } else {
        emit(SectionByIdFetchFailure(result[MESSAGE]));
      }
    } catch (e) {
      if (!isClosed)
        emit(SectionByIdFetchFailure(e
            .toString())); //isClosed checked to resolve Bad state issue of Bloc
    }
  }

  bool hasMoreSections() {
    return (state is SectionByIdFetchSuccess)
        ? (state as SectionByIdFetchSuccess).hasMore
        : false;
  }

  void getMoreSectionById(
      {required String langCode,
      required String sectionId,
      String? latitude,
      String? longitude,
      String? limit,
      String? offset}) async {
    final prev = state;
    if (prev is SectionByIdFetchSuccess) {
      try {
        final offset = prev.type == RSS_FEED_NEWS
            ? prev.rssFeedModel.length.toString()
            : prev.newsModel.length.toString();
        final result = await _sectionByIdRepository.getSectionById(
            sectionId: sectionId,
            latitude: latitude,
            longitude: longitude,
            limit: limit ?? limitOfFeaturedSectionData.toString(),
            offset: offset,
            langCode: langCode);
        // State changed while waiting (refresh / another section opened) -
        // this page is stale, so drop it.
        if (!identical(state, prev)) return;
        final row = result[DATA][0];
        List<NewsModel> updatedResults = [...prev.newsModel];
        List<BreakingNewsModel> updatedBrResults = [...prev.breakNewsModel];
        List<RSSFeedModel> updatedRssResults = [...prev.rssFeedModel];

        if (row.newsType! == NEWS ||
            row.newsType! == AUTHOR_NEWS ||
            row.videosType == NEWS) {
          List<NewsModel> newValues =
              (row.newsType == "news" || row.newsType == "user_choice")
                  ? row.news ?? []
                  : row.newsType == "author_news"
                      ? (row.authorNews ?? [])
                      : row.videosType == "news"
                          ? row.videos ?? []
                          : [];
          updatedResults.addAll(newValues);
        } else if (row.newsType! == RSS_FEED_NEWS) {
          updatedRssResults.addAll(row.rssFeedNews ?? []);
        } else {
          List<BreakingNewsModel> newValues = row.newsType == "breaking_news"
              ? row.breakNews ?? []
              : row.videosType == "breaking_news"
                  ? row.breakVideos ?? []
                  : [];
          updatedBrResults.addAll(newValues);
        }

        final moreRow = row;
        int totalCount;
        if (moreRow.newsType == "news" || moreRow.newsType == "user_choice") {
          totalCount = moreRow.newsTotal!;
        } else if (moreRow.newsType == "author_news") {
          totalCount = moreRow.authorNewsTotal ??
              moreRow.newsTotal ??
              updatedResults.length;
        } else if (moreRow.newsType == RSS_FEED_NEWS) {
          totalCount = moreRow.rssFeedTotal ?? updatedRssResults.length;
        } else if (moreRow.newsType == "breaking_news") {
          totalCount = moreRow.breakNewsTotal!;
        } else {
          totalCount = moreRow.videosTotal!;
        }

        bool hasMore;
        if (moreRow.newsType == RSS_FEED_NEWS) {
          hasMore = updatedRssResults.length < totalCount;
        } else if (moreRow.newsType! == NEWS ||
            moreRow.newsType! == AUTHOR_NEWS ||
            moreRow.videosType == NEWS) {
          hasMore = updatedResults.length < totalCount;
        } else {
          hasMore = updatedBrResults.length < totalCount;
        }

        emit(SectionByIdFetchSuccess(
            featuredSectionModel: row,
            newsModel: updatedResults,
            breakNewsModel: updatedBrResults,
            rssFeedModel: updatedRssResults,
            type: row.newsType!,
            totalCount: totalCount,
            hasMoreFetchError: false,
            hasMore: hasMore));
      } catch (e) {
        //print("error in loading more featured sections ${e.toString()}");
        if (!identical(state, prev)) return;
        emit(SectionByIdFetchSuccess(
            featuredSectionModel: prev.featuredSectionModel,
            type: prev.type,
            breakNewsModel: prev.breakNewsModel,
            newsModel: prev.newsModel,
            rssFeedModel: prev.rssFeedModel,
            hasMoreFetchError: (e.toString() == "No Data Found") ? false : true,
            totalCount: prev.totalCount,
            hasMore: prev.hasMore));
      }
    }
  }
}
