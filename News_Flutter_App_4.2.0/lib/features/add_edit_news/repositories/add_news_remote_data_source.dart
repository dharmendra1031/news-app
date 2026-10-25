import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:news/utils/ui_utils.dart';
import 'package:news/core/api/api.dart';
import 'package:news/core/constants/strings.dart';

class AddNewsRemoteDataSource {
  //to update fcmId of user's
  Future<dynamic> addNewsData(
      {required BuildContext context,
      required String actionType,
      required String catId,
      required String title,
      required String conTypeId,
      required String conType,
      required String langId,
      required String langCode,
      File? image,
      String? newsId,
      String? subCatId,
      String? showTill,
      String? tagId,
      String? url,
      String? desc,
      String? summDescription,
      String? locationId,
      File? videoUpload,
      List<File>? otherImage,
      String? publishDate,
      required String metaTitle,
      required String metaDescription,
      required String metaKeyword,
      required String slug,
      required int isDraft,
      required int isShortNews}) async {
    try {
      Map<String, dynamic> body = {
        ACTION_TYPE: actionType,
        CATEGORY_ID: catId,
        TITLE: title,
        CONTENT_TYPE: conTypeId,
        // LANGUAGE_ID: langId, // not used in api
        LANGUAGE_CODE: langCode,
        META_TITLE: metaTitle,
        META_DESC: metaDescription,
        META_KEYWORD: metaKeyword,
        SLUG: slug,
        SUMM_DESCRIPTION: summDescription,
        IS_DRAFT_KEY: isDraft,
        IS_SHORT_NEWS: isShortNews,
      };
      Map<String, dynamic> result = {};

      if (image != null) body[IMAGE] = await MultipartFile.fromFile(image.path);
      if (newsId != null) body[NEWS_ID] = newsId; // in case of update news only
      if (subCatId != null) body[SUBCAT_ID] = subCatId;
      if (showTill != null) body[SHOW_TILL] = showTill;
      if (tagId != null) body[TAG_ID] = tagId;
      if (desc != null) body[DESCRIPTION] = desc;
      if (locationId != null) body[LOCATION_ID] = locationId;
      if (publishDate != null) body[PUBLISHED_DATE] = publishDate;

      if (url != null &&
          (conType == UiUtils.getTranslatedLabel(context, 'videoOtherUrlLbl') ||
              conType ==
                  UiUtils.getTranslatedLabel(context, 'videoYoutubeLbl'))) {
        body[CONTENT_DATA] = url;
      } else if (conType ==
          UiUtils.getTranslatedLabel(context, 'videoUploadLbl')) {
        if (videoUpload != null)
          body[CONTENT_DATA] = await MultipartFile.fromFile(videoUpload.path);
      }

      if (otherImage!.isNotEmpty) {
        for (var i = 0; i < otherImage.length; i++) {
          body["ofile[$i]"] = await MultipartFile.fromFile(otherImage[i].path);
        }
      }

      result = await Api.sendApiRequest(body: body, url: Api.setNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
