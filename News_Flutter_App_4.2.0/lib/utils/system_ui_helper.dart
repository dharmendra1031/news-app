import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controls the Android navigation-bar visibility for the app.
///
/// The app keeps the navigation bar VISIBLE by default (edge-to-edge, so
/// [SystemUiOverlayStyle] can paint it to match the current theme). A few
/// genuinely full-screen surfaces (Reels, landscape/full-screen video) hide it
/// for an immersive experience via [hideNavBar] and restore it with
/// [showNavBar] on exit.
///
/// Hiding is routed through the native side (`MainActivity.applyImmersiveNavBar`)
/// because Flutter's [SystemUiMode.manual] hides the bar with show-bars-by-TOUCH
/// behaviour: the hidden strip still belongs to the system, so the first tap
/// there is swallowed and (with 3-button navigation) registers as a phantom
/// Back/Home/Recents press. The native side uses swipe-to-reveal behaviour so
/// taps fall through to the app. The native side also tracks the desired
/// visibility so it can re-assert it on window focus / resume without hiding a
/// bar the app wants visible.
class SystemUiHelper {
  SystemUiHelper._();

  static const MethodChannel _channel =
      MethodChannel('com.news.wrteam/system_ui');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Keep BOTH system bars visible using edge-to-edge, so the navigation bar
  /// can be themed via [SystemUiOverlayStyle]. This is the app-wide default.
  static Future<void> showNavBar() async {
    // Edge-to-edge shows the status AND navigation bars while letting the
    // overlay style paint the nav bar; works on every platform.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!_isAndroid) return;
    try {
      // Also flip the native "immersive" flag off so the focus/resume
      // re-assertion keeps the bar visible instead of re-hiding it.
      await _channel.invokeMethod('showSystemNavBar');
    } catch (_) {
      // Flutter's edge-to-edge call above is a sufficient fallback.
    }
  }

  /// Hide the navigation bar (status bar stays visible) using swipe-to-reveal
  /// behaviour, so the hidden strip no longer captures taps. Used only by the
  /// immersive full-screen surfaces.
  static Future<void> hideNavBar() async {
    if (!_isAndroid) {
      return SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const [SystemUiOverlay.top],
      );
    }
    try {
      await _channel.invokeMethod('applyImmersiveNavBar');
    } catch (_) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const [SystemUiOverlay.top],
      );
    }
  }
}
