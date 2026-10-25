import UIKit
import Flutter
import Firebase
import AppTrackingTransparency
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let reelsChannelName = "com.news.wrteam/reels_deeplink"
    private var pendingReelsUrl: String?
    private var reelsChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }

        MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)

        if let url = launchOptions?[.url] as? URL {
            cacheReelsUrlIfNeeded(url.absoluteString)
        }

        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

        DispatchQueue.main.async { [weak self] in
            self?.setupReelsChannel()
        }

        return result
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if isReelsLink(url.absoluteString) {
            cacheAndNotifyReels(url.absoluteString)
            return true
        }
        return super.application(app, open: url, options: options)
    }

    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL,
           isReelsLink(url.absoluteString) {
            cacheAndNotifyReels(url.absoluteString)
            return true
        }
        return super.application(
            application,
            continue: userActivity,
            restorationHandler: restorationHandler
        )
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        if #available(iOS 15.0, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
        }
    }

    private func setupReelsChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        let channel = FlutterMethodChannel(
            name: reelsChannelName,
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == "getInitialReelsLink" {
                result(self?.pendingReelsUrl)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        reelsChannel = channel
    }

    // The web's reels page is /newsbuzz; /reels is kept for older links.
    private func isReelsLink(_ url: String) -> Bool {
        return url.contains("/reels") || url.contains("/newsbuzz")
    }

    private func cacheReelsUrlIfNeeded(_ url: String?) {
        guard let url = url, isReelsLink(url) else { return }
        pendingReelsUrl = url
    }

    private func cacheAndNotifyReels(_ url: String) {
        guard isReelsLink(url) else { return }
        pendingReelsUrl = url
        reelsChannel?.invokeMethod("onReelsLink", arguments: url)
    }
}
