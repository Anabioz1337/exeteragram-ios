import Foundation
import TelegramCore
import SwiftSignalKit

public struct ExteraSettings: Codable, Equatable {
    public var downloadSpeedBoostLevel: Int
    public var uploadSpeedBoost: Bool
    public var disableNumberRounding: Bool
    public var formatTimeWithSeconds: Bool
    public var checkUpdatesOnLaunch: Bool
    public var lastUpdateCheckTime: Int64

    public static var defaultSettings: ExteraSettings {
        return ExteraSettings(downloadSpeedBoostLevel: 0, uploadSpeedBoost: false, disableNumberRounding: false, formatTimeWithSeconds: false, checkUpdatesOnLaunch: false, lastUpdateCheckTime: 0)
    }

    public init(downloadSpeedBoostLevel: Int, uploadSpeedBoost: Bool, disableNumberRounding: Bool, formatTimeWithSeconds: Bool, checkUpdatesOnLaunch: Bool, lastUpdateCheckTime: Int64) {
        self.downloadSpeedBoostLevel = downloadSpeedBoostLevel
        self.uploadSpeedBoost = uploadSpeedBoost
        self.disableNumberRounding = disableNumberRounding
        self.formatTimeWithSeconds = formatTimeWithSeconds
        self.checkUpdatesOnLaunch = checkUpdatesOnLaunch
        self.lastUpdateCheckTime = lastUpdateCheckTime
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)

        self.downloadSpeedBoostLevel = (try? container.decode(Int32.self, forKey: "downloadSpeedBoostLevel")).flatMap({ Int($0) }) ?? 0
        self.uploadSpeedBoost = ((try? container.decode(Int32.self, forKey: "uploadSpeedBoost")) ?? 0) != 0
        self.disableNumberRounding = ((try? container.decode(Int32.self, forKey: "disableNumberRounding")) ?? 0) != 0
        self.formatTimeWithSeconds = ((try? container.decode(Int32.self, forKey: "formatTimeWithSeconds")) ?? 0) != 0
        self.checkUpdatesOnLaunch = ((try? container.decode(Int32.self, forKey: "checkUpdatesOnLaunch")) ?? 0) != 0
        self.lastUpdateCheckTime = (try? container.decode(Int64.self, forKey: "lastUpdateCheckTime")) ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)

        try container.encode(Int32(self.downloadSpeedBoostLevel), forKey: "downloadSpeedBoostLevel")
        try container.encode((self.uploadSpeedBoost ? 1 : 0) as Int32, forKey: "uploadSpeedBoost")
        try container.encode((self.disableNumberRounding ? 1 : 0) as Int32, forKey: "disableNumberRounding")
        try container.encode((self.formatTimeWithSeconds ? 1 : 0) as Int32, forKey: "formatTimeWithSeconds")
        try container.encode((self.checkUpdatesOnLaunch ? 1 : 0) as Int32, forKey: "checkUpdatesOnLaunch")
        try container.encode(self.lastUpdateCheckTime, forKey: "lastUpdateCheckTime")
    }

    public static func ==(lhs: ExteraSettings, rhs: ExteraSettings) -> Bool {
        return lhs.downloadSpeedBoostLevel == rhs.downloadSpeedBoostLevel &&
            lhs.uploadSpeedBoost == rhs.uploadSpeedBoost &&
            lhs.disableNumberRounding == rhs.disableNumberRounding &&
            lhs.formatTimeWithSeconds == rhs.formatTimeWithSeconds &&
            lhs.checkUpdatesOnLaunch == rhs.checkUpdatesOnLaunch &&
            lhs.lastUpdateCheckTime == rhs.lastUpdateCheckTime
    }
}

public func updateExteraSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExteraSettings) -> ExteraSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.exteraSettings, { entry in
            let currentSettings: ExteraSettings
            if let entry = entry?.get(ExteraSettings.self) {
                currentSettings = entry
            } else {
                currentSettings = ExteraSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(currentSettings))
        })
    }
}

public func exteraSettings(accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<ExteraSettings, NoError> {
    return accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.exteraSettings])
    |> map { sharedData -> ExteraSettings in
        return sharedData.entries[ApplicationSpecificSharedDataKeys.exteraSettings]?.get(ExteraSettings.self) ?? .defaultSettings
    }
}
