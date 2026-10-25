// The menu on a row the author owns: Edit, Delete, and — on a podcast row only —
// Create Episode, which opens that channel's MyEpisodesScreen.

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/custom_text_label.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/utils/ui_utils.dart';

enum PodcastOwnerMenuAction { edit, delete, episodes }

class PodcastOwnerMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final VoidCallback? onEpisodes;

  const PodcastOwnerMenu({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onEpisodes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return PopupMenuButton<PodcastOwnerMenuAction>(
      padding: EdgeInsets.zero,
      color: colorScheme.surface,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.25),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      offset: const Offset(0, 30),
      onSelected: (action) {
        switch (action) {
          case PodcastOwnerMenuAction.edit:
            onEdit?.call();
            break;
          case PodcastOwnerMenuAction.delete:
            onDelete?.call();
            break;
          case PodcastOwnerMenuAction.episodes:
            onEpisodes?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
            value: PodcastOwnerMenuAction.edit,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: _menuRow(context, 'editNewsIcon', 'editLbl',
                iconScale: _editIconScale)),
        const PopupMenuDivider(height: 17),
        PopupMenuItem(
            value: PodcastOwnerMenuAction.delete,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: _menuRow(context, 'deleteNewsIcon', 'deleteTxt',
                iconScale: _deleteIconScale)),
        if (onEpisodes != null) ...[
          const PopupMenuDivider(height: 17),
          PopupMenuItem(
              value: PodcastOwnerMenuAction.episodes,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: _menuRow(
                  context, 'podcast_create_episode', 'createEpisodeLbl',
                  iconScale: _episodesIconScale)),
        ],
      ],
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border:
              Border.all(color: colorScheme.primaryContainer.withOpacity(0.1)),
        ),
        child: SvgPictureWidget(
            assetName: 'podcast_menu',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(
                colorScheme.primaryContainer, BlendMode.srcIn)),
      ),
    );
  }

  static const double _iconSlot = 23.077;
  static const double _editIconScale = 1.85;
  static const double _deleteIconScale = 1.69;
  static const double _episodesIconScale = 0.833;

  Widget _menuRow(BuildContext context, String iconName, String labelKey,
      {double iconScale = 1}) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: iconScale,
          child: SvgPictureWidget(
              assetName: iconName,
              width: _iconSlot,
              height: _iconSlot,
              fit: BoxFit.contain,
              assetColor: ColorFilter.mode(
                  colorScheme.primaryContainer, BlendMode.srcIn)),
        ),
        const SizedBox(width: 12),
        CustomTextLabel(
            text: labelKey,
            textStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1018,
              color: colorScheme.primaryContainer,
            )),
      ],
    );
  }
}
