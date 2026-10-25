import 'package:news/core/constants/strings.dart';

class LiveStreamingModel {
  String? id, image, title, type, url, updatedDate, totalViews;

  LiveStreamingModel(
      {this.id,
      this.image,
      this.title,
      this.type,
      this.url,
      this.updatedDate,
      this.totalViews});

  factory LiveStreamingModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamingModel(
        id: json[ID].toString(),
        image: json[IMAGE],
        title: json[TITLE],
        type: json[TYPE],
        url: json[URL],
        updatedDate: json[UPDATED_DATE],
        // Not every backend build reports viewers for a live stream yet; the
        // Figma "viewer count" tag simply hides itself when this is absent.
        totalViews: json[TOTAL_VIEWS]?.toString());
  }
}
