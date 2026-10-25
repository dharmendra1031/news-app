import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:news/utils/ui_utils.dart';

class Validators {
  //name validation check
  static String? nameValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'nameRequired');
    }
    if (value.length <= 1) {
      return UiUtils.getTranslatedLabel(context, 'nameLength');
    }
    return null;
  }

//email validation check
  static String? emailValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'emailRequired');
    } else if (!RegExp(
            r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)"
            r"*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+"
            r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
        .hasMatch(value)) {
      return UiUtils.getTranslatedLabel(context, 'emailValid');
    } else {
      return null;
    }
  }

//password validation check
  static String? passValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'pwdRequired');
    } else if (value.length <= 5) {
      return UiUtils.getTranslatedLabel(context, 'pwdLength');
    } else {
      return null;
    }
  }

  static String? mobValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'mblRequired');
    }
    if (value.length < 9 || value.length > 16) {
      return UiUtils.getTranslatedLabel(context, 'mblValid');
    }
    return null;
  }

  static String? titleValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'newsTitleReqLbl');
    } else if (value.length < 2) {
      return UiUtils.getTranslatedLabel(context, 'plzAddValidTitleLbl');
    }
    return null;
  }

  static String? youtubeUrlValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'urlReqLbl');
    } else {
      bool isValidURL = RegExp(
              r'^(((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?)')
          .hasMatch(value);
      if (!isValidURL)
        return UiUtils.getTranslatedLabel(context, 'plzValidUrlLbl');
    }

    return null;
  }

  static String? urlValidation(String value, BuildContext context) {
    bool? test;
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'urlReqLbl');
    } else {
      validUrl(value).then((result) {
        test = result;
        if (test!) {
          return UiUtils.getTranslatedLabel(context, 'plzValidUrlLbl');
        }
      });
    }

    return null;
  }

  static Future<bool> validUrl(String value) async {
    await Dio().head(value).then((value) {
      return (value.statusCode == 200) ? false : true;
    });
    return false;
  }

  //name validation check
  static String? emptyFieldValidation(
      String value, String hintText, BuildContext context) {
    if (value.isEmpty) {
      switch (hintText) {
        case 'metaTitleLbl':
          return UiUtils.getTranslatedLabel(context, 'metaTitleRequired');
        case 'metaDescriptionLbl':
          return UiUtils.getTranslatedLabel(context, 'metaDescriptionRequired');
        case 'metaKeywordLbl':
          return UiUtils.getTranslatedLabel(context, 'metaKeywordRequired');
      }
    }
    return null;
  }

  static String generateSlug(String title) {
    return _foldToAscii(title.toLowerCase())
        .replaceAll(RegExp("['’`]"), '')
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static const Map<String, String> _asciiForAccents = {
    'a': 'àáâãäåāăą',
    'c': 'çćĉċč',
    'd': 'ďđ',
    'e': 'èéêëēĕėęě',
    'g': 'ĝğġģ',
    'h': 'ĥħ',
    'i': 'ìíîïĩīĭįı',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľł',
    'n': 'ñńņň',
    'o': 'òóôõöøōŏő',
    'r': 'ŕŗř',
    's': 'śŝşš',
    't': 'ţťŧ',
    'u': 'ùúûüũūŭůűų',
    'w': 'ŵ',
    'y': 'ýÿŷ',
    'z': 'źżž',
    'ae': 'æ',
    'oe': 'œ',
    'ss': 'ß',
  };

  /// [_asciiForAccents] turned around into one lookup per accented letter, built
  /// once instead of on every keystroke.
  static final Map<String, String> _asciiByAccent = {
    for (final MapEntry<String, String> entry in _asciiForAccents.entries)
      for (final String accented in entry.value.split('')) accented: entry.key
  };

  static String _foldToAscii(String text) {
    final StringBuffer folded = StringBuffer();
    for (final String character in text.split('')) {
      folded.write(_asciiByAccent[character] ?? character);
    }
    return folded.toString();
  }

  static String? slugValidation(String value, BuildContext context) {
    if (value.isEmpty) {
      return UiUtils.getTranslatedLabel(context, 'slugRequired');
    } else if (!RegExp("^[a-z0-9]+(?:-[a-z0-9]+)*").hasMatch(value)) {
      return UiUtils.getTranslatedLabel(context, 'slugValid');
    } else {
      return null;
    }
  }
}
