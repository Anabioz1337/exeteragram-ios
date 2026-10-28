import Foundation
import TelegramCore
import SwiftSignalKit

public struct ExteraFeedCategory: Codable, Equatable {
    public let id: Int64
    public let title: String
    public let channelIds: [Int64]
    public let hidden: Bool

    public init(id: Int64, title: String, channelIds: [Int64], hidden: Bool) {
        self.id = id
        self.title = title
        self.channelIds = channelIds
        self.hidden = hidden
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.id = try container.decode(Int64.self, forKey: "id")
        self.title = try container.decode(String.self, forKey: "title")
        self.channelIds = try container.decode([Int64].self, forKey: "channelIds")
        self.hidden = try container.decode(Int32.self, forKey: "hidden") != 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.id, forKey: "id")
        try container.encode(self.title, forKey: "title")
        try container.encode(self.channelIds, forKey: "channelIds")
        try container.encode((self.hidden ? 1 : 0) as Int32, forKey: "hidden")
    }
}

public struct ExteraSettings: Codable, Equatable {
    public var downloadSpeedBoostLevel: Int
    public var uploadSpeedBoost: Bool
    public var disableNumberRounding: Bool
    public var formatTimeWithSeconds: Bool
    public var checkUpdatesOnLaunch: Bool
    public var lastUpdateCheckTime: Int64
    public var customSaveFolderName: String
    public var useGoogleAnalytics: Bool
    public var useGoogleCrashlytics: Bool
    public var adBlockEnabled: Bool
    public var adBlockBlockedRequests: Int32
    public var feedEnabled: Bool
    public var feedCategories: [ExteraFeedCategory]
    public var feedIncludeArchived: Bool
    public var feedWidePosts: Bool

    public static var defaultSettings: ExteraSettings {
        return ExteraSettings(downloadSpeedBoostLevel: 0, uploadSpeedBoost: false, disableNumberRounding: false, formatTimeWithSeconds: false, checkUpdatesOnLaunch: false, lastUpdateCheckTime: 0, customSaveFolderName: "", useGoogleAnalytics: false, useGoogleCrashlytics: false, adBlockEnabled: false, adBlockBlockedRequests: 0, feedEnabled: false, feedCategories: [], feedIncludeArchived: false, feedWidePosts: false)
    }

    public init(downloadSpeedBoostLevel: Int, uploadSpeedBoost: Bool, disableNumberRounding: Bool, formatTimeWithSeconds: Bool, checkUpdatesOnLaunch: Bool, lastUpdateCheckTime: Int64, customSaveFolderName: String, useGoogleAnalytics: Bool, useGoogleCrashlytics: Bool, adBlockEnabled: Bool, adBlockBlockedRequests: Int32, feedEnabled: Bool, feedCategories: [ExteraFeedCategory], feedIncludeArchived: Bool, feedWidePosts: Bool) {
        self.downloadSpeedBoostLevel = downloadSpeedBoostLevel
        self.uploadSpeedBoost = uploadSpeedBoost
        self.disableNumberRounding = disableNumberRounding
        self.formatTimeWithSeconds = formatTimeWithSeconds
        self.checkUpdatesOnLaunch = checkUpdatesOnLaunch
        self.lastUpdateCheckTime = lastUpdateCheckTime
        self.customSaveFolderName = customSaveFolderName
        self.useGoogleAnalytics = useGoogleAnalytics
        self.useGoogleCrashlytics = useGoogleCrashlytics
        self.adBlockEnabled = adBlockEnabled
        self.adBlockBlockedRequests = adBlockBlockedRequests
        self.feedEnabled = feedEnabled
        self.feedCategories = feedCategories
        self.feedIncludeArchived = feedIncludeArchived
        self.feedWidePosts = feedWidePosts
    }

    public func withUpdatedAdBlockEnabled(_ value: Bool) -> ExteraSettings {
        var result = self
        result.adBlockEnabled = value
        return result
    }

    public func withUpdatedAdBlockBlockedRequests(_ value: Int32) -> ExteraSettings {
        var result = self
        result.adBlockBlockedRequests = value
        return result
    }

    public func withUpdatedFeedEnabled(_ value: Bool) -> ExteraSettings {
        var result = self
        result.feedEnabled = value
        return result
    }

    public func withUpdatedFeedCategories(_ value: [ExteraFeedCategory]) -> ExteraSettings {
        var result = self
        result.feedCategories = value
        return result
    }

    public func withUpdatedFeedIncludeArchived(_ value: Bool) -> ExteraSettings {
        var result = self
        result.feedIncludeArchived = value
        return result
    }

