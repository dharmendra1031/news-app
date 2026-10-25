// Single entry point for the Download action on every screen, so the messages and
// the edge cases (no audio, YouTube-only, already saved) stay identical.

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/snackbar_widget.dart';
import 'package:news/features/podcast/models/playable_audio.dart';
import 'package:news/features/podcast/repositories/podcast_repository.dart';

Future<void> startEpisodeDownload(
    BuildContext context, PlayableAudio audio) async {
  final repository = PodcastRepository();

  if (audio.id.isEmpty || audio.url.isEmpty) {
    showSnackBar('This episode has no audio to download', context);
    return;
  }
  if (!audio.isDownloadable) {
    showSnackBar('This episode can only be streamed', context);
    return;
  }
  if (repository.isDownloaded(audio.id)) {
    showSnackBar('Already saved in your Download folder', context);
    return;
  }

  await repository.ensureDownloadPermissions();
  if (!context.mounted) return;

  showSnackBar('Download started', context);

  final started = await repository.download(audio);
  if (!context.mounted) return;

  if (!started) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    showSnackBar('Could not start the download. Please try again.', context);
  }
}
