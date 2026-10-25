// The "now playing" bar that floats above *every* screen while an episode is
// loaded in the app-wide [PodcastPlayerCubit].
//
// Only its ✕ closes it, and that stops playback — navigating, popping back,
// pausing and backgrounding the app all leave the bar up. It is mounted once,
// above the Navigator (see MyApp.builder), so it survives route changes instead
// of being rebuilt per screen.

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news/commons/widgets/network_image.dart';
import 'package:news/commons/widgets/svg_picture_widget.dart';
import 'package:news/core/routes/route_tracker.dart';
import 'package:news/core/routes/routes.dart';
import 'package:news/core/theme/app_theme.dart';
import 'package:news/features/dashboard/widgets/app_bottom_nav_bar.dart';
import 'package:news/features/podcast/cubits/podcast_player_cubit.dart';
import 'package:news/features/podcast/models/playable_audio.dart';
import 'package:news/features/podcast/screens/podcast_player_screen.dart';
import 'package:news/utils/ui_utils.dart';

/// Mounts [PodcastMiniPlayer] over [child] (the app's Navigator).
class PodcastMiniPlayerHost extends StatelessWidget {
  final Widget child;

  const PodcastMiniPlayerHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // The bar's own RepaintBoundary lives inside its AnimatedPositioned (see
    // [PodcastMiniPlayer._positioned]): a Positioned must be a direct child of
    // this Stack, so nothing may wrap the bar out here.
    return Stack(children: [
      RepaintBoundary(child: child),
      const PodcastMiniPlayer(),
    ]);
  }
}

class PodcastMiniPlayer extends StatelessWidget {
  const PodcastMiniPlayer({super.key});

  /// Screens that own the whole display: the bar would cover their own controls,
  /// so it steps aside there and comes back on the way out.
  static const Set<String> _fullScreenRoutes = {
    Routes.podcastPlayer,
    Routes.videoLandscape,
    Routes.live,
    Routes.splash,
  };

  /// Space the dashboard's floating bottom navigation bar occupies above the
  /// Scaffold bottom; the mini player floats above it.
  static const double _bottomNavBarHeight = AppBottomNavBar.reservedHeight;

  static final ValueNotifier<bool> _suppressed = ValueNotifier<bool>(false);

  /// Hides the bar while a full-screen surface that is *not* a route of its own
  /// is showing — the Reels tab, which runs immersive inside the dashboard.
  static void setSuppressed(bool value) =>
      UiUtils.setNotifier(_suppressed, value);

  static final ValueNotifier<String?> _playerScreenEpisodeId =
      ValueNotifier<String?>(null);

  /// The episode the player screen shows, or null when no player screen is up.
  static void setPlayerScreenEpisode(String? id) =>
      UiUtils.setNotifier(_playerScreenEpisodeId, id);

  static void clearPlayerScreenEpisode(String? id) {
    if (_playerScreenEpisodeId.value == id) setPlayerScreenEpisode(null);
  }

  static final ValueNotifier<double> _bottomInset = ValueNotifier<double>(0);

