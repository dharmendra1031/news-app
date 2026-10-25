import 'package:news/core/constants/strings.dart';

class LanguageModel {
  String? id, language, languageDisplayName, image, code;
  int? isRTL;
  LanguageModel(
      {this.id,
      this.image,
      this.language,
      this.languageDisplayName,
      this.code,
      this.isRTL});
  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
        id: json[ID].toString(),
        image: json[IMAGE],
        language: json[LANGUAGE],
        languageDisplayName: (json[DISPLAY_NAME_LANG] != "")
            ? json[DISPLAY_NAME_LANG]
            : json[LANGUAGE],
        code: json[CODE],
        isRTL: (json[ISRTL].runtimeType == int)
            ? json[ISRTL]
            : int.tryParse(json[ISRTL]));
  }
}
