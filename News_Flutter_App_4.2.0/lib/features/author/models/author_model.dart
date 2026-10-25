import 'package:news/commons/enums.dart';
import 'package:news/core/constants/strings.dart';

class Author {
  final int? id;
  final int? userId;
  final String? bio;
  final String? telegramLink;
  final String? linkedinLink;
  final String? facebookLink;
  final String? whatsappLink;
  final AuthorStatus? status;

  /// When true (admin toggle on the author's profile), news posted by this
  /// author is auto-published instead of waiting for per-article admin review.
  final bool autoApprove;

  Author({
    this.id,
    this.userId,
    this.bio,
    this.telegramLink,
    this.linkedinLink,
    this.facebookLink,
    this.whatsappLink,
    this.status,
    this.autoApprove = false,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
        id: json['id'] as int?,
        userId: json['user_id'] as int?,
        bio: json['bio'] ?? "",
        telegramLink: json['telegram_link'] ?? "",
        linkedinLink: json['linkedin_link'] ?? "",
        facebookLink: json['facebook_link'] ?? "",
        whatsappLink: json['whatsapp_link'] ?? "",
        status: fromAuthorStatus(json[STATUS]),
        autoApprove: fromAutoApprove(json[AUTO_APPROVE]));
  }
}

/// Backend may send the flag as bool, int (1/0) or string ("1"/"0"); treat all
/// truthy representations as enabled and anything missing/else as disabled.
bool fromAutoApprove(dynamic value) {
  return value == true || value == 1 || value == "1";
}

AuthorStatus? fromAuthorStatus(String? value) {
  switch (value) {
    case 'pending':
      return AuthorStatus.pending;
    case 'approved':
      return AuthorStatus.approved;
    case 'rejected':
      return AuthorStatus.rejected;
    default:
      return null;
  }
}
