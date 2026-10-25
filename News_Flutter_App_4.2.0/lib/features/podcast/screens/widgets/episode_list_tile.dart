// The one episode row used everywhere in the module; it changes shape only through
// the nullable fields of EpisodeListTileData (subtitle, progress, title lines).

import 'package:flutter/material.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/features/podcast/models/playable_audio.dart';
import 'package:news/features/podcast/screens/widgets/podcast_deactive_notice.dart';
import 'package:news/utils/ui_utils.dart';

class EpisodeListTileData {
  final String imageUrl;

  final String? episodeLabel;
  final String title;

  final String? subtitle;

  final String duration;

  final String? date;

  final double? progress;

  final bool isBookmarked;

  final PlayableAudio? audio;

  final String? description;

  /// `status == "0"` on the API — admin-deactivated. Only the author's own
  /// lists ever carry one; `get_episode` drops them unless `is_author_check`
  /// is set, so every listener surface leaves this false.
  final bool isDeactivated;

  const EpisodeListTileData({
    required this.imageUrl,
    this.episodeLabel,
    required this.title,
    this.subtitle,
    required this.duration,
    this.date,
    this.progress,
    this.isBookmarked = false,
    this.audio,
    this.description,
    this.isDeactivated = false,
  });
}

enum PodcastEpisodeMenuAction { download, bookmark }

class EpisodeListTile extends StatefulWidget {
  final EpisodeListTileData data;
  final VoidCallback? onTap;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onBookmarkTap;

  /// Bookmarking is a listener action — the author of the channel never sees
  /// it on their own episodes.
  final bool showBookmark;

  /// Replaces the built-in menu wholesale. Download and Bookmark are what a
  /// listener does with an episode; an author manages one instead, so their
  /// row passes [PodcastOwnerMenu] here and gets Edit / Delete in their place.
  final Widget? trailing;

  final bool isActive;

  const EpisodeListTile({
    super.key,
    required this.data,
    this.onTap,
    this.onDownloadTap,
    this.onBookmarkTap,
    this.showBookmark = true,
    this.trailing,
    this.isActive = false,
  });

  @override
  State<EpisodeListTile> createState() => _EpisodeListTileState();
}

class _EpisodeListTileState extends State<EpisodeListTile> {
  late bool _isBookmarked = widget.data.isBookmarked;

