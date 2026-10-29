import Foundation
import UIKit
import SwiftSignalKit
import AccountContext
import AlertUI
import PresentationDataUtils
import TelegramUIPreferences
import TelegramPresentationData

public struct ExteraRelease: Equatable {
    public let version: String
    public let changelog: String
    public let pageUrl: String

    public init(version: String, changelog: String, pageUrl: String) {
        self.version = version
        self.changelog = changelog
        self.pageUrl = pageUrl
    }
}

private let exteraReleasesApiUrl = URL(string: "https://api.github.com/repos/Anabioz1337/exeteragram-ios/releases/latest")!

private func exteraRelease(from json: [String: Any]) -> ExteraRelease? {
    guard let version = json["tag_name"] as? String, !version.isEmpty else {
        return nil
    }
    guard let pageUrl = json["html_url"] as? String, !pageUrl.isEmpty else {
        return nil
    }
    let changelog = json["body"] as? String ?? ""
    return ExteraRelease(version: version, changelog: changelog, pageUrl: pageUrl)
}

private func fetchLatestExteraRelease() -> Signal<ExteraRelease?, NoError> {
    return Signal { subscriber in
        var request = URLRequest(url: exteraReleasesApiUrl)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            var release: ExteraRelease?
            if let data = data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                release = exteraRelease(from: json)
            }
            Queue.mainQueue().async {
                subscriber.putNext(release)
                subscriber.putCompletion()
            }
        }
        task.resume()
        return ActionDisposable {
            task.cancel()
        }
    }
}

private func exteraVersionComponents(_ version: String) -> [Int] {
    var normalized = version
    if normalized.hasPrefix("v") {
        normalized.removeFirst()
    }
    return normalized.split(separator: ".").map { component in
        let digits = component.prefix(while: { $0.isNumber })
        return Int(digits) ?? 0
    }
}

private func exteraReleaseIsNewer(_ release: ExteraRelease, than currentVersion: String) -> Bool {
    let releaseComponents = exteraVersionComponents(release.version)
    let currentComponents = exteraVersionComponents(currentVersion)
    for index in 0 ..< max(releaseComponents.count, currentComponents.count) {
        let releaseComponent = index < releaseComponents.count ? releaseComponents[index] : 0
        let currentComponent = index < currentComponents.count ? currentComponents[index] : 0
        if releaseComponent != currentComponent {
            return releaseComponent > currentComponent
        }
    }
    return false
}

private let exteraLaunchUpdateCheckPerformed = Atomic<Bool>(value: false)

public enum ExteraUpdater {
    public static func checkOnLaunchIfNeeded(sharedContext: SharedAccountContext, settings: ExteraSettings) {
        guard settings.checkUpdatesOnLaunch else {
            return
        }
        guard !exteraLaunchUpdateCheckPerformed.swap(true) else {
            return
        }
        checkForUpdate(sharedContext: sharedContext)
    }

    @discardableResult
    public static func checkForUpdate(sharedContext: SharedAccountContext, completion: ((ExteraRelease?) -> Void)? = nil) -> Disposable {
        return (fetchLatestExteraRelease()
        |> deliverOnMainQueue).start(next: { release in
            let _ = updateExteraSettingsInteractively(accountManager: sharedContext.accountManager) { settings in
                var settings = settings
                settings.lastUpdateCheckTime = Int64(Date().timeIntervalSince1970)
                return settings
            }.start()
            guard let release = release, let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, exteraReleaseIsNewer(release, than: currentVersion) else {
                completion?(release)
                return
            }
            presentUpdateAlert(sharedContext: sharedContext, release: release)
            completion?(release)
        })
    }

    private static func presentUpdateAlert(sharedContext: SharedAccountContext, release: ExteraRelease) {
        let presentationData = sharedContext.currentPresentationData.with { $0 }
        let strings = exteraStrings(presentationData: presentationData)
        let alert = textAlertController(
            sharedContext: sharedContext,
            title: strings.updateAvailable,
            text: strings.updateAvailableText(release.version) + "\n\n" + release.changelog,
            actions: [
                TextAlertAction(type: .genericAction, title: strings.laterAction, action: {}),
                TextAlertAction(type: .defaultAction, title: strings.downloadAction, action: {
                    if let url = URL(string: release.pageUrl) {
                        UIApplication.shared.open(url)
                    }
                })
            ]
        )
        sharedContext.presentGlobalController(alert, nil)
    }
}
