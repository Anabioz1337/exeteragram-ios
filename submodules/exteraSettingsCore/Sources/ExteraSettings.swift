import Foundation
import TelegramCore
import SwiftSignalKit

public struct ExteraSettings: Codable, Equatable {
    public var disableNumberRounding: Bool = false
    public var formatTimeWithSeconds: Bool = false
    public var downloadSpeedBoost: Int32 = 0
    public var uploadSpeedBoost: Bool = false
    public var hidePhoneNumber: Bool = false
    public var showIdAndDc: Int32 = 1
    public var archiveOnPull: Bool = false
    public var disableUnarchiveSwipe: Bool = true

    public var avatarCorners: Int32 = 30
    public var hideActionBarStatus: Bool = false
    public var centerTitle: Bool = false
    public var titleText: Int32 = 0
    public var tabIcons: Int32 = 1
    public var tabCounter: Bool = true
    public var hideAllChats: Bool = false
    public var forceBlur: Bool = false
    public var forceSnow: Bool = false
    public var useSystemFonts: Bool = true
    public var newSwitchStyle: Bool = true
    public var disableDividers: Bool = false

    public var stickerSize: Int32 = 14
    public var stickerShape: Int32 = 1
    public var hideStickerTime: Bool = false
    public var unlimitedRecentStickers: Bool = false
    public var hideCategories: Bool = true
    public var doubleTapAction: Int32 = 1
    public var doubleTapActionOutOwner: Int32 = 1
    public var doubleTapSeekDuration: Int32 = 1
    public var bottomButton: Int32 = 2
    public var hideKeyboardOnScroll: Bool = true
    public var permissionsShortcut: Bool = false
    public var administratorsShortcut: Bool = false
    public var membersShortcut: Bool = false
    public var recentActionsShortcut: Bool = true
    public var disableJumpToNextChannel: Bool = false
    public var showActionTimestamps: Bool = true
    public var hideShareButton: Bool = true
    public var showCopyPhotoButton: Bool = true
    public var showClearButton: Bool = true
    public var showSaveMessageButton: Bool = false
    public var showDetailsButton: Bool = false
    public var showReportButton: Bool = true
    public var showHistoryButton: Bool = false
    public var addCommaAfterMention: Bool = true
    public var sendPhotosQuality: Int32 = 1
    public var hidePhotoCounter: Bool = false
    public var hideCameraTile: Bool = false
    public var staticZoom: Bool = false
    public var videoMessagesCamera: Int32 = 0
    public var rememberLastUsedCamera: Bool = false
    public var pauseOnMinimize: Bool = true
    public var disablePlayback: Bool = true

    public var filterZalgo: Bool = false
    public var dateFormat: Int32 = 0
    public var checkUpdatesOnLaunch: Bool = true

    private static let booleanKeys: [String] = [
        "disableNumberRounding",
        "formatTimeWithSeconds",
        "uploadSpeedBoost",
        "hidePhoneNumber",
        "archiveOnPull",
        "disableUnarchiveSwipe",
        "hideActionBarStatus",
        "centerTitle",
        "tabCounter",
        "hideAllChats",
        "forceBlur",
        "forceSnow",
        "useSystemFonts",
        "newSwitchStyle",
        "disableDividers",
        "hideStickerTime",
        "unlimitedRecentStickers",
        "hideCategories",
        "hideKeyboardOnScroll",
        "permissionsShortcut",
        "administratorsShortcut",
        "membersShortcut",
        "recentActionsShortcut",
        "disableJumpToNextChannel",
        "showActionTimestamps",
        "hideShareButton",
        "showCopyPhotoButton",
        "showClearButton",
        "showSaveMessageButton",
        "showDetailsButton",
        "showReportButton",
        "showHistoryButton",
        "addCommaAfterMention",
        "hidePhotoCounter",
        "hideCameraTile",
        "staticZoom",
        "rememberLastUsedCamera",
        "pauseOnMinimize",
        "disablePlayback",
        "filterZalgo",
        "checkUpdatesOnLaunch"
    ]

    private static let dateFormatIntegerKey = "dateFormat"

    private static let integerKeys: [String] = [
        "downloadSpeedBoost",
        "showIdAndDc",
        "avatarCorners",
        "titleText",
        "tabIcons",
        "stickerSize",
        "stickerShape",
        "doubleTapAction",
        "doubleTapActionOutOwner",
        "doubleTapSeekDuration",
        "bottomButton",
        "sendPhotosQuality",
        "videoMessagesCamera",
        ExteraSettings.dateFormatIntegerKey
    ]

    public init() {
    }

