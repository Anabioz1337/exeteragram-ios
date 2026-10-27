import Foundation
import SwiftSignalKit

public enum ExteraChatListActionBarTitle: String, Codable, Equatable, CaseIterable {
    case appName
    case name
    case username
}

public struct ExteraProfilePreferences: Codable, Equatable {
    public var hidePhoneNumber: Bool
    public var showIdAndDc: Bool
    public var showCreationDate: Bool
    public var showRegistrationDates: Bool
    public var showOnlineIndicator: Bool
    public var showForwardsCount: Bool

    public var hideArchiveFolder: Bool
    public var archiveOnPull: Bool
    public var disableUnarchiveSwipe: Bool

    public var actionBarTitle: ExteraChatListActionBarTitle
    public var senderMiniAvatars: Bool

    public static let `default` = ExteraProfilePreferences(
        hidePhoneNumber: false,
        showIdAndDc: false,
        showCreationDate: false,
        showRegistrationDates: false,
        showOnlineIndicator: false,
        showForwardsCount: false,
        hideArchiveFolder: false,
        archiveOnPull: false,
        disableUnarchiveSwipe: false,
        actionBarTitle: .appName,
        senderMiniAvatars: false
    )

    public init(
        hidePhoneNumber: Bool,
        showIdAndDc: Bool,
        showCreationDate: Bool,
        showRegistrationDates: Bool,
        showOnlineIndicator: Bool,
        showForwardsCount: Bool,
        hideArchiveFolder: Bool,
        archiveOnPull: Bool,
        disableUnarchiveSwipe: Bool,
        actionBarTitle: ExteraChatListActionBarTitle,
        senderMiniAvatars: Bool
    ) {
        self.hidePhoneNumber = hidePhoneNumber
        self.showIdAndDc = showIdAndDc
        self.showCreationDate = showCreationDate
        self.showRegistrationDates = showRegistrationDates
        self.showOnlineIndicator = showOnlineIndicator
        self.showForwardsCount = showForwardsCount
        self.hideArchiveFolder = hideArchiveFolder
        self.archiveOnPull = archiveOnPull
        self.disableUnarchiveSwipe = disableUnarchiveSwipe
        self.actionBarTitle = actionBarTitle
        self.senderMiniAvatars = senderMiniAvatars
    }

    private enum CodingKeys: String, CodingKey {
        case hidePhoneNumber
        case showIdAndDc
        case showCreationDate
        case showRegistrationDates
        case showOnlineIndicator
        case showForwardsCount
        case hideArchiveFolder
        case archiveOnPull
        case disableUnarchiveSwipe
        case actionBarTitle
        case senderMiniAvatars
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            hidePhoneNumber: try container.decodeIfPresent(Bool.self, forKey: .hidePhoneNumber) ?? false,
            showIdAndDc: try container.decodeIfPresent(Bool.self, forKey: .showIdAndDc) ?? false,
            showCreationDate: try container.decodeIfPresent(Bool.self, forKey: .showCreationDate) ?? false,
            showRegistrationDates: try container.decodeIfPresent(Bool.self, forKey: .showRegistrationDates) ?? false,
            showOnlineIndicator: try container.decodeIfPresent(Bool.self, forKey: .showOnlineIndicator) ?? false,
            showForwardsCount: try container.decodeIfPresent(Bool.self, forKey: .showForwardsCount) ?? false,
            hideArchiveFolder: try container.decodeIfPresent(Bool.self, forKey: .hideArchiveFolder) ?? false,
            archiveOnPull: try container.decodeIfPresent(Bool.self, forKey: .archiveOnPull) ?? false,
            disableUnarchiveSwipe: try container.decodeIfPresent(Bool.self, forKey: .disableUnarchiveSwipe) ?? false,
            actionBarTitle: (try container.decodeIfPresent(String.self, forKey: .actionBarTitle)).flatMap(ExteraChatListActionBarTitle.init(rawValue:)) ?? .appName,
            senderMiniAvatars: try container.decodeIfPresent(Bool.self, forKey: .senderMiniAvatars) ?? false
        )
    }
}

/// Feature flags of the extera profile & chat list domain. Kept in the dedicated
/// `exteraProfile` defaults suite so they live outside Telegram's preferences domain;
/// change notification goes through a plain signal.
public final class ExteraProfileSettings {
    public static let shared = ExteraProfileSettings()

    private static let defaults = UserDefaults(suiteName: "exteraProfile") ?? .standard
    private static let preferencesKey = "preferences"

    private let promise = ValuePromise<ExteraProfilePreferences>(ignoreRepeated: true)
    private let lock = NSLock()
    private var cachedPreferences: ExteraProfilePreferences

    private init() {
        if let data = ExteraProfileSettings.defaults.data(forKey: ExteraProfileSettings.preferencesKey), let preferences = try? JSONDecoder().decode(ExteraProfilePreferences.self, from: data) {
            self.cachedPreferences = preferences
        } else {
            self.cachedPreferences = .default
        }
    }

    public var current: ExteraProfilePreferences {
        return self.lock.with {
            self.cachedPreferences
        }
    }

    public func update(_ preferences: ExteraProfilePreferences) {
        let data = (try? JSONEncoder().encode(preferences)) ?? Data()
        ExteraProfileSettings.defaults.set(data, forKey: ExteraProfileSettings.preferencesKey)
        self.lock.with {
            self.cachedPreferences = preferences
        }
        self.promise.set(preferences)
    }

    public func with(_ f: @escaping (ExteraProfilePreferences) -> ExteraProfilePreferences) {
        self.update(f(self.current))
    }

    public var preferencesSignal: Signal<ExteraProfilePreferences, NoError> {
        return self.promise.signal()
    }
}

extension NSLock {
    fileprivate func with<T>(_ body: () -> T) -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return body()
    }
}
