// "Save as draft" / "Publish" footer shared by the Create channel and Create
// episode forms. Purely presentational — each screen keeps its own
// BlocConsumer around it and passes the resulting [isSaving] down.

import 'package:flutter/material.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class PodcastFormActionButtons extends StatelessWidget {
  /// While true both buttons are disabled and Publish shows a spinner.
  final bool isSaving;

  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  const PodcastFormActionButtons({
    super.key,
    required this.isSaving,
    required this.onSaveDraft,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.15);
    final Color secondary = UiUtils.getColorScheme(context).primaryContainer;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: 16, end: 16, top: 8, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onSaveDraft,
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondary,
                  side: BorderSide(color: secondary),
                  minimumSize: const Size.fromHeight(40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  textStyle: labelStyle,
                ),
                child:
                    Text(UiUtils.getTranslatedLabel(context, 'saveAsDraftLbl')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: isSaving ? null : onPublish,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: secondaryColor,
                  minimumSize: const Size.fromHeight(40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  textStyle: labelStyle,
                ),
                child: (isSaving)
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: secondaryColor))
                    : Text(
                        UiUtils.getTranslatedLabel(context, 'publishBtnLbl')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