  @override
  void didUpdateWidget(EpisodeListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.isBookmarked != widget.data.isBookmarked) {
      _isBookmarked = widget.data.isBookmarked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final Widget? menu = widget.trailing ?? _menuButton(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isActive
              ? Color.alphaBlend(colorScheme.primaryContainer.withOpacity(0.06),
                  colorScheme.surface)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: colorScheme.primaryContainer
                  .withOpacity(widget.isActive ? 0.5 : 0.1),
              width: widget.isActive ? 1 : 0.678),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomNetworkImage(
                  networkImageUrl: widget.data.imageUrl,
                  width: 93,
                  height: 93,
                  fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _titleBlock(context)),
                      if (menu != null) ...[
                        const SizedBox(width: 12),
                        menu,
                      ],
                    ],
                  ),
                  ..._statsRow(context),
                  if (widget.data.isDeactivated) ...[
                    const SizedBox(height: 6),
                    const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: PodcastDeactiveBadge()),
                  ],
                  if (widget.data.progress != null) ...[
                    const SizedBox(height: 8),
                    _progressBar(context, widget.data.progress!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBlock(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.data.episodeLabel != null) ...[
          Text(widget.data.episodeLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 22.3 / 11,
                letterSpacing: 0.1018,
                color: colorScheme.primaryContainer.withOpacity(0.5),
              )),
          const SizedBox(height: 4),
        ],
        Text(widget.data.title,
            maxLines: widget.data.subtitle == null ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22.3 / 16,
              letterSpacing: 0.1018,
              color: colorScheme.primaryContainer,
            )),
        if (widget.data.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(widget.data.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 22.3 / 12,
                letterSpacing: 0.1018,
                color: colorScheme.primaryContainer.withOpacity(0.7),
              )),
        ],
      ],
    );
  }

  bool get _canDownload =>
      widget.onDownloadTap != null &&
      (widget.data.audio?.isDownloadable ?? false);

  /// The rows this tile offers, in order, with a divider between each. A row
  /// can end up with nothing to show (bookmarking off, nothing to download),
  /// and an empty popup is just a blank box — hence the null.
  List<PopupMenuEntry<PodcastEpisodeMenuAction>>? _menuItems(
      BuildContext context) {
    final entries = <PopupMenuEntry<PodcastEpisodeMenuAction>>[];
    void add(PopupMenuItem<PodcastEpisodeMenuAction> item) {
      if (entries.isNotEmpty) entries.add(const PopupMenuDivider(height: 17));
      entries.add(item);
    }

    if (_canDownload) {
      add(PopupMenuItem(
          value: PodcastEpisodeMenuAction.download,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: _menuRow(context, 'podcast_download',
              Text('Download', style: _menuLabelStyle(context)))));
    }
    if (widget.showBookmark) {
      add(PopupMenuItem(
          value: PodcastEpisodeMenuAction.bookmark,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: _menuRow(
              context,
              _isBookmarked ? 'podcast_bookmark' : 'podcast_bookmark_outline',
              Text('Bookmark', style: _menuLabelStyle(context)))));
    }
    return entries.isEmpty ? null : entries;
  }

  Widget? _menuButton(BuildContext context) {
    final items = _menuItems(context);
    if (items == null) return null;
    final colorScheme = UiUtils.getColorScheme(context);
    return PopupMenuButton<PodcastEpisodeMenuAction>(
      padding: EdgeInsets.zero,
      color: colorScheme.surface,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.25),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      offset: const Offset(0, 30),
      onSelected: (action) {
        switch (action) {
          case PodcastEpisodeMenuAction.download:
            widget.onDownloadTap?.call();
            break;
          case PodcastEpisodeMenuAction.bookmark:
            setState(() => _isBookmarked = !_isBookmarked);
            widget.onBookmarkTap?.call();
            break;
        }
      },
      itemBuilder: (context) => items,
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

  TextStyle _menuLabelStyle(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1018,
        color: UiUtils.getColorScheme(context).primaryContainer,
      );

  Widget _menuRow(BuildContext context, String iconName, Widget label) {
    final colorScheme = UiUtils.getColorScheme(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPictureWidget(
            assetName: iconName,
            width: _iconSlot,
            height: _iconSlot,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(
                colorScheme.primaryContainer, BlendMode.srcIn)),
        const SizedBox(width: 12),
        label,
      ],
    );
  }

  Widget _progressBar(BuildContext context, double progress) {
    final colorScheme = UiUtils.getColorScheme(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: LinearProgressIndicator(
        // A bad duration upstream can hand us NaN/Infinity, and clamp() lets
        // NaN through as a full bar.
        value: progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0,
        minHeight: 4,
        backgroundColor: colorScheme.primaryContainer.withOpacity(0.1),
        valueColor: AlwaysStoppedAnimation(colorScheme.primaryContainer),
      ),
    );
  }

  List<Widget> _statsRow(BuildContext context) {
    final String duration = widget.data.duration;
    final String date = widget.data.date ?? '';
    if (duration.isEmpty && date.isEmpty) return const [];
    // The date is a full localised 'dd MMMM yyyy', so on a narrow phone — or at
    // any system font size above the default — the two stats no longer fit on
    // one line. A Row would push the date out over the card edge and drag the
    // overflow stripes across the progress bar underneath; wrapping moves it to
    // its own line instead and every device keeps a clean tile.
    return [
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (duration.isNotEmpty) _stat(context, 'podcast_duration', duration),
          if (date.isNotEmpty) _stat(context, 'calendar', date),
        ],
      ),
    ];
  }

  Widget _stat(BuildContext context, String iconName, String value) {
    final colorScheme = UiUtils.getColorScheme(context);
    final mutedColor = colorScheme.primaryContainer.withOpacity(0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPictureWidget(
            assetName: iconName,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(mutedColor, BlendMode.srcIn)),
        const SizedBox(width: 4),
        // A single stat that is still too wide for its own line (long month
        // name, huge font scale) ellipsises rather than overflowing.
        Flexible(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 16 / 11,
                letterSpacing: 0.5,
                color: mutedColor,
              )),
        ),
      ],
    );
  }
}
