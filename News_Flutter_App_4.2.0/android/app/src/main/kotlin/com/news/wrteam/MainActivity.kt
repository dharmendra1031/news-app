package com.news.wrteam

import android.content.Intent
import android.net.Uri
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Extends AudioServiceActivity (a FlutterFragmentActivity) — required by
// audio_service / just_audio_background so the background playback service is
// handed the correct, shared FlutterEngine. A plain FlutterActivity throws
// "The Activity class declared in your AndroidManifest.xml is wrong..." on
// AudioService.init().
class MainActivity : AudioServiceActivity() {

    private var reelsChannel: MethodChannel? = null
    private var systemUiChannel: MethodChannel? = null

    // Whether the app currently wants the nav bar hidden (immersive full-screen
    // surfaces such as Reels / landscape video). Default is VISIBLE so the bar
    // shows on every normal screen and can be themed from Dart.
    private var immersiveNavBar = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        reelsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REELS_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialReelsLink" -> {
                        val url = intent?.data?.toString()
                        result.success(if (isReelsLink(url)) url else null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Lets Dart (re)assert the desired navigation-bar visibility after any
        // widget/plugin resets the system UI (e.g. flick_video_player on Reels,
        // or leaving an immersive surface).
        systemUiChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_UI_CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "applyImmersiveNavBar" -> {
                        applyImmersiveNavBar()
                        result.success(null)
                    }
                    "showSystemNavBar" -> {
                        showSystemNavBar()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Default to a visible (edge-to-edge, themeable) navigation bar.
        showSystemNavBar()
        notifyReelsLinkIfNeeded(intent?.data)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        // Re-assert on regaining focus (app resume, dialog / keyboard dismiss) —
        // exactly when Android tends to reset the system bars.
        if (hasFocus) reapplyNavBarState()
    }

    override fun onPostResume() {
        // Flutter's PlatformPlugin re-applies its cached SystemUiMode here (via
        // updateSystemUiOverlays). Run super first, then re-assert the app's
        // desired nav-bar state so it wins the last write.
        super.onPostResume()
        reapplyNavBarState()
    }

    /** Re-applies whichever nav-bar visibility the app currently wants. */
    private fun reapplyNavBarState() {
        if (immersiveNavBar) applyImmersiveNavBar() else showSystemNavBar()
    }

    /**
     * Keeps BOTH system bars visible edge-to-edge so the navigation bar can be
     * painted from Dart via `SystemUiOverlayStyle.systemNavigationBarColor`.
     */
    private fun showSystemNavBar() {
        immersiveNavBar = false
        val window = window ?: return
        // Draw behind the bars so Flutter controls the nav-bar colour.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        // Showing the bar persistently; systemBarsBehavior only affects how a
        // hidden bar is revealed, so it needn't be reset here.
        controller.show(WindowInsetsCompat.Type.navigationBars())
    }

    /**
     * Hides ONLY the navigation bar (the status bar stays visible) using
     * swipe-to-reveal behaviour, for immersive full-screen surfaces.
     *
     * Flutter's `SystemUiMode.manual` hides the nav bar with show-bars-by-TOUCH:
     * the hidden strip still belongs to the system, so the first tap there is
     * swallowed and, with 3-button navigation, registers as a phantom
     * Back/Home/Recents press. `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE` reveals
     * the bar only on an edge swipe, so a plain tap in the strip falls through
     * to the app. Works from minSdk 27 up (the compat layer maps to
     * IMMERSIVE_STICKY, without FULLSCREEN, on API < 30 so the status bar stays).
     */
    private fun applyImmersiveNavBar() {
        immersiveNavBar = true
        val window = window ?: return
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.hide(WindowInsetsCompat.Type.navigationBars())
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }

    override fun getInitialRoute(): String? {
        return intent?.data?.toString() ?: super.getInitialRoute()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        notifyReelsLinkIfNeeded(intent.data)
    }

    private fun notifyReelsLinkIfNeeded(data: Uri?) {
        val url = data?.toString() ?: return
        if (!isReelsLink(url)) return
        reelsChannel?.invokeMethod("onReelsLink", url)
    }

    private fun isReelsLink(url: String?): Boolean {
        if (url.isNullOrBlank()) return false
        // The web's reels page is /newsbuzz; /reels is kept for older links.
        return url.contains("/reels") || url.contains("/newsbuzz")
    }

    companion object {
        private const val REELS_CHANNEL = "com.news.wrteam/reels_deeplink"
        private const val SYSTEM_UI_CHANNEL = "com.news.wrteam/system_ui"
    }
}
