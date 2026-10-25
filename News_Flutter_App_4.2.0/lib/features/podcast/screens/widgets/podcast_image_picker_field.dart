// Main-image drop zone shared by the Create channel and Create episode forms.
// Shows the freshly picked file first, then whatever was already uploaded, and
// falls back to the dotted "upload" placeholder.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/utils/ui_utils.dart';

class PodcastImagePickerField extends StatelessWidget {
  /// Image chosen in this session; wins over [existingImageUrl] when set.
  final File? pickedImage;

  /// Cover already stored on the record being edited. Empty while creating.
  final String existingImageUrl;

  final VoidCallback onTap;

  const PodcastImagePickerField({
    super.key,
    required this.pickedImage,
    required this.existingImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: (pickedImage != null)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(pickedImage!,
                  height: 125, width: double.maxFinite, fit: BoxFit.cover))
          : (existingImageUrl.isNotEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CustomNetworkImage(
                      networkImageUrl: existingImageUrl,
                      height: 125,
                      width: double.maxFinite,
                      fit: BoxFit.cover,
                      isVideo: false))
              : SizedBox(
                  height: 93,
                  width: double.maxFinite,
                  child: UiUtils.dottedRRectBorder(
                      context: context,
                      childWidget: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image,
                                size: 20,
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.7)),
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 8),
                              child: CustomTextLabel(
                                  text: 'uploadMainImageLbl',
                                  textStyle: podcastDropZoneTextStyle(context)),
                            )
                          ])),
                ),
    );
  }
}

/// Placeholder text inside the dotted image / audio drop zones.
TextStyle? podcastDropZoneTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(
        color:
            UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.7));
