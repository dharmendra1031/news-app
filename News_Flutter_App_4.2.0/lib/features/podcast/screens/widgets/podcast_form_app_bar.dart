// Shared app bar for the Create / Edit channel and episode forms — only the
// title key differs between them.

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/utils/ui_utils.dart';

class PodcastFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Remote language-JSON key of the screen title.
  final String titleKey;

  const PodcastFormAppBar({super.key, required this.titleKey});

  @override
  Size get preferredSize => const Size(double.infinity, 54);

  @override
  Widget build(BuildContext context) {
    final Color foreground = UiUtils.getColorScheme(context).primaryContainer;
    return UiUtils.applyBoxShadow(
      context: context,
      child: AppBar(
        toolbarHeight: 54,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        leadingWidth: 40,
        titleSpacing: 12,
        title: CustomTextLabel(
            text: titleKey,
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15)),
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16.0),
          child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Icon(Icons.arrow_back, size: 24, color: foreground)),
        ),
      ),
    );
  }
}
