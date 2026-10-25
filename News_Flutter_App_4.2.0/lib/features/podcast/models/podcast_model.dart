// One podcast channel, from `get_podcast` or the channel block of `get_episode`.
// Also builds its own card data and owns the "1.4K" follower formatting.

import 'package:news/core/constants/strings.dart';
import 'package:news/features/podcast/screens/widgets/podcast_card.dart';

class PodcastModel {
  final String? id;

  final String? userId;
  final String? title;
  final String? slug;
  final String? description;
  final String? image;
  final String? publishedAt;
  final int followerCount;
  final int episodeCount;
  final bool isFollowed;

  final bool hasFollowState;

  final bool isActive;
  final bool isDraft;
  final String? authorName;
  final String? authorImage;

  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeyword;
  final String? schemaMarkup;

  PodcastModel({
    this.id,
    this.userId,
    this.title,
    this.slug,
    this.description,
    this.image,
    this.publishedAt,
    this.followerCount = 0,
    this.episodeCount = 0,
    this.isFollowed = false,
    this.hasFollowState = false,
    this.isActive = true,
    this.isDraft = false,
    this.authorName,
    this.authorImage,
    this.metaTitle,
    this.metaDescription,
    this.metaKeyword,
    this.schemaMarkup,
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    final user = (json[USER] is Map)
        ? Map<String, dynamic>.from(json[USER])
        : const <String, dynamic>{};
    return PodcastModel(
      id: json[ID]?.toString(),
      userId: json[USER_ID]?.toString(),
      title: json[TITLE]?.toString(),
      slug: json[SLUG]?.toString(),
      description: json[DESCRIPTION]?.toString(),
      image: json[IMAGE]?.toString(),
      publishedAt: json[PUBLISHED_AT]?.toString(),
      followerCount: _parseInt(json[FOLLOWER_COUNT]),
      episodeCount: _parseInt(json[EPISODE_COUNT]),
      isFollowed: _parseBool(json[IS_FOLLOWED]),
      hasFollowState: json[IS_FOLLOWED] != null,
      isActive: json[STATUS] == null ? true : _parseBool(json[STATUS]),
      isDraft: _parseBool(json[DRAFT]),
      authorName: user[NAME]?.toString(),
      authorImage: user[PROFILE]?.toString(),
      metaTitle: json[META_TITLE]?.toString(),
      metaDescription: json[META_DESC]?.toString(),
      metaKeyword: json[META_KEYWORD]?.toString(),
      schemaMarkup: json[SCHEMA_MARKUP]?.toString(),
    );
  }

  PodcastCardData toCardData() => PodcastCardData(
        id: id,
        slug: slug,
        imageUrl: image ?? '',
        title: title ?? '',
        description: description,
        listenersCount: compactCount(followerCount),
        episodesCount: episodeCount.toString(),
        authorName: authorName ?? '',
        authorImageUrl: authorImage ?? '',
        isFollowed: isFollowed,
        isActive: isActive,
      );

  PodcastModel copyWith({bool? isFollowed, int? followerCount}) => PodcastModel(
        id: id,
        userId: userId,
        title: title,
        slug: slug,
        description: description,
        image: image,
        publishedAt: publishedAt,
        followerCount: followerCount ?? this.followerCount,
        episodeCount: episodeCount,
        isFollowed: isFollowed ?? this.isFollowed,
        hasFollowState: hasFollowState || isFollowed != null,
        isActive: isActive,
        isDraft: isDraft,
        authorName: authorName,
        authorImage: authorImage,
        metaTitle: metaTitle,
        metaDescription: metaDescription,
        metaKeyword: metaKeyword,
        schemaMarkup: schemaMarkup,
      );

  /// True when the logged-in user owns this channel, i.e. they are its author.
  ///
  /// Guests come through as "0" and admin-created channels carry no `user_id`,
  /// so both fall back to false — the listener view is always the safe default.
  bool isOwnedBy(String? loggedInUserId) {
    final owner = userId ?? '';
    final viewer = loggedInUserId ?? '';
    if (owner.isEmpty || owner == '0') return false;
    if (viewer.isEmpty || viewer == '0') return false;
    return owner == viewer;
  }

  /// The description as it should be rendered, or null when there is nothing
  /// worth a line of its own.
  ///
  /// Both forms make the description required, so an author with nothing to
  /// say fills it with a placeholder and the API hands that straight back —
  /// a lone "-" under the title reads as a broken row, not as content. Only
  /// the display side uses this; the forms still prefill the raw text, or
  /// editing such a channel would fail its own validation.
  static String? displayDescription(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.replaceAll(RegExp(r'[-–—_.·•\s]'), '').isEmpty ? null : text;
  }

  static String compactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M'.replaceAll('.0', '');
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K'.replaceAll('.0', '');
    }
    return value.toString();
  }

  static int _parseInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  static bool _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    final str = raw?.toString().toLowerCase();
    return str == 'true' || str == '1';
  }
}
