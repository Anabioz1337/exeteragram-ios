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
    public let adBlockEnabled: Bool
    public let adBlockBlockedRequests: Int32
    public let feedEnabled: Bool
    public let feedCategories: [ExteraFeedCategory]
    public let feedIncludeArchived: Bool
    public let feedWidePosts: Bool

    public static var defaultSettings: ExteraSettings {
        return ExteraSettings(
            adBlockEnabled: false,
            adBlockBlockedRequests: 0,
            feedEnabled: false,
            feedCategories: [],
            feedIncludeArchived: false,
            feedWidePosts: false
        )
    }

    public init(adBlockEnabled: Bool, adBlockBlockedRequests: Int32, feedEnabled: Bool, feedCategories: [ExteraFeedCategory], feedIncludeArchived: Bool, feedWidePosts: Bool) {
        self.adBlockEnabled = adBlockEnabled
        self.adBlockBlockedRequests = adBlockBlockedRequests
        self.feedEnabled = feedEnabled
        self.feedCategories = feedCategories
        self.feedIncludeArchived = feedIncludeArchived
        self.feedWidePosts = feedWidePosts
    }

    public func withUpdatedAdBlockEnabled(_ value: Bool) -> ExteraSettings {
        return ExteraSettings(adBlockEnabled: value, adBlockBlockedRequests: self.adBlockBlockedRequests, feedEnabled: self.feedEnabled, feedCategories: self.feedCategories, feedIncludeArchived: self.feedIncludeArchived, feedWidePosts: self.feedWidePosts)
    }

    public func withUpdatedAdBlockBlockedRequests(_ value: Int32) -> ExteraSettings {
        return ExteraSettings(adBlockEnabled: self.adBlockEnabled, adBlockBlockedRequests: value, feedEnabled: self.feedEnabled, feedCategories: self.feedCategories, feedIncludeArchived: self.feedIncludeArchived, feedWidePosts: self.feedWidePosts)
    }

    public func withUpdatedFeedEnabled(_ value: Bool) -> ExteraSettings {
        return ExteraSettings(adBlockEnabled: self.adBlockEnabled, adBlockBlockedRequests: self.adBlockBlockedRequests, feedEnabled: value, feedCategories: self.feedCategories, feedIncludeArchived: self.feedIncludeArchived, feedWidePosts: self.feedWidePosts)
    }

    public func withUpdatedFeedCategories(_ value: [ExteraFeedCategory]) -> ExteraSettings {
        return ExteraSettings(adBlockEnabled: self.adBlockEnabled, adBlockBlockedRequests: self.adBlockBlockedRequests, feedEnabled: self.feedEnabled, feedCategories: value, feedIncludeArchived: self.feedIncludeArchived, feedWidePosts: self.feedWidePosts)
    }

    public func withUpdatedFeedIncludeArchived(_ value: Bool) -> ExteraSettings {
        return ExteraSettings(adBlockEnabled: self.adBlockEnabled, adBlockBlockedRequests: self.adBlockBlockedRequests, feedEnabled: self.feedEnabled, feedCategories: self.feedCategories, feedIncludeArchived: value, feedWidePosts: self.feedWidePosts)
    }

    public func withUpdatedFeedWidePosts(_ value: Bool) -> ExteraSettings {
        return ExteraSettings(adBlockEnabled: self.adBlockEnabled, adBlockBlockedRequests: self.adBlockBlockedRequests, feedEnabled: self.feedEnabled, feedCategories: self.feedCategories, feedIncludeArchived: self.feedIncludeArchived, feedWidePosts: value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.adBlockEnabled = (try container.decodeIfPresent(Int32.self, forKey: "adBlockEnabled")).flatMap({ $0 != 0 }) ?? false
        self.adBlockBlockedRequests = (try container.decodeIfPresent(Int32.self, forKey: "adBlockBlockedRequests")) ?? 0
        self.feedEnabled = (try container.decodeIfPresent(Int32.self, forKey: "feedEnabled")).flatMap({ $0 != 0 }) ?? false
        self.feedCategories = (try container.decodeIfPresent([ExteraFeedCategory].self, forKey: "feedCategories")) ?? []
        self.feedIncludeArchived = (try container.decodeIfPresent(Int32.self, forKey: "feedIncludeArchived")).flatMap({ $0 != 0 }) ?? false
        self.feedWidePosts = (try container.decodeIfPresent(Int32.self, forKey: "feedWidePosts")).flatMap({ $0 != 0 }) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode((self.adBlockEnabled ? 1 : 0) as Int32, forKey: "adBlockEnabled")
        try container.encode(self.adBlockBlockedRequests, forKey: "adBlockBlockedRequests")
        try container.encode((self.feedEnabled ? 1 : 0) as Int32, forKey: "feedEnabled")
        try container.encode(self.feedCategories, forKey: "feedCategories")
        try container.encode((self.feedIncludeArchived ? 1 : 0) as Int32, forKey: "feedIncludeArchived")
        try container.encode((self.feedWidePosts ? 1 : 0) as Int32, forKey: "feedWidePosts")
    }
}

public func updateExteraSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSettings) -> ExteraSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSettings, { entry in
            let currentSettings = entry?.get(ExteraSettings.self) ?? ExteraSettings.defaultSettings
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}
