// Every podcast API call: this layer only builds request bodies and returns the
// raw response — parsing into models is PodcastRepository's job.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class PodcastRemoteDataSource {
  static const String typeAll = "all";
  static const String typeHistory = "history";
  static const String typeBookmark = "bookmark";

  static const String typeDraft = "draft";

  static const String actionCreate = "1";
  static const String actionUpdate = "2";

  static const String myTypeAll = "all";
  static const String myTypeDraft = "draft";

  Future<dynamic> getPodcasts({
    String? search,
    String type = typeAll,
    String? offset,
    String? limit,
  }) async {
    try {
      final Map<String, dynamic> body = {TYPE: type};
      if (search != null && search.trim().isNotEmpty) body[SEARCH] = search;
      if (offset != null) body[OFFSET] = offset;
      if (limit != null) body[LIMIT] = limit;
      return await Api.sendApiRequest(body: body, url: Api.getPodcastsApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> getEpisodes({
    required String podcastSlug,
    required String offset,
    required String limit,
    String type = typeAll,
    bool isAuthorCheck = false,
  }) async {
    try {
      final body = {
        PODCAST_SLUG: podcastSlug,
        OFFSET: offset,
        LIMIT: limit,
        TYPE: type,
        IS_AUTHOR_CHECK: isAuthorCheck ? "1" : "0",
      };
      return await Api.sendApiRequest(body: body, url: Api.getEpisodesApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> bookmarkEpisode({
    required String podcastId,
    required String episodeId,
    required String status,
  }) async {
    try {
      final body = {
        PODCAST_ID: podcastId,
        EPISODE_ID: episodeId,
        STATUS: status,
      };
      return await Api.sendApiRequest(body: body, url: Api.bookmarkEpisodeApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> updateEpisodeListeningHistory({
    required String episodeId,
    required String listenedSeconds,
    required String completed,
  }) async {
    try {
      final body = {
        EPISODE_ID: episodeId,
        LISTENED_SECONDS: listenedSeconds,
        COMPLETED: completed,
      };
      return await Api.sendApiRequest(
          body: body, url: Api.updateEpisodeListeningHistoryApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> followPodcast({
    required String podcastId,
    required String status,
  }) async {
    try {
      final body = {PODCAST_ID: podcastId, STATUS: status};
      return await Api.sendApiRequest(body: body, url: Api.followPodcastApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> getMyPodcasts({
    String type = myTypeAll,
    String? search,
    String? offset,
    String? limit,
  }) async {
    try {
      final Map<String, dynamic> body = {TYPE: type};
      if (search != null && search.trim().isNotEmpty) body[SEARCH] = search;
      if (offset != null) body[OFFSET] = offset;
      if (limit != null) body[LIMIT] = limit;
      return await Api.sendApiRequest(body: body, url: Api.myPodcastsApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> getMyEpisodes({
    required String type,
    String? search,
    String? offset,
    String? limit,
  }) async {
    try {
      final Map<String, dynamic> body = {TYPE: type};
      if (search != null && search.trim().isNotEmpty) body[SEARCH] = search;
      if (offset != null) body[OFFSET] = offset;
      if (limit != null) body[LIMIT] = limit;
      return await Api.sendApiRequest(body: body, url: Api.myEpisodesApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> savePodcast({
    String? podcastId,
    required String title,
    required String slug,
    required String description,
    required String publishedDate,
    required String draft,
    required String metaTitle,
    required String metaDescription,
    required String metaKeyword,
    required String schemaMarkup,
    File? image,
  }) async {
    try {
      final Map<String, dynamic> body = {
        ACTION_TYPE: (podcastId == null) ? actionCreate : actionUpdate,
        TITLE: title,
        SLUG: slug,
        DESCRIPTION: description,
        PUBLISHED_DATE: publishedDate,
        DRAFT: draft,
        META_TITLE: metaTitle,
        META_DESC: metaDescription,
        META_KEYWORD: metaKeyword,
        SCHEMA_MARKUP: schemaMarkup,
      };
      if (podcastId != null) body[ID] = podcastId;
      if (image != null) body[IMAGE] = await MultipartFile.fromFile(image.path);
      return await Api.sendApiRequest(body: body, url: Api.savePodcastApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> deletePodcast({required String podcastId}) async {
    try {
      return await Api.sendApiRequest(
          body: {ID: podcastId}, url: Api.deletePodcastApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> saveEpisode({
    String? episodeId,
    required String podcastId,
    required String episodeNo,
    required String title,
    required String slug,
    required String description,
    required String publishedDate,
    required String sourceType,
    required String draft,
    String? audioUrl,
    File? audioFile,
    File? image,
  }) async {
    try {
      final Map<String, dynamic> body = {
        ACTION_TYPE: (episodeId == null) ? actionCreate : actionUpdate,
        PODCAST_ID: podcastId,
        EPISODE_NO: episodeNo,
        TITLE: title,
        SLUG: slug,
        DESCRIPTION: description,
        PUBLISHED_DATE: publishedDate,
        SOURCE_TYPE: sourceType,
        IS_DRAFT_KEY: draft,
      };
      if (episodeId != null) body[EPISODE_ID] = episodeId;
      if (audioUrl != null && audioUrl.trim().isNotEmpty) {
        body[AUDIO_URL] = audioUrl.trim();
      }
      if (audioFile != null) {
        body[AUDIO_FILE] = await MultipartFile.fromFile(audioFile.path);
      }
      if (image != null) body[IMAGE] = await MultipartFile.fromFile(image.path);
      return await Api.sendApiRequest(body: body, url: Api.saveEpisodeApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  Future<dynamic> deleteEpisode({required String episodeId}) async {
    try {
      return await Api.sendApiRequest(
          body: {EPISODE_ID: episodeId}, url: Api.deleteEpisodeApi);
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
