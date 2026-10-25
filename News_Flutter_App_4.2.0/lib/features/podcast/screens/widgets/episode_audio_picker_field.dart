// Audio drop zone of the Create / Edit episode form, shown only while the
// source type is "upload". Displays the freshly picked file first, then the
// name of the file already attached to a saved episode.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/features/podcast/screens/widgets/podcast_image_picker_field.dart';
import 'package:news/utils/ui_utils.dart';

class EpisodeAudioPickerField extends StatelessWidget {
  /// File chosen in this session; wins over [savedAudioName] when set.
  final File? pickedAudio;

  /// File name of the audio already stored on the episode. Empty otherwise.
  final String savedAudioName;

  final VoidCallback onTap;

  const EpisodeAudioPickerField({
    super.key,
    required this.pickedAudio,
    required this.savedAudioName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? textStyle = podcastDropZoneTextStyle(context);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 93,
        width: double.maxFinite,
        child: UiUtils.dottedRRectBorder(
          context: context,
          childWidget: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.audiotrack,
                    size: 20,
                    color: UiUtils.getColorScheme(context)
                        .primaryContainer
                        .withOpacity(0.7)),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: (pickedAudio == null && savedAudioName.isEmpty)
                        ? CustomTextLabel(
                            text: 'uploadAudioLbl', textStyle: textStyle)
                        : Text(
                            pickedAudio?.path.split('/').last ?? savedAudioName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
