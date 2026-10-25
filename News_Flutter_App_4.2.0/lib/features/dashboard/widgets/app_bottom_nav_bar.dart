import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/theme/theme_colors.dart';
import 'package:news/utils/ui_utils.dart';

/// Data for a single [AppBottomNavBar] tab.
class AppBottomNavBarItemData {
  /// SVG asset name for the unselected (outline) state.
  final String icon;

  /// SVG asset name for the selected (filled) state.
  final String activeIcon;

  /// Translation key for the accessibility label.
  final String labelKey;

  /// Clockwise rotation applied to the glyph, in turns (1 turn = 360°).
  /// The RSS tab tilts a wifi glyph 30° so it reads as the RSS mark, matching
  /// the Figma design.
  final double iconTurns;

  const AppBottomNavBarItemData({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    this.iconTurns = 0,
  });

  /// Maps a dashboard tab key (`home`, `video`, `reels`, `rss`, `profile`) to
  /// its icon pair. Keeps the asset names in one place instead of the caller.
  factory AppBottomNavBarItemData.forKey(String key,
      {required String labelKey}) {
    switch (key) {
      case 'video':
        return AppBottomNavBarItemData(
            icon: 'nav_video',
            activeIcon: 'nav_video_fill',
            labelKey: labelKey);
      case 'reels':
        return AppBottomNavBarItemData(
            icon: 'nav_reels',
            activeIcon: 'nav_reels_fill',
            labelKey: labelKey);
      case 'rss':
        return AppBottomNavBarItemData(
            icon: 'nav_rss',
            activeIcon: 'nav_rss_fill',
            labelKey: labelKey,
            iconTurns: 30 / 360);
      case 'profile':
        return AppBottomNavBarItemData(
            icon: 'nav_profile',
            activeIcon: 'nav_profile_fill',
            labelKey: labelKey);
      case 'home':
      default:
        return AppBottomNavBarItemData(
            icon: 'nav_home', activeIcon: 'nav_home_fill', labelKey: labelKey);
    }
  }
}

