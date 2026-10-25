import 'package:flutter/material.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

class NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NextButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      // app.dart already pads the whole app by the Android system nav-bar
      // inset. Insetting again here would double it and push the button up.
      bottom: false,
      // 8 + 40 + 8 = the 56pt bar height from Figma.
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: 16, end: 16, top: 8, bottom: 8),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            // Not colorScheme.primary: the scheme is built with
            // ColorScheme.fromSeed, which derives a tonal shade rather than
            // keeping the brand red.
            backgroundColor: primaryColor,
            foregroundColor: secondaryColor,
            minimumSize: const Size.fromHeight(40),
            // Without this the button reserves a 48pt tap target and the bar
            // grows past 56.
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.15),
          ),
          child: Text(UiUtils.getTranslatedLabel(context, "nxt")),
        ),
      ),
    );
  }
}
