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
    public var downloadSpeedBoostLevel: Int32
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
    public var hidePhoneNumber: Bool = false
    public var archiveOnPull: Bool = false
    public var disableUnarchiveSwipe: Bool = true
    public var hideActionBarStatus: Bool = false
    public var centerTitle: Bool = false
    public var tabCounter: Bool = true
    public var hideAllChats: Bool = false
    public var forceBlur: Bool = false
    public var forceSnow: Bool = false
    public var useSystemFonts: Bool = true
    public var newSwitchStyle: Bool = true
    public var disableDividers: Bool = false
    public var hideStickerTime: Bool = false
    public var unlimitedRecentStickers: Bool = false
    public var hideCategories: Bool = false
    public var hideKeyboardOnScroll: Bool = true
    public var permissionsShortcut: Bool = false
    public var administratorsShortcut: Bool = false
    public var membersShortcut: Bool = false
    public var recentActionsShortcut: Bool = true
    public var disableJumpToNextChannel: Bool = false
    public var showActionTimestamps: Bool = true
    public var hideShareButton: Bool = false
    public var showCopyPhotoButton: Bool = true
    public var showClearButton: Bool = true
    public var showSaveMessageButton: Bool = false
    public var showDetailsButton: Bool = false
    public var showReportButton: Bool = true
    public var showHistoryButton: Bool = false
    public var addCommaAfterMention: Bool = true
    public var hidePhotoCounter: Bool = false
    public var hideCameraTile: Bool = false
    public var staticZoom: Bool = false
    public var rememberLastUsedCamera: Bool = false
    public var pauseOnMinimize: Bool = true
    public var disablePlayback: Bool = false
    public var filterZalgo: Bool = false
    public var showIdAndDc: Int32 = 0
    public var avatarCorners: Bool = false
    public var titleText: Bool = false
    public var tabIcons: Bool = false
    public var stickerSize: Bool = false
    public var stickerShape: Bool = false
    public var doubleTapAction: Int32 = 0
    public var doubleTapActionOutOwner: Int32 = 0
    public var doubleTapSeekDuration: Bool = false
    public var bottomButton: Bool = false
    public var sendPhotosQuality: Int32 = 0
    public var videoMessagesCamera: Bool = false

    public static var defaultSettings: ExteraSettings {
        return ExteraSettings(downloadSpeedBoostLevel: 0, uploadSpeedBoost: false, disableNumberRounding: false, formatTimeWithSeconds: false, checkUpdatesOnLaunch: false, lastUpdateCheckTime: 0, customSaveFolderName: "", useGoogleAnalytics: false, useGoogleCrashlytics: false, adBlockEnabled: false, adBlockBlockedRequests: 0, feedEnabled: false, feedCategories: [], feedIncludeArchived: false, feedWidePosts: false)
    }

    public init(downloadSpeedBoostLevel: Int32, uploadSpeedBoost: Bool, disableNumberRounding: Bool, formatTimeWithSeconds: Bool, checkUpdatesOnLaunch: Bool, lastUpdateCheckTime: Int64, customSaveFolderName: String, useGoogleAnalytics: Bool, useGoogleCrashlytics: Bool, adBlockEnabled: Bool, adBlockBlockedRequests: Int32, feedEnabled: Bool, feedCategories: [ExteraFeedCategory], feedIncludeArchived: Bool, feedWidePosts: Bool) {
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

        self.downloadSpeedBoostLevel = (try? container.decode(Int32.self, forKey: "downloadSpeedBoostLevel")) ?? 0
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

        self.hidePhoneNumber = ((try? container.decode(Int32.self, forKey: "hidePhoneNumber")) ?? 0) != 0
        self.archiveOnPull = ((try? container.decode(Int32.self, forKey: "archiveOnPull")) ?? 0) != 0
        self.disableUnarchiveSwipe = ((try? container.decode(Int32.self, forKey: "disableUnarchiveSwipe")) ?? 1) != 0
        self.hideActionBarStatus = ((try? container.decode(Int32.self, forKey: "hideActionBarStatus")) ?? 0) != 0
        self.centerTitle = ((try? container.decode(Int32.self, forKey: "centerTitle")) ?? 0) != 0
        self.tabCounter = ((try? container.decode(Int32.self, forKey: "tabCounter")) ?? 1) != 0
        self.hideAllChats = ((try? container.decode(Int32.self, forKey: "hideAllChats")) ?? 0) != 0
        self.forceBlur = ((try? container.decode(Int32.self, forKey: "forceBlur")) ?? 0) != 0
        self.forceSnow = ((try? container.decode(Int32.self, forKey: "forceSnow")) ?? 0) != 0
        self.useSystemFonts = ((try? container.decode(Int32.self, forKey: "useSystemFonts")) ?? 1) != 0
        self.newSwitchStyle = ((try? container.decode(Int32.self, forKey: "newSwitchStyle")) ?? 1) != 0
        self.disableDividers = ((try? container.decode(Int32.self, forKey: "disableDividers")) ?? 0) != 0
        self.hideStickerTime = ((try? container.decode(Int32.self, forKey: "hideStickerTime")) ?? 0) != 0
        self.unlimitedRecentStickers = ((try? container.decode(Int32.self, forKey: "unlimitedRecentStickers")) ?? 0) != 0
        self.hideCategories = ((try? container.decode(Int32.self, forKey: "hideCategories")) ?? 0) != 0
        self.hideKeyboardOnScroll = ((try? container.decode(Int32.self, forKey: "hideKeyboardOnScroll")) ?? 1) != 0
        self.permissionsShortcut = ((try? container.decode(Int32.self, forKey: "permissionsShortcut")) ?? 0) != 0
        self.administratorsShortcut = ((try? container.decode(Int32.self, forKey: "administratorsShortcut")) ?? 0) != 0
        self.membersShortcut = ((try? container.decode(Int32.self, forKey: "membersShortcut")) ?? 0) != 0
        self.recentActionsShortcut = ((try? container.decode(Int32.self, forKey: "recentActionsShortcut")) ?? 1) != 0
        self.disableJumpToNextChannel = ((try? container.decode(Int32.self, forKey: "disableJumpToNextChannel")) ?? 0) != 0
        self.showActionTimestamps = ((try? container.decode(Int32.self, forKey: "showActionTimestamps")) ?? 1) != 0
        self.hideShareButton = ((try? container.decode(Int32.self, forKey: "hideShareButton")) ?? 0) != 0
        self.showCopyPhotoButton = ((try? container.decode(Int32.self, forKey: "showCopyPhotoButton")) ?? 1) != 0
        self.showClearButton = ((try? container.decode(Int32.self, forKey: "showClearButton")) ?? 1) != 0
        self.showSaveMessageButton = ((try? container.decode(Int32.self, forKey: "showSaveMessageButton")) ?? 0) != 0
        self.showDetailsButton = ((try? container.decode(Int32.self, forKey: "showDetailsButton")) ?? 0) != 0
        self.showReportButton = ((try? container.decode(Int32.self, forKey: "showReportButton")) ?? 1) != 0
        self.showHistoryButton = ((try? container.decode(Int32.self, forKey: "showHistoryButton")) ?? 0) != 0
        self.addCommaAfterMention = ((try? container.decode(Int32.self, forKey: "addCommaAfterMention")) ?? 1) != 0
        self.hidePhotoCounter = ((try? container.decode(Int32.self, forKey: "hidePhotoCounter")) ?? 0) != 0
        self.hideCameraTile = ((try? container.decode(Int32.self, forKey: "hideCameraTile")) ?? 0) != 0
        self.staticZoom = ((try? container.decode(Int32.self, forKey: "staticZoom")) ?? 0) != 0
        self.rememberLastUsedCamera = ((try? container.decode(Int32.self, forKey: "rememberLastUsedCamera")) ?? 0) != 0
        self.pauseOnMinimize = ((try? container.decode(Int32.self, forKey: "pauseOnMinimize")) ?? 1) != 0
        self.disablePlayback = ((try? container.decode(Int32.self, forKey: "disablePlayback")) ?? 0) != 0
        self.filterZalgo = ((try? container.decode(Int32.self, forKey: "filterZalgo")) ?? 0) != 0
        self.showIdAndDc = (try? container.decode(Int32.self, forKey: "showIdAndDc")) ?? 0
        self.avatarCorners = ((try? container.decode(Int32.self, forKey: "avatarCorners")) ?? 0) != 0
        self.titleText = ((try? container.decode(Int32.self, forKey: "titleText")) ?? 0) != 0
        self.tabIcons = ((try? container.decode(Int32.self, forKey: "tabIcons")) ?? 0) != 0
        self.stickerSize = ((try? container.decode(Int32.self, forKey: "stickerSize")) ?? 0) != 0
        self.stickerShape = ((try? container.decode(Int32.self, forKey: "stickerShape")) ?? 0) != 0
        self.doubleTapAction = (try? container.decode(Int32.self, forKey: "doubleTapAction")) ?? 0
        self.doubleTapActionOutOwner = (try? container.decode(Int32.self, forKey: "doubleTapActionOutOwner")) ?? 0
        self.doubleTapSeekDuration = ((try? container.decode(Int32.self, forKey: "doubleTapSeekDuration")) ?? 0) != 0
        self.bottomButton = ((try? container.decode(Int32.self, forKey: "bottomButton")) ?? 0) != 0
        self.sendPhotosQuality = (try? container.decode(Int32.self, forKey: "sendPhotosQuality")) ?? 0
        self.videoMessagesCamera = ((try? container.decode(Int32.self, forKey: "videoMessagesCamera")) ?? 0) != 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(self.downloadSpeedBoostLevel, forKey: "downloadSpeedBoostLevel")
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

        try container.encode((self.hidePhoneNumber ? 1 : 0) as Int32, forKey: "hidePhoneNumber")
        try container.encode((self.archiveOnPull ? 1 : 0) as Int32, forKey: "archiveOnPull")
        try container.encode((self.disableUnarchiveSwipe ? 1 : 0) as Int32, forKey: "disableUnarchiveSwipe")
        try container.encode((self.hideActionBarStatus ? 1 : 0) as Int32, forKey: "hideActionBarStatus")
        try container.encode((self.centerTitle ? 1 : 0) as Int32, forKey: "centerTitle")
        try container.encode((self.tabCounter ? 1 : 0) as Int32, forKey: "tabCounter")
        try container.encode((self.hideAllChats ? 1 : 0) as Int32, forKey: "hideAllChats")
        try container.encode((self.forceBlur ? 1 : 0) as Int32, forKey: "forceBlur")
        try container.encode((self.forceSnow ? 1 : 0) as Int32, forKey: "forceSnow")
        try container.encode((self.useSystemFonts ? 1 : 0) as Int32, forKey: "useSystemFonts")
        try container.encode((self.newSwitchStyle ? 1 : 0) as Int32, forKey: "newSwitchStyle")
        try container.encode((self.disableDividers ? 1 : 0) as Int32, forKey: "disableDividers")
        try container.encode((self.hideStickerTime ? 1 : 0) as Int32, forKey: "hideStickerTime")
        try container.encode((self.unlimitedRecentStickers ? 1 : 0) as Int32, forKey: "unlimitedRecentStickers")
        try container.encode((self.hideCategories ? 1 : 0) as Int32, forKey: "hideCategories")
        try container.encode((self.hideKeyboardOnScroll ? 1 : 0) as Int32, forKey: "hideKeyboardOnScroll")
        try container.encode((self.permissionsShortcut ? 1 : 0) as Int32, forKey: "permissionsShortcut")
        try container.encode((self.administratorsShortcut ? 1 : 0) as Int32, forKey: "administratorsShortcut")
        try container.encode((self.membersShortcut ? 1 : 0) as Int32, forKey: "membersShortcut")
        try container.encode((self.recentActionsShortcut ? 1 : 0) as Int32, forKey: "recentActionsShortcut")
        try container.encode((self.disableJumpToNextChannel ? 1 : 0) as Int32, forKey: "disableJumpToNextChannel")
        try container.encode((self.showActionTimestamps ? 1 : 0) as Int32, forKey: "showActionTimestamps")
        try container.encode((self.hideShareButton ? 1 : 0) as Int32, forKey: "hideShareButton")
        try container.encode((self.showCopyPhotoButton ? 1 : 0) as Int32, forKey: "showCopyPhotoButton")
        try container.encode((self.showClearButton ? 1 : 0) as Int32, forKey: "showClearButton")
        try container.encode((self.showSaveMessageButton ? 1 : 0) as Int32, forKey: "showSaveMessageButton")
        try container.encode((self.showDetailsButton ? 1 : 0) as Int32, forKey: "showDetailsButton")
        try container.encode((self.showReportButton ? 1 : 0) as Int32, forKey: "showReportButton")
        try container.encode((self.showHistoryButton ? 1 : 0) as Int32, forKey: "showHistoryButton")
        try container.encode((self.addCommaAfterMention ? 1 : 0) as Int32, forKey: "addCommaAfterMention")
        try container.encode((self.hidePhotoCounter ? 1 : 0) as Int32, forKey: "hidePhotoCounter")
        try container.encode((self.hideCameraTile ? 1 : 0) as Int32, forKey: "hideCameraTile")
        try container.encode((self.staticZoom ? 1 : 0) as Int32, forKey: "staticZoom")
        try container.encode((self.rememberLastUsedCamera ? 1 : 0) as Int32, forKey: "rememberLastUsedCamera")
        try container.encode((self.pauseOnMinimize ? 1 : 0) as Int32, forKey: "pauseOnMinimize")
        try container.encode((self.disablePlayback ? 1 : 0) as Int32, forKey: "disablePlayback")
        try container.encode((self.filterZalgo ? 1 : 0) as Int32, forKey: "filterZalgo")
        try container.encode(self.showIdAndDc, forKey: "showIdAndDc")
        try container.encode((self.avatarCorners ? 1 : 0) as Int32, forKey: "avatarCorners")
        try container.encode((self.titleText ? 1 : 0) as Int32, forKey: "titleText")
        try container.encode((self.tabIcons ? 1 : 0) as Int32, forKey: "tabIcons")
        try container.encode((self.stickerSize ? 1 : 0) as Int32, forKey: "stickerSize")
        try container.encode((self.stickerShape ? 1 : 0) as Int32, forKey: "stickerShape")
        try container.encode(self.doubleTapAction, forKey: "doubleTapAction")
        try container.encode(self.doubleTapActionOutOwner, forKey: "doubleTapActionOutOwner")
        try container.encode((self.doubleTapSeekDuration ? 1 : 0) as Int32, forKey: "doubleTapSeekDuration")
        try container.encode((self.bottomButton ? 1 : 0) as Int32, forKey: "bottomButton")
        try container.encode(self.sendPhotosQuality, forKey: "sendPhotosQuality")
        try container.encode((self.videoMessagesCamera ? 1 : 0) as Int32, forKey: "videoMessagesCamera")
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
            lhs.feedWidePosts == rhs.feedWidePosts &&
            lhs.hidePhoneNumber == rhs.hidePhoneNumber &&
            lhs.archiveOnPull == rhs.archiveOnPull &&
            lhs.disableUnarchiveSwipe == rhs.disableUnarchiveSwipe &&
            lhs.hideActionBarStatus == rhs.hideActionBarStatus &&
            lhs.centerTitle == rhs.centerTitle &&
            lhs.tabCounter == rhs.tabCounter &&
            lhs.hideAllChats == rhs.hideAllChats &&
            lhs.forceBlur == rhs.forceBlur &&
            lhs.forceSnow == rhs.forceSnow &&
            lhs.useSystemFonts == rhs.useSystemFonts &&
            lhs.newSwitchStyle == rhs.newSwitchStyle &&
            lhs.disableDividers == rhs.disableDividers &&
            lhs.hideStickerTime == rhs.hideStickerTime &&
            lhs.unlimitedRecentStickers == rhs.unlimitedRecentStickers &&
            lhs.hideCategories == rhs.hideCategories &&
            lhs.hideKeyboardOnScroll == rhs.hideKeyboardOnScroll &&
            lhs.permissionsShortcut == rhs.permissionsShortcut &&
            lhs.administratorsShortcut == rhs.administratorsShortcut &&
            lhs.membersShortcut == rhs.membersShortcut &&
            lhs.recentActionsShortcut == rhs.recentActionsShortcut &&
            lhs.disableJumpToNextChannel == rhs.disableJumpToNextChannel &&
            lhs.showActionTimestamps == rhs.showActionTimestamps &&
            lhs.hideShareButton == rhs.hideShareButton &&
            lhs.showCopyPhotoButton == rhs.showCopyPhotoButton &&
            lhs.showClearButton == rhs.showClearButton &&
            lhs.showSaveMessageButton == rhs.showSaveMessageButton &&
            lhs.showDetailsButton == rhs.showDetailsButton &&
            lhs.showReportButton == rhs.showReportButton &&
            lhs.showHistoryButton == rhs.showHistoryButton &&
            lhs.addCommaAfterMention == rhs.addCommaAfterMention &&
            lhs.hidePhotoCounter == rhs.hidePhotoCounter &&
            lhs.hideCameraTile == rhs.hideCameraTile &&
            lhs.staticZoom == rhs.staticZoom &&
            lhs.rememberLastUsedCamera == rhs.rememberLastUsedCamera &&
            lhs.pauseOnMinimize == rhs.pauseOnMinimize &&
            lhs.disablePlayback == rhs.disablePlayback &&
            lhs.filterZalgo == rhs.filterZalgo &&
            lhs.showIdAndDc == rhs.showIdAndDc &&
            lhs.avatarCorners == rhs.avatarCorners &&
            lhs.titleText == rhs.titleText &&
            lhs.tabIcons == rhs.tabIcons &&
            lhs.stickerSize == rhs.stickerSize &&
            lhs.stickerShape == rhs.stickerShape &&
            lhs.doubleTapAction == rhs.doubleTapAction &&
            lhs.doubleTapActionOutOwner == rhs.doubleTapActionOutOwner &&
            lhs.doubleTapSeekDuration == rhs.doubleTapSeekDuration &&
            lhs.bottomButton == rhs.bottomButton &&
            lhs.sendPhotosQuality == rhs.sendPhotosQuality &&
            lhs.videoMessagesCamera == rhs.videoMessagesCamera
    }

    public func with<Value>(_ keyPath: WritableKeyPath<ExteraSettings, Value>, _ value: Value) -> ExteraSettings {
        var result = self
        result[keyPath: keyPath] = value
        return result
    }

    public func changedKeyCount(comparedTo other: ExteraSettings) -> Int {
        var count = 0
        if self.downloadSpeedBoostLevel != other.downloadSpeedBoostLevel { count += 1 }
        if self.uploadSpeedBoost != other.uploadSpeedBoost { count += 1 }
        if self.disableNumberRounding != other.disableNumberRounding { count += 1 }
        if self.formatTimeWithSeconds != other.formatTimeWithSeconds { count += 1 }
        if self.checkUpdatesOnLaunch != other.checkUpdatesOnLaunch { count += 1 }
        if self.lastUpdateCheckTime != other.lastUpdateCheckTime { count += 1 }
        if self.customSaveFolderName != other.customSaveFolderName { count += 1 }
        if self.useGoogleAnalytics != other.useGoogleAnalytics { count += 1 }
        if self.useGoogleCrashlytics != other.useGoogleCrashlytics { count += 1 }
        if self.adBlockEnabled != other.adBlockEnabled { count += 1 }
        if self.adBlockBlockedRequests != other.adBlockBlockedRequests { count += 1 }
        if self.feedEnabled != other.feedEnabled { count += 1 }
        if self.feedCategories != other.feedCategories { count += 1 }
        if self.feedIncludeArchived != other.feedIncludeArchived { count += 1 }
        if self.feedWidePosts != other.feedWidePosts { count += 1 }
        if self.hidePhoneNumber != other.hidePhoneNumber { count += 1 }
        if self.archiveOnPull != other.archiveOnPull { count += 1 }
        if self.disableUnarchiveSwipe != other.disableUnarchiveSwipe { count += 1 }
        if self.hideActionBarStatus != other.hideActionBarStatus { count += 1 }
        if self.centerTitle != other.centerTitle { count += 1 }
        if self.tabCounter != other.tabCounter { count += 1 }
        if self.hideAllChats != other.hideAllChats { count += 1 }
        if self.forceBlur != other.forceBlur { count += 1 }
        if self.forceSnow != other.forceSnow { count += 1 }
        if self.useSystemFonts != other.useSystemFonts { count += 1 }
        if self.newSwitchStyle != other.newSwitchStyle { count += 1 }
        if self.disableDividers != other.disableDividers { count += 1 }
        if self.hideStickerTime != other.hideStickerTime { count += 1 }
        if self.unlimitedRecentStickers != other.unlimitedRecentStickers { count += 1 }
        if self.hideCategories != other.hideCategories { count += 1 }
        if self.hideKeyboardOnScroll != other.hideKeyboardOnScroll { count += 1 }
        if self.permissionsShortcut != other.permissionsShortcut { count += 1 }
        if self.administratorsShortcut != other.administratorsShortcut { count += 1 }
        if self.membersShortcut != other.membersShortcut { count += 1 }
        if self.recentActionsShortcut != other.recentActionsShortcut { count += 1 }
        if self.disableJumpToNextChannel != other.disableJumpToNextChannel { count += 1 }
        if self.showActionTimestamps != other.showActionTimestamps { count += 1 }
        if self.hideShareButton != other.hideShareButton { count += 1 }
        if self.showCopyPhotoButton != other.showCopyPhotoButton { count += 1 }
        if self.showClearButton != other.showClearButton { count += 1 }
        if self.showSaveMessageButton != other.showSaveMessageButton { count += 1 }
        if self.showDetailsButton != other.showDetailsButton { count += 1 }
        if self.showReportButton != other.showReportButton { count += 1 }
        if self.showHistoryButton != other.showHistoryButton { count += 1 }
        if self.addCommaAfterMention != other.addCommaAfterMention { count += 1 }
        if self.hidePhotoCounter != other.hidePhotoCounter { count += 1 }
        if self.hideCameraTile != other.hideCameraTile { count += 1 }
        if self.staticZoom != other.staticZoom { count += 1 }
        if self.rememberLastUsedCamera != other.rememberLastUsedCamera { count += 1 }
        if self.pauseOnMinimize != other.pauseOnMinimize { count += 1 }
        if self.disablePlayback != other.disablePlayback { count += 1 }
        if self.filterZalgo != other.filterZalgo { count += 1 }
        if self.showIdAndDc != other.showIdAndDc { count += 1 }
        if self.avatarCorners != other.avatarCorners { count += 1 }
        if self.titleText != other.titleText { count += 1 }
        if self.tabIcons != other.tabIcons { count += 1 }
        if self.stickerSize != other.stickerSize { count += 1 }
        if self.stickerShape != other.stickerShape { count += 1 }
        if self.doubleTapAction != other.doubleTapAction { count += 1 }
        if self.doubleTapActionOutOwner != other.doubleTapActionOutOwner { count += 1 }
        if self.doubleTapSeekDuration != other.doubleTapSeekDuration { count += 1 }
        if self.bottomButton != other.bottomButton { count += 1 }
        if self.sendPhotosQuality != other.sendPhotosQuality { count += 1 }
        if self.videoMessagesCamera != other.videoMessagesCamera { count += 1 }
        return count
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
