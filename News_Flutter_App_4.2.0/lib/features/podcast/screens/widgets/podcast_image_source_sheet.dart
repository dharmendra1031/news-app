// Camera / Gallery bottom sheet behind the main-image drop zone, shared by the
// Create channel and Create episode forms.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news/utils/ui_utils.dart';

/// Opens the picker sheet and hands the chosen file back through
/// [onImagePicked]. The sheet closes itself once a file comes back; a cancelled
/// pick leaves it open so the author can try the other source.
void showPodcastImageSourceSheet({
  required BuildContext context,
  required ValueChanged<File> onImagePicked,
}) {
  Future<void> pick(ImageSource source) async {
    final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: source == ImageSource.gallery ? 1800 : null,
        maxHeight: source == ImageSource.gallery ? 1800 : null);
    if (pickedFile == null || !context.mounted) return;
    onImagePicked(File(pickedFile.path));
    Navigator.of(context).pop();
  }

  UiUtils().showUploadImageBottomsheet(
    context: context,
    // The camera can throw on devices without one; the gallery path is left
    // unguarded exactly as before.
    onCamera: () async {
      try {
        await pick(ImageSource.camera);
      } catch (_) {}
    },
    onGallery: () => pick(ImageSource.gallery),
  );
}