    public func withUpdatedFeedWidePosts(_ value: Bool) -> ExteraSettings {
        var result = self
        result.feedWidePosts = value
        return result
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.downloadSpeedBoostLevel = (try? container.decode(Int32.self, forKey: "downloadSpeedBoostLevel")).flatMap({ Int($0) }) ?? 0
        self.uploadSpeedBoost = ((try? container.decode(Int32.self, forKey: "uploadSpeedBoost")) ?? 0) != 0
        self.disableNumberRounding = ((try? container.decode(Int32.self, forKey: "disableNumberRounding")) ?? 0) != 0
        self.formatTimeWithSeconds = ((try? container.decode(Int32.self, forKey: "formatTimeWithSeconds")) ?? 0) != 0
        self.checkUpdatesOnLaunch = ((try? container.decode(Int32.self, forKey: "checkUpdatesOnLaunch")) ?? 0) != 0
        self.lastUpdateCheckTime = (try? container.decode(Int64.self, forKey: "lastUpdateCheckTime")) ?? 0
        self.customSaveFolderName = (try? container.decode(String.self, forKey: "customSaveFolderName")) ?? ""
        self.useGoogleAnalytics = ((try? container.decode(Int32.self, forKey: "useGoogleAnalytics")) ?? 0) != 0
        self.useGoogleCrashlytics = ((try? container.decode(Int32.self, forKey: "useGoogleCrashlytics")) ?? 0) != 0
        self.adBlockEnabled = (try container.decodeIfPresent(Int32.self, forKey: "adBlockEnabled")).flatMap({ $0 != 0 }) ?? false
        self.adBlockBlockedRequests = (try container.decodeIfPresent(Int32.self, forKey: "adBlockBlockedRequests")) ?? 0
        self.feedEnabled = (try container.decodeIfPresent(Int32.self, forKey: "feedEnabled")).flatMap({ $0 != 0 }) ?? false
        self.feedCategories = (try container.decodeIfPresent([ExteraFeedCategory].self, forKey: "feedCategories")) ?? []
        self.feedIncludeArchived = (try container.decodeIfPresent(Int32.self, forKey: "feedIncludeArchived")).flatMap({ $0 != 0 }) ?? false
        self.feedWidePosts = (try container.decodeIfPresent(Int32.self, forKey: "feedWidePosts")).flatMap({ $0 != 0 }) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(Int32(self.downloadSpeedBoostLevel), forKey: "downloadSpeedBoostLevel")
        try container.encode((self.uploadSpeedBoost ? 1 : 0) as Int32, forKey: "uploadSpeedBoost")
        try container.encode((self.disableNumberRounding ? 1 : 0) as Int32, forKey: "disableNumberRounding")
        try container.encode((self.formatTimeWithSeconds ? 1 : 0) as Int32, forKey: "formatTimeWithSeconds")
        try container.encode((self.checkUpdatesOnLaunch ? 1 : 0) as Int32, forKey: "checkUpdatesOnLaunch")
        try container.encode(self.lastUpdateCheckTime, forKey: "lastUpdateCheckTime")
        try container.encode(self.customSaveFolderName, forKey: "customSaveFolderName")
        try container.encode((self.useGoogleAnalytics ? 1 : 0) as Int32, forKey: "useGoogleAnalytics")
        try container.encode((self.useGoogleCrashlytics ? 1 : 0) as Int32, forKey: "useGoogleCrashlytics")
        try container.encode((self.adBlockEnabled ? 1 : 0) as Int32, forKey: "adBlockEnabled")
        try container.encode(self.adBlockBlockedRequests, forKey: "adBlockBlockedRequests")
        try container.encode((self.feedEnabled ? 1 : 0) as Int32, forKey: "feedEnabled")
        try container.encode(self.feedCategories, forKey: "feedCategories")
        try container.encode((self.feedIncludeArchived ? 1 : 0) as Int32, forKey: "feedIncludeArchived")
        try container.encode((self.feedWidePosts ? 1 : 0) as Int32, forKey: "feedWidePosts")
    }

    public static func ==(lhs: ExteraSettings, rhs: ExteraSettings) -> Bool {
        return lhs.downloadSpeedBoostLevel == rhs.downloadSpeedBoostLevel &&
            lhs.uploadSpeedBoost == rhs.uploadSpeedBoost &&
            lhs.disableNumberRounding == rhs.disableNumberRounding &&
            lhs.formatTimeWithSeconds == rhs.formatTimeWithSeconds &&
            lhs.checkUpdatesOnLaunch == rhs.checkUpdatesOnLaunch &&
            lhs.lastUpdateCheckTime == rhs.lastUpdateCheckTime &&
            lhs.customSaveFolderName == rhs.customSaveFolderName &&
            lhs.useGoogleAnalytics == rhs.useGoogleAnalytics &&
            lhs.useGoogleCrashlytics == rhs.useGoogleCrashlytics &&
            lhs.adBlockEnabled == rhs.adBlockEnabled &&
            lhs.adBlockBlockedRequests == rhs.adBlockBlockedRequests &&
            lhs.feedEnabled == rhs.feedEnabled &&
            lhs.feedCategories == rhs.feedCategories &&
            lhs.feedIncludeArchived == rhs.feedIncludeArchived &&
            lhs.feedWidePosts == rhs.feedWidePosts
    }
}

public let exteraAdBlockUserDefaults = UserDefaults(suiteName: "exteraAdBlock")

public func updateExteraSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSettings) -> ExteraSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSettings, { entry in
            let currentSettings: ExteraSettings
            if let entry = entry?.get(ExteraSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraSettings.defaultSettings
            }
            let updated = f(currentSettings)
            exteraAdBlockUserDefaults?.set(updated.adBlockEnabled, forKey: "blockAdsEnabled")
            return SharedPreferencesEntry(updated)
        })
    }
}

public func exteraSettings(accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<ExteraSettings, NoError> {
    return accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
    |> map { sharedData -> ExteraSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? .defaultSettings
    }
}
