// Holds every editable value of the Create / Edit episode form so the screen
// itself keeps a single object instead of a dozen loose fields. Pure state — it
// never touches BuildContext, so the form logic stays testable on its own.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:news/features/podcast/models/episode_model.dart';
import 'package:news/features/podcast/models/podcast_model.dart';
import 'package:news/utils/validators.dart';

/// Where an episode's audio comes from. [apiValue] is what the backend stores,
/// [labelKey] is the remote language-JSON key shown in the picker.
enum EpisodeSourceType {
  youtubeLink('youtube_link', 'sourceYoutubeLbl'),
  upload('upload', 'sourceUploadLbl');

  final String apiValue;
  final String labelKey;

  const EpisodeSourceType(this.apiValue, this.labelKey);

  static EpisodeSourceType? fromApiValue(String? apiValue) {
    for (final source in EpisodeSourceType.values) {
      if (source.apiValue == apiValue) return source;
    }
    return null;
  }
}

class EpisodeFormController {
  /// Audio formats an episode may be uploaded in — kept to the ones both
  /// Android and iOS can play back, so a listener never gets a file the app
  /// cannot open. Keep `plzValidAudioFileLbl` in sync when this changes.
  static const List<String> allowedAudioExtensions = [
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac'
  ];

  /// Channel the episode belongs to. Shown read-only and never edited here.
  final PodcastModel podcast;

  /// The episode being edited, or null while creating a new one.
  final EpisodeModel? episode;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController podcastTitle = TextEditingController();
  final TextEditingController episodeNo = TextEditingController();
  final TextEditingController title = TextEditingController();
  final TextEditingController slug = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController youtubeUrl = TextEditingController();

  DateTime? publishDate;
  EpisodeSourceType? sourceType;
  File? audio;
  File? image;

  /// Once the author types their own slug the title stops overwriting it.
  bool slugEditedByHand = false;

  EpisodeFormController({required this.podcast, this.episode}) {
    podcastTitle.text = podcast.title ?? '';

    final EpisodeModel? source = episode;
    if (source == null) {
      publishDate = DateTime.now();
      return;
    }
    episodeNo.text = source.episodeNo > 0 ? source.episodeNo.toString() : '';
    title.text = source.title ?? '';
    slug.text = source.slug ?? '';
    slugEditedByHand = slug.text.trim().isNotEmpty;
    description.text = source.description ?? '';
    publishDate = DateTime.tryParse(source.publishedAt ?? '')?.toLocal();
    sourceType = EpisodeSourceType.fromApiValue(source.sourceType);
    if (sourceType == EpisodeSourceType.youtubeLink) {
      youtubeUrl.text = source.audioUrl ?? '';
    }
  }

  bool get isEdit => episode != null;

  /// Already uploaded cover, shown until the author picks a new [image].
  String get existingImageUrl => episode?.image ?? '';

  /// True while the saved episode still carries a usable upload — switching the
  /// source type away and back must not count the old file as still attached.
  bool get hasSavedAudio =>
      isEdit &&
      episode!.sourceType == sourceType?.apiValue &&
      (episode!.audioUrl?.isNotEmpty ?? false);

  /// File name of [hasSavedAudio], shown when no new file has been picked.
  String get savedAudioName => hasSavedAudio
      ? Uri.parse(episode!.audioUrl!).pathSegments.lastOrNull ?? ''
      : '';

  /// Mirrors the title into the slug until the author edits the slug by hand.
  /// Returns true when the slug actually changed, so the caller only rebuilds
  /// on the keystrokes that matter.
  bool syncSlugWithTitle(String value) {
    if (slugEditedByHand) return false;
    final String generated = Validators.generateSlug(value);
    if (generated == slug.text) return false;
    slug.text = generated;
    return true;
  }

  /// Slugs cannot hold spaces, so they are folded to dashes as they are typed.
  void normalizeSlug() {
    slug.text = slug.text.replaceAll(' ', '-');
    slug.selection =
        TextSelection.fromPosition(TextPosition(offset: slug.text.length));
    slugEditedByHand = slug.text.trim().isNotEmpty;
  }

  /// Switching source drops whatever the previous one collected, so a YouTube
  /// link never ships alongside an upload. Returns true when it changed.
  bool selectSourceType(EpisodeSourceType source) {
    if (sourceType == source) return false;
    sourceType = source;
    youtubeUrl.clear();
    audio = null;
    return true;
  }

  /// The picker is already limited to [allowedAudioExtensions], but Android
  /// file managers can still hand back anything the user browses to, so the
  /// pick is re-checked here before it can reach the upload.
  bool isSupportedAudio(File file) {
    final String name = file.path.split(Platform.pathSeparator).last;
    final int dotIndex = name.lastIndexOf('.');
    final String extension =
        (dotIndex == -1) ? '' : name.substring(dotIndex + 1).toLowerCase();
    if (!allowedAudioExtensions.contains(extension)) return false;
    return file.existsSync() && file.lengthSync() > 0;
  }

  void dispose() {
    podcastTitle.dispose();
    episodeNo.dispose();
    title.dispose();
    slug.dispose();
    description.dispose();
    youtubeUrl.dispose();
  }
}