/// Floating capsule bottom navigation bar for the dashboard tabs.
///
/// Owns no state: it renders [items], highlights [currentIndex] and reports taps
/// through [onTap]. The host ([DashBoard]) keeps the selected index.
///
/// Per the Figma design the bar always renders as the **inverse** of the active
/// theme — a dark capsule with white glyphs over the light UI, and a light
/// capsule with dark glyphs over the dark UI. The selected tab gets a filled
/// glyph inside a "glass" pill (hairline border + a soft bottom-up glow).
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<AppBottomNavBarItemData> items;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  /// Gap between the capsule and each screen edge, left and right.
  static const double sideMargin = 16;
  static const double _bottomMargin = 12;
  static const double _capsulePadding = 8;
  static const double _itemGap = 10;
  static const double _itemHeight = 56;
  static const double _iconSize = 24;

  /// How long the highlight pill takes to glide to a newly tapped tab.
  static const Duration _slideDuration = Duration(milliseconds: 280);

  /// Full height the bar occupies above the Scaffold bottom (capsule + margin),
  /// used by overlapping widgets such as the podcast mini player.
  static const double reservedHeight =
      _bottomMargin + _capsulePadding * 2 + _itemHeight;

  /// Bottom padding a dashboard tab's scroll content needs so its last item
  /// rests above the floating bar: the bar ([reservedHeight]), the system
  /// bottom inset (gesture / home-indicator area) and a small breathing gap.
  static double contentClearance(BuildContext context) =>
      reservedHeight + MediaQuery.viewPaddingOf(context).bottom + 16;

  Widget _buildItem(
      BuildContext context, AppBottomNavBarItemData item, int index, Color fg) {
    final bool selected = index == currentIndex;

    Widget glyph = SvgPictureWidget(
      height: _iconSize,
      width: _iconSize,
      fit: BoxFit.contain,
      assetName: selected ? item.activeIcon : item.icon,
      assetColor: ColorFilter.mode(fg, BlendMode.srcIn),
    );
    if (item.iconTurns != 0) {
      glyph =
          Transform.rotate(angle: item.iconTurns * 2 * math.pi, child: glyph);
    }

    return Semantics(
      button: true,
      selected: selected,
      label: UiUtils.getTranslatedLabel(context, item.labelKey),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Container(
          height: _itemHeight,
          alignment: Alignment.center,
          child: glyph,
        ),
      ),
    );
  }

  /// The "glass" highlight pill. Rendered once behind the row and slid between
  /// tabs, so tapping another tab glides the highlight across instead of
  /// snapping it.
  Widget _buildPill(Color fg) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: fg.withOpacity(0.35))),
        // Soft glow that lifts the bottom of the pill, transparent for the top
        // two-thirds (Figma: 66.9% → 101.6%, white @ 30%).
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.669, 1.0],
          colors: [fg.withOpacity(0), fg.withOpacity(0.3)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Inverse of the active theme.
    final Color capsuleColor = isDark ? backgroundColor : darkBackgroundColor;
    final Color fg = isDark ? textPrimaryColor : secondaryColor;

    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(sideMargin, 0, sideMargin, _bottomMargin),
      // app.dart already reserves the Android system-nav strip app-wide; on iOS
      // the home-indicator inset is still ours to clear.
      child: SafeArea(
        top: false,
        bottom: !isAndroid,
        child: Container(
          padding: const EdgeInsets.all(_capsulePadding),
          decoration: ShapeDecoration(
            color: capsuleColor,
            shape: const StadiumBorder(),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int count = items.length;
              // Row lays out [count] equal Expanded items with [_itemGap]
              // between each, so a tab's slot is this wide/offset.
              final double itemWidth =
                  (constraints.maxWidth - (count - 1) * _itemGap) / count;
              final double pillStart = currentIndex * (itemWidth + _itemGap);

              final List<Widget> row = [];
              for (var i = 0; i < count; i++) {
                if (i > 0) row.add(const SizedBox(width: _itemGap));
                row.add(Expanded(child: _buildItem(context, items[i], i, fg)));
              }

              return SizedBox(
                height: _itemHeight,
                child: Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: _slideDuration,
                      curve: Curves.easeOutCubic,
                      top: 0,
                      bottom: 0,
                      start: pillStart,
                      width: itemWidth,
                      child: _buildPill(fg),
                    ),
                    Positioned.fill(child: Row(children: row)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Whether the floating nav capsule is at its full size.
///
/// [BottomNavScrollHider] flips this to `false` while the user scrolls the
/// content toward its end (reading further down) and back to `true` the instant
/// they scroll the other way, and [BottomNavShrinkTransition] animates the
/// capsule to match. Reset it to `true` whenever the active tab changes so a
/// shrunk bar never carries over to another tab.
final ValueNotifier<bool> bottomNavExpanded = ValueNotifier<bool>(true);

/// Wraps scrollable content and drives [bottomNavExpanded] from the direction of
/// actual scroll movement.
///
/// The dashboard wraps its tab body in one of these, so every tab — the feeds,
/// Videos, RSS, Profile and the Reels pager — collapses and restores the bar the
/// same way. Routes pushed on top of the dashboard sit outside its subtree and
/// never reach it.
///
/// It watches [ScrollUpdateNotification.scrollDelta] rather than
/// [UserScrollNotification.direction]: the latter goes `idle` the moment a fling
/// settles, so once the feed is pinned at the bottom it stops reporting and the
/// bar can't be coaxed back. Tracking the delta means the very first pixel of an
/// upward drag — from anywhere, the end of the list included — brings it back,
/// and any real downward scroll collapses it (not just reaching the end).
///
/// A small accumulator absorbs finger jitter; the restore threshold is tiny so
/// the bar returns fast, the collapse threshold larger so a stray nudge doesn't
/// shrink it. Horizontal inner lists (the Categories rail, the breaking-news
/// marquee) are ignored via the axis check.
class BottomNavScrollHider extends StatefulWidget {
  final Widget child;

  const BottomNavScrollHider({super.key, required this.child});

  @override
  State<BottomNavScrollHider> createState() => _BottomNavScrollHiderState();
}

class _BottomNavScrollHiderState extends State<BottomNavScrollHider> {
  /// Signed pixels scrolled since the last direction flip: + is toward the
  /// bottom (collapse), - is toward the top (restore).
  double _accum = 0;

  /// Upward drag needed to restore — kept small so it snaps back promptly.
  static const double _revealThreshold = 6;

  /// Downward scroll needed to collapse — larger so a small nudge doesn't
  /// shrink it.
  static const double _hideThreshold = 24;

  @override
  void initState() {
    super.initState();
    bottomNavExpanded.addListener(_onExpandedChanged);
  }

  @override
  void dispose() {
    bottomNavExpanded.removeListener(_onExpandedChanged);
    super.dispose();
  }

  /// The dashboard restores the bar when the tab changes, so a run counted on
  /// the previous tab (a Reels swipe, say) must not make the first pixel of the
  /// next tab's scroll collapse it at once.
  void _onExpandedChanged() {
    if (bottomNavExpanded.value) _accum = 0;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) return false;
        if (notification is! ScrollUpdateNotification) return false;

        final double delta = notification.scrollDelta ?? 0;
        if (delta == 0) return false;

        // Always restore once the list is back at (or above) the top.
        if (notification.metrics.pixels <=
            notification.metrics.minScrollExtent + 4) {
          _accum = 0;
          _setExpanded(true);
          return false;
        }

        // Reset the run as soon as the scroll reverses.
        if ((delta > 0) != (_accum > 0)) _accum = 0;
        _accum += delta;

        if (_accum <= -_revealThreshold) {
          _setExpanded(true);
        } else if (_accum >= _hideThreshold) {
          _setExpanded(false);
        }
        return false;
      },
      child: widget.child,
    );
  }

  void _setExpanded(bool value) {
    if (bottomNavExpanded.value != value) bottomNavExpanded.value = value;
  }
}

/// Scales [child] down toward its bottom edge whenever [bottomNavExpanded] is
/// `false`, and eases it back to full size when it is `true`.
///
/// The bar is never removed or moved, only made compact, so the tabs stay
/// reachable at any scroll position. The scale is paint-only: the bar keeps its
/// layout size, so nothing around it reflows.
class BottomNavShrinkTransition extends StatelessWidget {
  final Widget child;

  const BottomNavShrinkTransition({super.key, required this.child});

  /// Scale the capsule shrinks to — compact but still present, never fully
  /// hidden.
  static const double _shrunkScale = 0.82;

  static const Duration _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: bottomNavExpanded,
      builder: (context, expanded, child) {
        return AnimatedScale(
          scale: expanded ? 1 : _shrunkScale,
          alignment: Alignment.bottomCenter,
          duration: _duration,
          curve: Curves.easeOutCubic,
          child: child,
        );
      },
      child: child,
    );
  }
}
