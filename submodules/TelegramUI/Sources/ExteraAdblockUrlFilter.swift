import Foundation
import SwiftSignalKit
import TelegramCore
import TelegramUIPreferences

private let exteraAdblockFilterListUrl = URL(string: "https://filters.adtidy.org/ios/filters/1.txt")!
private let exteraAdblockFilterListRefreshInterval: TimeInterval = 24.0 * 60.0 * 60.0

/// Hosts the fork never filters, so the account's own domains keep working even if a list matches.
private let exteraAdblockAlwaysAllowedHosts: Set<String> = [
    "telegram.org",
    "t.me",
    "core.telegram.org",
    "telegram.me",
    "telegram-cdn.org",
    "telesco.pe",
    "exteragram.app"
]

func exteraAdblockHostForUrl(_ url: String) -> String {
    let lowercased = url.lowercased()
    guard let urlObject = URL(string: lowercased), let host = urlObject.host, !host.isEmpty else {
        return lowercased
    }
    return host
}

func parseFilterListDomains(_ source: String, limit: Int = 20000) -> Set<String> {
    var hosts = Set<String>()
    for line in source.split(separator: "\n", omittingEmptySubsequences: true) {
        if hosts.count >= limit {
            break
        }
        let rule = line.trimmingCharacters(in: .whitespaces)
        if rule.hasPrefix("||") {
            let remainder = rule.dropFirst(2)
            if let caretIndex = remainder.firstIndex(of: "^") {
                let host = String(remainder[..<caretIndex])
                if !host.isEmpty {
                    hosts.insert(host)
                }
            }
        }
    }
    return hosts
}

private struct ExteraAdblockFilterState {
    var blockedHosts: Set<String> = []
    var sessionAllowedHosts: Set<String> = []
    var lastRefresh: Date?
}

/// Ad and badware host filtering behind the Block Ads flag: the host list comes from the
/// AdGuard filter list (refreshed once a day) plus the session hosts the user proceeded to.
/// Blocked requests are counted in the shared exteraSettings entry, so the controller needs an
/// account manager registered before the first blocked page.
public final class ExteraAdblockUrlFilter {
    public static let shared = ExteraAdblockUrlFilter()

    private let state = Atomic<ExteraAdblockFilterState>(value: ExteraAdblockFilterState())
    private let defaults: UserDefaults
    private let accountManager = Atomic<AccountManager<TelegramAccountManagerTypes>?>(value: nil)
    private let refreshInFlight = Atomic<Bool>(value: false)

    private init() {
        self.defaults = exteraAdBlockUserDefaults ?? UserDefaults.standard
        if let storedHosts = self.defaults.stringArray(forKey: "filterBlockedHosts") {
            self.state.modify { state -> ExteraAdblockFilterState in
                var state = state
                state.blockedHosts = Set(storedHosts)
                state.lastRefresh = self.defaults.object(forKey: "filterListUpdatedAt") as? Date
                return state
            }
        }
        self.refreshIfNeeded()
    }

    public func register(accountManager: AccountManager<TelegramAccountManagerTypes>) {
        let _ = self.accountManager.swap(accountManager)
    }

    public func isAllowed(_ url: String) -> Bool {
        guard exteraAdBlockUserDefaults?.bool(forKey: "blockAdsEnabled") ?? false else {
            return true
        }
        let host = exteraAdblockHostForUrl(url)
        if exteraAdblockAlwaysAllowedHosts.contains(host) {
            return true
        }
        let verdict = self.state.with { state -> Bool in
            if state.sessionAllowedHosts.contains(host) {
                return true
            }
            return !(state.blockedHosts.contains(host) || state.blockedHosts.contains(where: { host.hasSuffix("." + $0) }))
        }
        if !verdict {
            self.countBlockedRequest()
        }
        return verdict
    }

    public func proceed(_ url: String) {
        let host = exteraAdblockHostForUrl(url)
        self.state.modify { state -> ExteraAdblockFilterState in
            var state = state
            state.sessionAllowedHosts.insert(host)
            return state
        }
    }

    private func countBlockedRequest() {
        guard let accountManager = self.accountManager.with({ $0 }) else {
            return
        }
        let _ = updateExteraSettingsInteractively(accountManager: accountManager) { settings in
            settings.withUpdatedAdBlockBlockedRequests(settings.adBlockBlockedRequests + 1)
        }.startStandalone()
    }

    private func refreshIfNeeded() {
        let shouldRefresh = self.state.with { state -> Bool in
            if let lastRefresh = state.lastRefresh, Date().timeIntervalSince(lastRefresh) < exteraAdblockFilterListRefreshInterval {
                return false
            }
            return true
        }
        guard shouldRefresh else {
            return
        }
        let started = self.refreshInFlight.swap(true)
        guard !started else {
            return
        }
        var request = URLRequest(url: exteraAdblockFilterListUrl)
        request.timeoutInterval = 30.0
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] data, _, _ in
            guard let self else {
                return
            }
            if let data, let source = String(data: data, encoding: .utf8) {
                let hosts = parseFilterListDomains(source)
                self.defaults.set(Array(hosts), forKey: "filterBlockedHosts")
                self.defaults.set(Date(), forKey: "filterListUpdatedAt")
                self.state.modify { state -> ExteraAdblockFilterState in
                    var state = state
                    state.blockedHosts = hosts
                    state.lastRefresh = Date()
                    return state
                }
            }
            let _ = self.refreshInFlight.swap(false)
        })
        task.resume()
    }
}