  /// Extra clearance for a screen with its own bottom furniture to stay clear of.
  static void setBottomInset(double inset) =>
      UiUtils.setNotifier(_bottomInset, inset);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PodcastPlayerCubit, PodcastPlayerState>(
      builder: (context, state) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            RouteTracker.topRoute,
            RouteTracker.popupOpen,
            _suppressed,
            _playerScreenEpisodeId,
            _bottomInset,
          ]),
          builder: (context, _) => _positioned(context, state),
        );
      },
    );
  }

  /// The audio the bar represents, or null when nothing is loaded — which is
  /// exactly the state `stop()` (the ✕) leaves the cubit in.
  PlayableAudio? _audioOf(PodcastPlayerState state) {
    if (state is PodcastPlayerLoading) return state.audio;
    if (state is PodcastPlayerReady) return state.audio;
    if (state is PodcastPlayerFailure) return state.audio;
    return null;
  }

  /// The player screen hides the bar only while it shows the loaded episode; on
  /// any other episode the bar is the only handle left on what is playing.
  bool _routeHidesBar(String? route, PlayableAudio audio) {
    if (!_fullScreenRoutes.contains(route)) return false;
    if (route != Routes.podcastPlayer) return true;
    final String? shown = _playerScreenEpisodeId.value;
    return shown == null ||
        shown.isEmpty ||
        audio.id.isEmpty ||
        shown == audio.id;
  }

  Widget _positioned(BuildContext context, PodcastPlayerState state) {
    final PlayableAudio? audio = _audioOf(state);
    final String? route = RouteTracker.topRoute.value;

    // The Reels tab only covers the dashboard itself; a screen pushed on top of
    // it gets the bar back.
    final bool reelsTabShowing = _suppressed.value && route == Routes.home;

    final bool visible = audio != null &&
        !reelsTabShowing &&
        !RouteTracker.popupOpen.value &&
        !_routeHidesBar(route, audio) &&
        MediaQuery.viewInsetsOf(context).bottom == 0;

    // On Android the system navigation-bar strip is already padded out by
    // MyApp.builder; on iOS the home-indicator inset is still ours to clear.
    final double systemInset = defaultTargetPlatform == TargetPlatform.android
        ? 0
        : MediaQuery.paddingOf(context).bottom;
    final double navBar = route == Routes.home ? _bottomNavBarHeight : 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: systemInset + navBar + _bottomInset.value + 8,
      // Keeps the bar's continuous repaints in their own compositing layer,
      // apart from the Navigator's subtree.
      child: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
                sizeFactor: animation, axisAlignment: -1, child: child),
          ),
          child: visible
              ? _bar(context, state, audio)
              : const SizedBox.shrink(key: ValueKey('podcastMiniPlayerHidden')),
        ),
      ),
    );
  }

  Widget _bar(
      BuildContext context, PodcastPlayerState state, PlayableAudio audio) {
    final cubit = context.read<PodcastPlayerCubit>();

    // The floating bar reads against whatever screen is behind it, so it takes
    // the theme *opposite* the app's: a dark bar over the light UI (as drawn in
    // Figma), a light bar over the dark UI. Dropping the whole subtree into that
    // ThemeData hands the treatment to every `Theme.of(context)` reader below
    // (background, titles, icon tints, seek handle).
    final AppTheme barTheme = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.Light
        : AppTheme.Dark;
    return Theme(
      key: const ValueKey('podcastMiniPlayer'),
      data: appThemeData[barTheme]!,
      child: Builder(
        builder: (context) {
          final colorScheme = UiUtils.getColorScheme(context);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // The bar hangs above the Navigator, so there is no Scaffold to
            // inherit a Material from — Slider and friends assert on one.
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openFullPlayer(audio),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colorScheme.primaryContainer.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 6, 0),
                        child: Row(
                          children: [
                            _artwork(context, audio),
                            const SizedBox(width: 10),
                            Expanded(child: _titles(context, audio)),
                            const SizedBox(width: 4),
                            _iconButton(
                              onTap: cubit.skipBackward,
                              child: _svgIcon(context, 'podcast_backward', 20),
                            ),
                            _playPauseButton(context, state, cubit),
                            _iconButton(
                              onTap: cubit.stop,
                              child: Icon(Icons.close_rounded,
                                  size: 22, color: colorScheme.primaryContainer),
                            ),
                          ],
                        ),
                      ),
                      _seekBar(context, cubit),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _artwork(BuildContext context, PlayableAudio audio) {
    final String url = audio.artUri ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: url.isEmpty
          ? Image.asset(UiUtils.getPlaceholderPngPath(),
              width: 40, height: 40, fit: BoxFit.cover)
          : CustomNetworkImage(
              networkImageUrl: url, width: 40, height: 40, fit: BoxFit.cover),
    );
  }

  Widget _titles(BuildContext context, PlayableAudio audio) {
    final colorScheme = UiUtils.getColorScheme(context);
    final String subtitle = audio.artist ?? audio.album ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(audio.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 16 / 13,
              letterSpacing: 0.1018,
              color: colorScheme.primaryContainer,
            )),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 14 / 11,
                letterSpacing: 0.1018,
                color: colorScheme.primaryContainer.withOpacity(0.6),
              )),
        ],
      ],
    );
  }

  Widget _playPauseButton(BuildContext context, PodcastPlayerState state,
      PodcastPlayerCubit cubit) {
    final colorScheme = UiUtils.getColorScheme(context);
    final Widget glyph;
    if (state is PodcastPlayerLoading) {
      glyph = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: colorScheme.primaryContainer),
      );
    } else if (state is PodcastPlayerReady && state.playing) {
      glyph = Icon(Icons.pause_rounded,
          size: 26, color: colorScheme.primaryContainer);
    } else {
      glyph = Transform.translate(
        offset: const Offset(2, 0),
        child: _svgIcon(context, 'podcast_play', 20),
      );
    }
    return _iconButton(onTap: cubit.togglePlayPause, child: glyph);
  }

  Widget _svgIcon(BuildContext context, String assetName, double size) {
    final colorScheme = UiUtils.getColorScheme(context);
    return SvgPictureWidget(
        assetName: assetName,
        width: size,
        height: size,
        fit: BoxFit.contain,
        assetColor:
            ColorFilter.mode(colorScheme.primaryContainer, BlendMode.srcIn));
  }

  Widget _iconButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 38, height: 38, child: Center(child: child)),
    );
  }

  Widget _seekBar(BuildContext context, PodcastPlayerCubit cubit) {
    final colorScheme = UiUtils.getColorScheme(context);
    return StreamBuilder<PositionData>(
      stream: cubit.positionDataStream,
      initialData: cubit.currentPositionData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const PositionData();
        final int totalMs = data.duration.inMilliseconds;
        final double fraction = totalMs == 0
            ? 0.0
            : (data.position.inMilliseconds / totalMs).clamp(0.0, 1.0);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _SeekBar(
                fraction: fraction,
                // The Figma mini player paints the played portion in the brand
                // red (its "Loding_bar" is a #E00000 stroke); the handle stays
                // the light dot so it reads against the red.
                activeColor: Theme.of(context).primaryColor,
                inactiveColor: colorScheme.primaryContainer.withOpacity(0.15),
                thumbColor: colorScheme.primaryContainer,
                onSeek: (value) {
                  if (totalMs == 0) return;
                  cubit.seek(Duration(milliseconds: (value * totalMs).round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(data.position), style: _timeStyle(context)),
                  Text(_format(data.duration), style: _timeStyle(context)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle _timeStyle(BuildContext context) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 12 / 10,
        color:
            UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.6),
      );

  // Same separator as the full player's seek bar.
  String _format(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(duration.inMinutes.remainder(60));
    final seconds = two(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${two(duration.inHours)}.$minutes.$seconds'
        : '$minutes.$seconds';
  }

  void _openFullPlayer(PlayableAudio audio) {
    final navigator = UiUtils.rootNavigatorKey.currentState;
    final arguments = PodcastPlayerScreen.launchArgumentsFor(audio);
    // Tapped from a player screen on another episode: swap it, never stack one.
    if (RouteTracker.topRoute.value == Routes.podcastPlayer) {
      navigator?.pushReplacementNamed(Routes.podcastPlayer,
          arguments: arguments);
      return;
    }
    navigator?.pushNamed(Routes.podcastPlayer, arguments: arguments);
  }
}

/// The bar's progress/scrub control.
///
/// Material's [Slider] cannot be used here: it asserts on both a [Material] and
/// an [Overlay] ancestor, and the mini player hangs above the Navigator where
/// neither exists. This is the same interaction in plain boxes.
class _SeekBar extends StatefulWidget {
  final double fraction;
  final Color activeColor;
  final Color inactiveColor;

  /// The scrub handle's colour. Kept apart from [activeColor] so the handle
  /// stays readable when the played track is the brand red.
  final Color thumbColor;
  final ValueChanged<double> onSeek;

  const _SeekBar({
    required this.fraction,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.onSeek,
  });

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  static const double _thumbSize = 10;
  static const double _trackHeight = 3;
  static const double _height = 18;

  // While the finger is down the thumb follows it, not the position stream.
  double? _dragFraction;

  double get _value => (_dragFraction ?? widget.fraction).clamp(0.0, 1.0);

  void _drag(double dx, double travel, bool isRtl) {
    if (travel <= 0) return;
    final double raw = ((dx - _thumbSize / 2) / travel).clamp(0.0, 1.0);
    setState(() => _dragFraction = isRtl ? 1 - raw : raw);
  }

  void _commit() {
    final double? fraction = _dragFraction;
    setState(() => _dragFraction = null);
    if (fraction != null) widget.onSeek(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double travel = constraints.maxWidth - _thumbSize;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _drag(details.localPosition.dx, travel, isRtl);
            _commit();
          },
          onHorizontalDragStart: (details) =>
              _drag(details.localPosition.dx, travel, isRtl),
          onHorizontalDragUpdate: (details) =>
              _drag(details.localPosition.dx, travel, isRtl),
          onHorizontalDragEnd: (_) => _commit(),
          onHorizontalDragCancel: () => setState(() => _dragFraction = null),
          child: SizedBox(
            height: _height,
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                Container(
                  width: double.infinity,
                  height: _trackHeight,
                  decoration: BoxDecoration(
                    color: widget.inactiveColor,
                    borderRadius: BorderRadius.circular(_trackHeight),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _value,
                  child: Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      borderRadius: BorderRadius.circular(_trackHeight),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: travel <= 0 ? 0 : travel * _value,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                          color: widget.thumbColor, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
