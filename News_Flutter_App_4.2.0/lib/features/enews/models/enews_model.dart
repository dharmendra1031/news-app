class ENewsModel {
  final int id;
  final int languageId;
  final String title;
  final String slug;
  final String? description;
  final String? thumbnail;
  final String? attachment;
  final String? date;
  final String? metaKeyword;
  final String? metaTitle;
  final String? metaDescription;
  final String? schemaMarkup;
  final int status;

  ENewsModel({
    required this.id,
    required this.languageId,
    required this.title,
    required this.slug,
    this.description,
    this.thumbnail,
    this.attachment,
    this.date,
    this.metaKeyword,
    this.metaTitle,
    this.metaDescription,
    this.schemaMarkup,
    required this.status,
  });

  factory ENewsModel.fromJson(Map<String, dynamic> json) {
    return ENewsModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      languageId: json['language_id'] is int ? json['language_id'] : int.tryParse(json['language_id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      attachment: json['attachment']?.toString(),
      date: json['date']?.toString(),
      metaKeyword: json['meta_keyword']?.toString(),
      metaTitle: json['meta_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
      schemaMarkup: json['schema_markup']?.toString(),
      status: json['status'] is int ? json['status'] : int.tryParse(json['status'].toString()) ?? 1,
    );
  }
}