    public init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: StringCodingKey.self)

        for key in ExteraSettings.booleanKeys {
            let codingKey = StringCodingKey(key)
            if let value = try container.decodeIfPresent(Int32.self, forKey: codingKey) {
                self[keyPath: ExteraSettings.booleanKeyPaths[key]!] = value != 0
            }
        }

        for key in ExteraSettings.integerKeys {
            let codingKey = StringCodingKey(key)
            if let value = try container.decodeIfPresent(Int32.self, forKey: codingKey) {
                self[keyPath: ExteraSettings.integerKeyPaths[key]!] = value
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        for key in ExteraSettings.booleanKeys {
            try container.encode(self[keyPath: ExteraSettings.booleanKeyPaths[key]!] ? 1 : 0 as Int32, forKey: StringCodingKey(key))
        }

        for key in ExteraSettings.integerKeys {
            try container.encode(self[keyPath: ExteraSettings.integerKeyPaths[key]!], forKey: StringCodingKey(key))
        }
    }

    private static let booleanKeyPaths: [String: WritableKeyPath<ExteraSettings, Bool>] = [
        "disableNumberRounding": \.disableNumberRounding,
        "formatTimeWithSeconds": \.formatTimeWithSeconds,
        "uploadSpeedBoost": \.uploadSpeedBoost,
        "hidePhoneNumber": \.hidePhoneNumber,
        "archiveOnPull": \.archiveOnPull,
        "disableUnarchiveSwipe": \.disableUnarchiveSwipe,
        "hideActionBarStatus": \.hideActionBarStatus,
        "centerTitle": \.centerTitle,
        "tabCounter": \.tabCounter,
        "hideAllChats": \.hideAllChats,
        "forceBlur": \.forceBlur,
        "forceSnow": \.forceSnow,
        "useSystemFonts": \.useSystemFonts,
        "newSwitchStyle": \.newSwitchStyle,
        "disableDividers": \.disableDividers,
        "hideStickerTime": \.hideStickerTime,
        "unlimitedRecentStickers": \.unlimitedRecentStickers,
        "hideCategories": \.hideCategories,
        "hideKeyboardOnScroll": \.hideKeyboardOnScroll,
        "permissionsShortcut": \.permissionsShortcut,
        "administratorsShortcut": \.administratorsShortcut,
        "membersShortcut": \.membersShortcut,
        "recentActionsShortcut": \.recentActionsShortcut,
        "disableJumpToNextChannel": \.disableJumpToNextChannel,
        "showActionTimestamps": \.showActionTimestamps,
        "hideShareButton": \.hideShareButton,
        "showCopyPhotoButton": \.showCopyPhotoButton,
        "showClearButton": \.showClearButton,
        "showSaveMessageButton": \.showSaveMessageButton,
        "showDetailsButton": \.showDetailsButton,
        "showReportButton": \.showReportButton,
        "showHistoryButton": \.showHistoryButton,
        "addCommaAfterMention": \.addCommaAfterMention,
        "hidePhotoCounter": \.hidePhotoCounter,
        "hideCameraTile": \.hideCameraTile,
        "staticZoom": \.staticZoom,
        "rememberLastUsedCamera": \.rememberLastUsedCamera,
        "pauseOnMinimize": \.pauseOnMinimize,
        "disablePlayback": \.disablePlayback,
        "filterZalgo": \.filterZalgo,
        "checkUpdatesOnLaunch": \.checkUpdatesOnLaunch
    ]

    private static let integerKeyPaths: [String: WritableKeyPath<ExteraSettings, Int32>] = [
        "downloadSpeedBoost": \.downloadSpeedBoost,
        "showIdAndDc": \.showIdAndDc,
        "avatarCorners": \.avatarCorners,
        "titleText": \.titleText,
        "tabIcons": \.tabIcons,
        "stickerSize": \.stickerSize,
        "stickerShape": \.stickerShape,
        "doubleTapAction": \.doubleTapAction,
        "doubleTapActionOutOwner": \.doubleTapActionOutOwner,
        "doubleTapSeekDuration": \.doubleTapSeekDuration,
        "bottomButton": \.bottomButton,
        "sendPhotosQuality": \.sendPhotosQuality,
        "videoMessagesCamera": \.videoMessagesCamera,
        ExteraSettings.dateFormatIntegerKey: \.dateFormat
    ]
}

extension ExteraSettings {
    public func with<Value>(_ keyPath: WritableKeyPath<ExteraSettings, Value>, _ value: Value) -> ExteraSettings {
        var updated = self
        updated[keyPath: keyPath] = value
        return updated
    }

    public var photosQualityPixels: Int {
        switch self.sendPhotosQuality {
            case 0:
                return 800
            case 2:
                return 2560
            default:
                return 1280
        }
    }

    public var doubleTapSeekIntervalMs: Int32 {
        switch self.doubleTapSeekDuration {
            case 0, 1, 2:
                return (self.doubleTapSeekDuration + 1) * 5000
            default:
                return 30000
        }
    }

    public func changedKeyCount(comparedTo other: ExteraSettings) -> Int {
        var count = 0
        for (_, keyPath) in ExteraSettings.booleanKeyPaths where self[keyPath: keyPath] != other[keyPath: keyPath] {
            count += 1
        }
        for (_, keyPath) in ExteraSettings.integerKeyPaths where self[keyPath: keyPath] != other[keyPath: keyPath] {
            count += 1
        }
        return count
    }
}

public func updateExteraSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSettings) -> ExteraSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSettings, { entry in
            let currentSettings: ExteraSettings
            if let entry = entry?.get(ExteraSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraSettings()
            }
            return EnginePreferencesEntry(f(currentSettings))
        })
    }
}
