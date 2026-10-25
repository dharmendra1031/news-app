import 'package:news/core/constants/strings.dart';

class NotificationModel {
  String? id, image, message, dateSent, title, newsId, type, date;
  bool isReadMore;

  NotificationModel(
      {this.id,
      this.image,
      this.message,
      this.title,
      this.dateSent,
      this.newsId,
      this.type,
      this.date,
      this.isReadMore = false});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
        id: json[ID].toString(),
        image: json[IMAGE],
        message: json[MESSAGE],
        dateSent: json[DATE_SENT],
        newsId: json[NEWS_ID].toString(),
        title: json[TITLE],
        type: json[TYPE],
        date: json[DATE],
        isReadMore: false);
  }
}
